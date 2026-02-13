#!/bin/bash

# Warna
DF='\e[39m'
Bold='\e[1m'
Blink='\e[5m'
yell='\e[33m'
red='\e[31m'
green='\e[32m'
blue='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
Lred='\e[91m'
Lgreen='\e[92m'
Lyellow='\e[93m'
NC='\e[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
LIGHT='\033[0;37m'

# ==================================================
#  Auto Remove Expired Users (SSH, Xray)
# ==================================================

TODAY=`date +"%Y-%m-%d"`
TODAY_HUMAN=`date +%d-%m-%Y`

# ------------------------------
#  Fungsi Hapus SSH Expired
# ------------------------------
remove_ssh_expired() {
    local EXPIRELIST="/tmp/expirelist.txt"
    cat /etc/shadow | cut -d: -f1,8 | sed /:$/d > "$EXPIRELIST"
    local TOTAL=$(wc -l < "$EXPIRELIST")

    for ((i=1; i<=TOTAL; i++)); do
        local TUSERVAL=$(sed -n "${i}p" "$EXPIRELIST")
        local USERNAME=$(echo "$TUSERVAL" | cut -f1 -d:)
        local USEREXP=$(echo "$TUSERVAL" | cut -f2 -d:)
        local USEREXPIRE_SEC=$(( USEREXP * 86400 ))

        if [ $USEREXPIRE_SEC -lt $(date +%s) ]; then
            echo "Expired - SSH user: $USERNAME removed on: $TODAY_HUMAN"
            userdel --force "$USERNAME"
        fi
    done
}

# ------------------------------
#  Fungsi Hapus Xray Expired
# ------------------------------
remove_xray_expired() {
    local PROTOCOL=$1
    local CONFIG="/usr/local/etc/xray/${PROTOCOL}.json"
    local TODAY=$(date +%Y-%m-%d)

    if [[ ! -f "$CONFIG" ]]; then
        echo "Config file $CONFIG not found!"
        return
    fi

    local USERS=($(grep '^###' "$CONFIG" | awk '{print $2}' | sort -u))

    for USER in "${USERS[@]}"; do
        local EXP=$(grep -w "^### $USER" "$CONFIG" | awk '{print $3}' | sort -u)
        local D1=$(date -d "$EXP" +%s)
        local D2=$(date -d "$TODAY" +%s)
        local REMAIN=$(( (D1 - D2) / 86400 ))

        if [[ "$REMAIN" -le 0 ]]; then
            echo "Expired - $PROTOCOL user: $USER removed"
            sed -i "/^### $USER $EXP/,/\"email\": \"$USER\"/d" "$CONFIG"
            rm -rf /home/vps/public_html/$USER*
            if [[ "$PROTOCOL" == "vmess" ]]; then
                rm -f /etc/xray/$USER-tls.json /etc/xray/$USER-none.json
            fi
        fi
    done
}

# ===== Helper: Remove expired IPs =====
remove_expired_ips() {
    [[ ! -f "$SOCK_FILE" ]] && return
    today=$(date +%s)
    while read -r line; do
        IP=$(echo $line | awk '{print $2}')
        EXP=$(echo $line | awk '{print $4}')
        if [[ -z "$EXP" ]]; then continue; fi
        exp_sec=$(date -d "$EXP" +%s)
        if (( exp_sec < today )); then
            sed -i "\|$line|d" "$SOCK_FILE"
            iptables -D INPUT -p tcp -s "$IP" --dport $PORT -j ACCEPT 2>/dev/null
            iptables -D INPUT -p udp -s "$IP" --dport $PORT -j ACCEPT 2>/dev/null
        fi
    done < "$SOCK_FILE"
    iptables-save >/etc/iptables.rules.v4
    netfilter-persistent save
    netfilter-persistent reload
}

remove_ssh_expired
remove_xray_expired "vless"
remove_expired_ips
systemctl restart xray
