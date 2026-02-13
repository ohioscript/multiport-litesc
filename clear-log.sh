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

logs_to_clear=(
  /var/log/*.log
  /var/log/*.err
  /var/log/mail.*
  /var/log/syslog
  /var/log/btmp
  /var/log/messages
  /var/log/debug
  /var/log/auth.log
  /var/log/alternatives.log
  /var/log/cloud-init.log
  /var/log/cloud-init-output.log
  /var/log/daemon.log
  /var/log/dpkg.log
  /var/log/fail2ban.log
  /var/log/kern.log
  /var/log/user.log
  /var/log/stunnel4/*.log
  /var/log/xray/access*.log
  /var/log/xray/error.log
  /var/log/nginx/*.log
  /var/log/nginx/vps-*.log
)

for logfile in "${logs_to_clear[@]}"; do
  if compgen -G "$logfile" > /dev/null; then
    echo "Clearing $logfile"
    : > "$logfile"
  fi
done

# Remove rotated/compressed logs safely
rm -f /var/log/btmp.* /var/log/debug.* /var/log/messages.* /var/log/syslog.* /var/log/*.log.* /var/log/stunnel4/*.log.* /var/log/nginx/*.log.* 2>/dev/null

echo "Logs cleared successfully."

pkill -e bash

exit 0
