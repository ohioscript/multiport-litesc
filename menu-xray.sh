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

# Variabel
host="https://t.me/vpnlegasi"
owner="vpnlegasi"
gitlink="https://raw.githubusercontent.com"
ISP=$(curl -s ipinfo.io/org | cut -d " " -f 2-10)
domain=$(cat /root/domain 2>/dev/null)
int=$(cat /home/.int 2>/dev/null)
sc=$(awk '{print $1}' /home/.ver 2>/dev/null)
scv=$(awk '{print $2,$3}' /home/.ver 2>/dev/null)
if ip link show wgcf >/dev/null 2>&1; then
  MYIP=$(ip -4 addr show scope global | grep -v wgcf | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
else
  MYIP=$(curl -s https://api.ipify.org)
fi

if [ -z "$MYIP" ]; then
  MYIP=$(curl -s https://api.ipify.org)
fi

clear

# Data admin & client
admin_data=$(curl -sS ${gitlink}/${owner}/ip-admin/main/access)
client_data=$(curl -sS ${gitlink}/${owner}/client-$sc/main/access)

if [ -z "$admin_data" ] || [ -z "$client_data" ]; then
    sleep 1
    admin_data=$(curl -sS --max-time 2 ${gitlink}/${owner}/ip-admin/main/access)
    client_data=$(curl -sS --max-time 2 ${gitlink}/${owner}/client-$sc/main/access)
fi

# Semak sama ada IP admin
is_admin=$(echo "$admin_data" | awk '{print $2}' | grep -w "$MYIP")

if [ "$is_admin" = "$MYIP" ]; then
    Name=$(echo "$admin_data" | grep -w "$MYIP" | awk '{print $4}')
    scexpireddate=$(echo "$admin_data" | grep -w "$MYIP" | awk '{print $3}')
else
    Name=$(echo "$client_data" | grep -w "$MYIP" | awk '{print $4}')
    scexpireddate=$(echo "$client_data" | grep -w "$MYIP" | awk '{print $3}')
fi

# Kira baki hari
period=$(date -d "$scexpireddate" +%s)
today=$(date +"%Y-%m-%d")
timestamptoday=$(date -d "$today" +%s)
sisa_hari=$(( (period - timestamptoday) / 86400 ))

# Fungsi permission
PERMISSION() {
    admin_check=$(echo "$admin_data" | awk '{print $2}' | grep -w "$MYIP")
    client_check=$(echo "$client_data" | awk '{print $2}' | grep -w "$MYIP")

    if [ "$admin_check" = "$MYIP" ] || [ "$client_check" = "$MYIP" ]; then
        clear
        echo -e "${green}Permission Accepted...${NC}"
    else
        clear
        echo -e "${red}Permission Denied!${NC}"
        echo "Your IP NOT REGISTER / EXPIRED | Contact Telegram @vpnlegasi to Unlock"
        sleep 2
        exit 0
    fi
}

echo "Checking VPS..."
PERMISSION

add_data() {
    echo -e "1) Bug Domain (Wildcard / Direct)"
    echo -e "2) Use IP as Address"
    echo -e "3) Reverse Proxy Mode (bug.domain or direct bug)"
    read -p "Your Option? 1/2/3 or press enter to continue : " ans

    # Default (Enter)
    if [[ -z "$ans" ]]; then
        BUG="isi_bug_disini"
        wild=""
        return
    fi

    domain=$(cat /root/domain 2>/dev/null)
    USE_WILD=false
    REVERSE_MODE=false

    # --- Mode 2: IP Address ---
    if [[ "$ans" == "2" ]]; then
        domain=$MYIP
    fi

    # --- Mode 3: Reverse Proxy ---
    if [[ "$ans" == "3" ]]; then
        REVERSE_MODE=true
        echo -e "Reverse Proxy Mode:"
        echo -e "1) Wildcard (bug.domain)"
        echo -e "2) Direct (bug sahaja)"
        read -p "Your Option? 1/2 or press enter to continue : " rev_mode
        [[ "$rev_mode" == "1" ]] && USE_WILD=true
    fi

    # --- Mode 1: Bug Domain ---
    if [[ "$ans" == "1" ]]; then
        echo -e "Select Bug Mode:"
        echo -e "1) Wildcard"
        echo -e "2) Direct"
        read -p "Your Option? 1/2 or press enter to continue : " bug_mode
        [[ "$bug_mode" == "1" ]] && USE_WILD=true
    fi

    # --- Pilih BUG ---
    if [[ -d /root/bug ]]; then
        telco_dirs=(/root/bug/*)
        telco_choices=()
        for d in "${telco_dirs[@]}"; do
            [[ -f "$d" ]] || continue
            telco_choices+=("$(basename "$d" | sed 's/\..*$//')")
        done
        telco_choices+=("Manual input")

        echo -e "\nSelect Telco:"
        i=1
        for t in "${telco_choices[@]}"; do
            echo "$i) $t"
            ((i++))
        done

        read -p "Your choice or press enter to continue : " telco_ans
        if [[ -z "$telco_ans" ]]; then
            BUG="isi_bug_disini"
        else
            choice="${telco_choices[$((telco_ans-1))]}"
            if [[ "$choice" == "Manual input" ]]; then
                read -p "Enter BUG manually: " BUG
                [[ -z "$BUG" ]] && BUG="isi_bug_disini"
            else
                file_bug=$(ls /root/bug/"$choice"* 2>/dev/null | head -n1)
                if [[ -f "$file_bug" ]]; then
                    mapfile -t bugs < "$file_bug"
                    bugs+=("Manual input")

                    echo -e "\nAvailable BUGs for $choice:"
                    i=1
                    for b in "${bugs[@]}"; do
                        echo "$i) $b"
                        ((i++))
                    done

                    read -p "Select BUG or press enter to continue : " bug_ans
                    if [[ -z "$bug_ans" ]]; then
                        BUG="isi_bug_disini"
                    else
                        BUG="${bugs[$((bug_ans-1))]}"
                        if [[ "$BUG" == "Manual input" ]]; then
                            read -p "Enter BUG manually: " BUG
                            [[ -z "$BUG" ]] && BUG="isi_bug_disini"
                        fi
                    fi
                else
                    BUG="isi_bug_disini"
                fi
            fi
        fi
    else
        read -p "Enter BUG manually: " BUG
        [[ -z "$BUG" ]] && BUG="isi_bug_disini"
    fi

    # --- Logik Domain ---
    if [[ "$REVERSE_MODE" == true ]]; then
        temp_domain="$domain"

        if [[ "$USE_WILD" == true && "$BUG" != "isi_bug_disini" ]]; then
            # Wildcard: @BUG, host=BUG.DOMAIN
            domain="$BUG"
            BUG="${BUG}.${temp_domain}"
        else
            # Direct: @BUG, host=DOMAIN
            domain="$BUG"
            BUG="$temp_domain"
        fi

        wild=""
    else
        if [[ "$USE_WILD" == true && "$BUG" != "isi_bug_disini" ]]; then
            wild="${BUG}."
        else
            wild=""
        fi
    fi
}

generate_yaml() {
    local proto="$1"
    local mode="$2"
    local file
    local port
    local tls_flag
    local sni
    local host_header
    local path_ws

    if [[ "$proto" == "vless" ]]; then
        path_ws="${VLP1}"
    else
        path_ws="${VMP1}"
    fi

    if [[ "$mode" == "tls" ]]; then
        file="/home/vps/public_html/${user}_${proto}tls.yaml"
        port="${tls}"
        tls_flag="true"
        sni="isi_bug_disini"
        host_header="${domain}"
    else
        file="/home/vps/public_html/${user}_${proto}ntls.yaml"
        port="${none}"
        tls_flag="false"
        sni=""
        host_header="isi_bug_disini"
    fi

    cat << EOF > "$file"
#Yaml MOD by VPN Legasi
port: 7890
socks-port: 7891
redir-port: 7892
mixed-port: 7893
tproxy-port: 7895
ipv6: false
mode: rule
log-level: silent
allow-lan: true
external-controller: 0.0.0.0:9090
secret: ""
bind-address: "*"
unified-delay: true
profile:
  store-selected: true
  store-fake-ip: true
dns:
  enable: true
  ipv6: false
  use-host: true
  enhanced-mode: fake-ip
  listen: 0.0.0.0:7874
  nameserver:
    - 8.8.8.8
    - 1.0.0.1
    - https://dns.google/dns-query
  fallback:
    - 1.1.1.1
    - 8.8.4.4
    - https://cloudflare-dns.com/dns-query
    - 112.215.203.254
  default-nameserver:
    - 8.8.8.8
    - 1.1.1.1
    - 112.215.203.254
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - "*.lan"
    - "*.localdomain"
    - "*.example"
    - "*.invalid"
    - "*.localhost"
    - "*.test"
    - "*.local"
    - "*.home.arpa"
    - time.*.com
    - time.*.gov
    - time.*.edu.cn
    - time.*.apple.com
    - time1.*.com
    - time2.*.com
    - time3.*.com
    - time4.*.com
    - time5.*.com
    - time6.*.com
    - time7.*.com
    - ntp.*.com
    - ntp1.*.com
    - ntp2.*.com
    - ntp3.*.com
    - ntp4.*.com
    - ntp5.*.com
    - ntp6.*.com
    - ntp7.*.com
    - "*.time.edu.cn"
    - "*.ntp.org.cn"
    - +.pool.ntp.org
    - time1.cloud.tencent.com
    - music.163.com
    - "*.music.163.com"
    - "*.126.net"
    - musicapi.taihe.com
    - music.taihe.com
    - songsearch.kugou.com
    - trackercdn.kugou.com
    - "*.kuwo.cn"
    - api-jooxtt.sanook.com
    - api.joox.com
    - joox.com
    - y.qq.com
    - "*.y.qq.com"
    - streamoc.music.tc.qq.com
    - mobileoc.music.tc.qq.com
    - isure.stream.qqmusic.qq.com
    - dl.stream.qqmusic.qq.com
    - aqqmusic.tc.qq.com
    - amobile.music.tc.qq.com
    - "*.xiami.com"
    - "*.music.migu.cn"
    - music.migu.cn
    - "*.msftconnecttest.com"
    - "*.msftncsi.com"
    - msftconnecttest.com
    - msftncsi.com
    - localhost.ptlogin2.qq.com
    - localhost.sec.qq.com
    - +.srv.nintendo.net
    - +.stun.playstation.net
    - xbox.*.microsoft.com
    - xnotify.xboxlive.com
    - +.battlenet.com.cn
    - +.wotgame.cn
    - +.wggames.cn
    - +.wowsgame.cn
    - +.wargaming.net
    - proxy.golang.org
    - stun.*.*
    - stun.*.*.*
    - +.stun.*.*
    - +.stun.*.*.*
    - +.stun.*.*.*.*
    - heartbeat.belkin.com
    - "*.linksys.com"
    - "*.linksyssmartwifi.com"
    - "*.router.asus.com"
    - mesu.apple.com
    - swscan.apple.com
    - swquery.apple.com
    - swdownload.apple.com
    - swcdn.apple.com
    - swdist.apple.com
    - lens.l.google.com
    - stun.l.google.com
    - +.nflxvideo.net
    - "*.square-enix.com"
    - "*.finalfantasyxiv.com"
    - "*.ffxiv.com"
    - "*.mcdn.bilivideo.cn"
    - +.media.dssott.com
proxies:
  - name: ${user}
    server: ${wild}${domain}
    port: ${port}
    type: ${proto}
    uuid: ${uuid}
    $( [[ "$proto" == "vmess" ]] && echo "alterId: 0" )
    cipher: auto
    tls: ${tls_flag}
    skip-cert-verify: true
    servername: ${sni}
    network: ws
    ws-opts:
      path: ${path_ws}
      headers:
        Host: ${host_header}
    udp: true
proxy-groups:
  - name: YAML-VPN-LEGASI
    type: select
    proxies:
      - ${user}
      - DIRECT
rules:
  - MATCH,YAML-VPN-LEGASI
EOF
}

vless_manage() {
    local mode=$1
    local user masaaktif exp hariini uuid domain domainn tls none none1
    local vlesslink1 vlesslink2 vlesslink3 vlesslink4 vlesslink5 vlesslink6 vlesslink7
    local vlessyamltls vlessyamlntls CLIENT_EXISTS CLIENT_NUMBER
    local sm show_mode

    clear
    source /var/lib/premium-script/ipvps.conf
    domain=$(cat /root/domain)
    domainn=$domain
    tls=$(grep -w "Vless TLS" ~/log-install.txt | cut -d: -f2 | tr -d ' ' | cut -d, -f1)
    none=$(grep -w "Vless None TLS" ~/log-install.txt | cut -d: -f2 | tr -d ' ' | cut -d, -f1)
    none1=$(grep -w "Vless None TLS" ~/log-install.txt | cut -d: -f2 | tr -d ' ')

    if [[ $mode == "trial" ]]; then
        until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
            echo -e "\033[0;34m------------------------------------\033[0m"
            echo -e "\E[44;1;39m       Trial Xray Vless Account     \E[0m"
            echo -e "\033[0;34m------------------------------------\033[0m"
            user="VLESS$(</dev/urandom tr -dc X-Z0-9 | head -c4)"
            CLIENT_EXISTS=$(grep -iE "### $user " /usr/local/etc/xray/vless.json | wc -l)
            [[ ${CLIENT_EXISTS} == '1' ]] && menu-xray
            add_data
        done
        masaaktif=1

    elif [[ $mode == "add" ]]; then
        until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
            echo -e "\033[0;34m------------------------------------\033[0m"
            echo -e "\E[44;1;39m        Add Xray Vless Account      \E[0m"
            echo -e "\033[0;34m------------------------------------\033[0m"
            read -rp "User: " -e user
            CLIENT_EXISTS=$(grep -iE "### $user " /usr/local/etc/xray/vless.json | wc -l)
            [[ ${CLIENT_EXISTS} == '1' ]] && menu-xray
            add_data
        done
        read -p "Expired (days): " masaaktif

    elif [[ $mode == "recreate" ]]; then
        rm -rf /root/user_tmp.txt
        grep -E "^### " "/usr/local/etc/xray/vless.json" | sort | uniq > /root/user_tmp.txt
        NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/root/user_tmp.txt")
        [[ ${NUMBER_OF_CLIENTS} == '0' ]] && { echo "No clients found!"; exit 1; }
        grep -E "^### " "/root/user_tmp.txt" | cut -d ' ' -f 2-4 | nl -s ') '
        read -rp "Select client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
        user=$(grep -E "^### " "/root/user_tmp.txt" | awk "NR==${CLIENT_NUMBER} {print \$2}")
        exp=$(grep -w "$user" /root/user_tmp.txt | awk '{print $3}')
        uuid=$(grep -w "$user" /usr/local/etc/xray/vless.json | grep "id" | cut -d'"' -f4 | sort -u)
        hariini=$(date +%Y-%m-%d)
        add_data
    fi

    echo ""
    echo "Select link to show:"
    echo "1) WS + gRPC"
    echo "2) HTTP Upgrade"
    echo "3) XHTTP"
    echo "4) ALL"
    read -rp "Choice: " sm

    case $sm in
        1) show_mode="wsgrpc" ;;
        2) show_mode="http" ;;
        3) show_mode="xhttp" ;;
        4) show_mode="all" ;;
        *) show_mode="all" ;;
    esac

    if [[ $mode != "recreate" ]]; then
        uuid=$(cat /proc/sys/kernel/random/uuid)
        hariini=$(date +%Y-%m-%d)
        exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
        sed -i '/#vless$/a\### '"$user $exp"'\
        },{"id": "'$uuid'","email": "'$user'"' /usr/local/etc/xray/vless.json
        sed -i '/#vlessgrpc$/a\### '"$user $exp"'\
        },{"id": "'$uuid'","email": "'$user'"' /usr/local/etc/xray/vless.json
    fi

    vlesslink1="vless://${uuid}@${wild}${domain}:$tls?path=/vlessws&security=tls&encryption=none&type=ws&sni=${BUG}#${user}"
    vlesslink2="vless://${uuid}@${wild}${domain}:$none?path=/vlessws&encryption=none&type=ws&host=${BUG}#${user}"
    vlesslink3="vless://${uuid}@${wild}${domain}:$tls?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${BUG}#${user}"
    vlesslink4="vless://${uuid}@${wild}${domain}:$tls??encryption=none&flow=none&type=httpupgrade&headerType=none&path=/httpupgrade&security=tls&sni=isi_bug_disini#${user}"
    vlesslink5="vless://${uuid}@${wild}${domain}:$none?encryption=none&flow=none&type=httpupgrade&host=isi_bug_disini&headerType=none&path=/httpupgrade&security=none#${user}"
    vlesslink6="vless://${uuid}@${wild}${domain}:$tls??encryption=none&flow=none&type=xhttp&headerType=none&path=/xhttp&security=tls&sni=isi_bug_disini#${user}"
    vlesslink7="vless://${uuid}@${wild}${domain}:$none?encryption=none&flow=none&type=xhttp&host=isi_bug_disini&headerType=none&path=/xhttp&security=none#${user}"

    rm -rf /home/vps/public_html/${user}*
    generate_yaml vless tls
    generate_yaml vless ntls
    vlessyamltls=http://$MYIP:81/${user}_vlesstls.yaml
    vlessyamlntls=http://$MYIP:81/${user}_vlessntls.yaml

    systemctl restart xray

    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m        User Xray Vless Account     \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "Remarks       : ${user}"
    echo -e "IP Address    : ${MYIP}"
    echo -e "Domain        : ${domainn}"
    echo -e "Port TLS      : ${tls}"
    echo -e "Port GRPC     : ${tls}"
    echo -e "Port none TLS : ${none1}"
if [[ $show_mode == "wsgrpc" ]]; then
    echo -e "Path WS       : anypath"
fi

if [[ $show_mode == "http" ]]; then
    echo -e "Path Http Up  : /httpupgrade"
fi

if [[ $show_mode == "xhttp" ]]; then
    echo -e "Path Xhttp    : /xhttp"
fi

if [[ $show_mode == "all" ]]; then
    echo -e "Path WS       : anypath"
    echo -e "Path Http Up  : /httpupgrade"
    echo -e "Path Xhttp    : /xhttp"
fi

    echo -e "id            : ${uuid}"
    echo -e "\033[0;34m------------------------------------\033[0m"

    if [[ $show_mode == "wsgrpc" || $show_mode == "all" ]]; then
        echo -e "Link TLS :"
        echo -e '```'
        echo -e "${vlesslink1}"
        echo -e '```'
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo -e "Link none TLS :"
        echo -e '```'
        echo -e "${vlesslink2}"
        echo -e '```'
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo -e "Link GRPC :"
        echo -e '```'
        echo -e "${vlesslink3}"
        echo -e '```'
        echo -e "\033[0;34m------------------------------------\033[0m"
    fi

    if [[ $show_mode == "http" || $show_mode == "all" ]]; then
        echo -e "Link HTTP Upgrade TLS :"
        echo -e '```'
        echo -e "${vlesslink4}"
        echo -e '```'
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo -e "Link HTTP Upgrade NTLS :"
        echo -e '```'
        echo -e "${vlesslink5}"
        echo -e '```'
        echo -e "\033[0;34m------------------------------------\033[0m"
    fi

    if [[ $show_mode == "xhttp" || $show_mode == "all" ]]; then
        echo -e "Link XHTTP TLS :"
        echo -e '```'
        echo -e "${vlesslink6}"
        echo -e '```'
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo -e "Link XHTTP NTLS :"
        echo -e '```'
        echo -e "${vlesslink7}"
        echo -e '```'
        echo -e "\033[0;34m------------------------------------\033[0m"
    fi

    if [[ $show_mode == "wsgrpc" || $show_mode == "all" ]]; then
        echo -e "Link Yaml TLS :"
        echo -e ""
        echo -e "${vlessyamltls}"
        echo -e ""
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo -e "Link Yaml none TLS :"
        echo -e ""
        echo -e "${vlessyamlntls}"
        echo -e ""
        echo -e "\033[0;34m------------------------------------\033[0m"
    fi

    echo -e "Created On    : $hariini"
    echo -e "Expired On    : $exp"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo ""
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-xray
}

trial-vless() { vless_manage trial; }
add-vless() { vless_manage add; }
recreate-vless() { vless_manage recreate; }


check-port() {
echo -e "\033[0;34m------------------------------------------------------------\033[0m"
echo -e "\E[44;1;39m                        INFO SCRIPTS INSTALL                \E[0m"
echo -e "\033[0;34m------------------------------------------------------------\033[0m"
cat /root/log-install.txt
echo -e "\033[0;34m------------------------------------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-xray
}

renew-xray() {

    tmpfile="/root/usr_tmp.txt"
    grep -E "^### " "/usr/local/etc/xray/vless.json" | awk '{print $2" "$3}' | sort -u > "$tmpfile"
    NUMBER_OF_CLIENTS=$(wc -l < "$tmpfile" | tr -d ' ')

    if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
        rm -f "$tmpfile"
        menu-xray
    fi

    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m        Renew VLESS Account     \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    nl -s ') ' "$tmpfile"
    echo -e "\033[0;34m-------------------------------\033[0m"

    read -rp "Select one client [1-${NUMBER_OF_CLIENTS}, or 'x' to cancel]: " CLIENT_NUMBER

    if [[ "$CLIENT_NUMBER" =~ ^[xXqQ]$ || -z "$CLIENT_NUMBER" ]]; then
        echo -e "\nAction canceled!"
        rm -f "$tmpfile"
        read -n 1 -s -r -p "Press any key to back on menu"
        menu-xray
    fi

    if ! [[ "$CLIENT_NUMBER" =~ ^[0-9]+$ ]] || (( CLIENT_NUMBER < 1 || CLIENT_NUMBER > NUMBER_OF_CLIENTS )); then
        rm -f "$tmpfile"
        menu-xray
    fi

    user=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $1}' "$tmpfile")
    exp=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $2}' "$tmpfile")

    read -rp "Extend by (days): " masaaktif

    now=$(date +%Y-%m-%d)
    d1=$(date -d "$exp" +%s)
    d2=$(date -d "$now" +%s)
    exp2=$(( (d1 - d2) / 86400 ))
    exp3=$((exp2 + masaaktif))
    exp4=$(date -d "$exp3 days" +"%Y-%m-%d")

    sed -i "/### $user/c\### $user $exp4" "/usr/local/etc/xray/vless.json"

    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m        Renew VLESS Account     \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo " Account Was Successfully Renewed"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo " Client Name : $user"
    echo " Expired On  : $exp4"
    echo -e "\033[0;34m-------------------------------\033[0m"

    rm -f "$tmpfile"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-xray
}

del-xray() {

    tmpfile="/root/usr_tmp.txt"
    grep -E "^### " "/usr/local/etc/xray/vless.json" | awk '{print $2" "$3}' | sort -u > "$tmpfile"
    NUMBER_OF_CLIENTS=$(wc -l < "$tmpfile" | tr -d ' ')

    if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
        echo -e "\nYou have no existing VLESS clients!\n"
        rm -f "$tmpfile"
        read -n 1 -s -r -p "Press any key to back on menu"
        menu-xray
    fi

    clear
    echo -e "\033[0;34m-----------------------------\033[0m"
    echo -e "\E[44;1;39m     Delete VLESS Account     \E[0m"
    echo -e "\033[0;34m-----------------------------\033[0m"
    echo "  User       Expired"
    echo -e "\033[0;34m-----------------------------\033[0m"
    nl -s ') ' "$tmpfile"
    echo -e "\033[0;34m-----------------------------\033[0m"

    read -rp "Select one client [1-${NUMBER_OF_CLIENTS}, or 'x' to cancel]: " CLIENT_NUMBER

    if [[ "$CLIENT_NUMBER" =~ ^[xXqQ]$ || -z "$CLIENT_NUMBER" ]]; then
        echo -e "\nAction canceled!"
        rm -f "$tmpfile"
        read -n 1 -s -r -p "Press any key to back on menu"
        menu-xray
    fi

    if ! [[ "$CLIENT_NUMBER" =~ ^[0-9]+$ ]] || (( CLIENT_NUMBER < 1 || CLIENT_NUMBER > NUMBER_OF_CLIENTS )); then
        echo -e "\nInvalid choice!"
        rm -f "$tmpfile"
        read -n 1 -s -r -p "Press any key to back on menu"
        menu-xray
    fi

    user=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $1}' "$tmpfile")
    exp=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $2}' "$tmpfile")
    hariini=$(date +%Y-%m-%d)

    sed -i "/^### $user $exp/,/\"email\": \"$user\"/d" /usr/local/etc/xray/vless.json
    rm -f /home/vps/public_html/${user}*
    systemctl restart xray >/dev/null 2>&1

    clear
    echo -e "\033[0;34m-----------------------------\033[0m"
    echo -e "\E[44;1;39m     Delete VLESS Account     \E[0m"
    echo -e "\033[0;34m-----------------------------\033[0m"
    echo " Account Deleted Successfully"
    echo -e "\033[0;34m-----------------------------\033[0m"
    echo " Client Name : $user"
    echo " Deleted On  : $hariini"
    echo -e "\033[0;34m-----------------------------\033[0m"

    rm -f "$tmpfile"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-xray
}

cek-login() {
    clear
    tmp_other="/tmp/other.txt"
    tmp_ip="/tmp/ipvmess.txt"

    print_header() {
        local protocol_name="$1"
        local width=40
        echo -e "\033[0;34m$(printf '%.0s-' $(seq 1 $width))\033[0m"
        printf "\E[44;1;39m%*s%s%*s\E[0m\n" \
            $(((width - ${#protocol_name}) / 2)) "" "$protocol_name" \
            $(((width - ${#protocol_name} + 1) / 2)) ""
        echo -e "\033[0;34m$(printf '%.0s-' $(seq 1 $width))\033[0m"
    }

    process_vless() {
        local config_file="/usr/local/etc/xray/vless.json"
        local log_file="/var/log/xray/access.log"
        local protocol_name="Vless"

        echo -n > "$tmp_other"
        data=( $(grep '^###' "$config_file" | cut -d ' ' -f2 | sort -u) )
        print_header "$protocol_name"

        for akun in "${data[@]}"; do
            [[ -z "$akun" ]] && akun="tidakada"
            echo -n > "$tmp_ip"

            data2=( $(tail -n 500 "$log_file" \
                | awk '/from/ {t=$4; if(t !~ /^tcp:/){split(t,a,":"); print a[1]}}' \
                | sort -u) )

            for ip in "${data2[@]}"; do
                jum=$(grep -w "$akun" "$log_file" | tail -n 500 \
                    | awk -v ip="$ip" '/from/ {t=$4; if(t !~ /^tcp:/){split(t,a,":"); if(a[1]==ip) print a[1]}}' \
                    | sort -u)

                if [[ "$jum" == "$ip" ]]; then
                    echo "$jum" >> "$tmp_ip"
                else
                    echo "$ip" >> "$tmp_other"
                fi

                while read -r line; do
                    sed -i "/^$line$/d" "$tmp_other"
                done < "$tmp_ip"
            done

            if [[ -s "$tmp_ip" ]]; then
                echo "user : $akun"
                nl "$tmp_ip"
            fi
            rm -f "$tmp_ip"
        done
    }

    process_vless

    rm -f "$tmp_other" "$tmp_ip"
    echo -e "\033[0;34m$(printf '%.0s-' $(seq 1 40))\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-xray
}

running-1() {
    # Warna
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'

    # Export IP Address
    export IP=$(curl -s https://ipinfo.io/ip)

    # Fungsi cek status systemctl
    cek_status() {
        local service=$1
        local status=$(systemctl is-active "$service" 2>/dev/null)
        if [[ "$status" == "active" ]]; then
            echo -e "${GREEN}Running${NC}"
        else
            echo -e "${RED}Error${NC}"
        fi
    }

    # Cek status service
    status_openssh=$(cek_status ssh)
    status_stunnel5=$(cek_status stunnel4)
    status_dropbear=$(cek_status dropbear)
    status_squid=$(cek_status squid)
    status_ws_epro=$(cek_status ws-stunnel)
    status_xray=$(cek_status xray)

    # Tampilkan hasil
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m   STATUS SERVICE INFORMATION  \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "Server Uptime        : $(uptime -p | cut -d ' ' -f 2-)"
    echo -e "Current Time        : $(date +"%d-%m-%Y %X")"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m      SERVICE INFORMATION      \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "OpenSSH             : $status_openssh"
    echo -e "Dropbear            : $status_dropbear"
    echo -e "Stunnel5            : $status_stunnel5"
    echo -e "Squid               : $status_squid"
    echo -e "NGINX               : $status_nginx"
    echo -e "SSH NonTLS          : $status_ws_epro"
    echo -e "SSH TLS             : $status_ws_epro"
    echo -e "Xray                : $status_xray"
    echo -e "\033[0;34m-------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-xray
}

clear
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m         XRAY MULTIPORT MENU       \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo ""
echo -e " [\e[36m 01 \e[0m] Trial XRay VLess"
echo -e " [\e[36m 02 \e[0m] Add XRay VLess"
echo -e " [\e[36m 03 \e[0m] Delete XRay VLess"
echo -e " [\e[36m 04 \e[0m] Renew XRay VLess"
echo -e " [\e[36m 05 \e[0m] Check User Login XRay Vless"
echo -e " [\e[36m 06 \e[0m] Renew Cert Xray "
echo -e " [\e[36m 07 \e[0m] Check Port Info "
echo -e " [\e[36m 08 \e[0m] Check Running Service "
echo -e " [\e[36m 09 \e[0m] Recall Id Vless User "
echo ""
echo -e "Press x or [ Ctrl+C ]   To-Exit"
echo -e ""
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "Client Name    : $Name"
echo -e "Expiry script  : $scexpireddate"
echo -e "Countdown Days : $sisa_hari Days Left"
echo -e "Script Type    : $sc $scv"
echo -e "\033[0;34m------------------------------------\033[0m"
echo ""
read -p " Select menu : " opt
opt=$(echo "$opt" | sed 's/^0*//')

case $opt in
1)
    clear
    trial-vless
    ;;
2)
    clear
    add-vless
    ;;
3)
    clear
    del-xray vless
    ;;
4)
    clear
    renew-xray vless
    ;;
5)
    clear
    cek-login vless
    ;;
6)
    clear
    certv2ray
    ;;
7)
    clear
    check-port
    ;;
8)
    clear
    running-1
    ;;
9)
    clear
    recreate-vless
    ;;
x|X)
    clear
    menu
    ;;
*)
    clear
    echo -e ""
    echo "Sila Pilih Semula"
    sleep 1
    menu-xray
    ;;
esac
