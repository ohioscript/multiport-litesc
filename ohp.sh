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
rm -f -- "$0"

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

# ==================================================
#  Open HTTP Puncher (OHP) by VPN Legasi
#  Direct Proxy Squid for OpenVPN TCP
# ==================================================

# Warna terminal
RED='\e[1;31m'
BLUE='\e[0;34m'
GREEN='\e[0;32m'
NC='\e[0m'

# IP Server
MYIP=$(wget -qO- ipinfo.io/ip)
MYIP2="s/xxxxxxxxx/$MYIP/g"

# Port Config (ubah ikut keperluan)
PORT_OVPN_TCP=1194
PORT_SQUID=3128
PORT_OHP=8000

# ==================================================
#  Update & Upgrade VPS
# ==================================================
clear
apt update && apt-get -y upgrade

# ==================================================
#  Install OHP Binary
# ==================================================
wget -O /usr/local/bin/ohp "${gitlink}/${owner}/resources/main/service/ohp"
chmod +x /usr/local/bin/ohp

# ==================================================
#  Generate OVPN Config (TCP OHP)
# ==================================================
cat > /etc/openvpn/tcp-ohp.ovpn <<-EOF
setenv FRIENDLY_NAME "OHP VPN LEGASI"
setenv CLIENT_CERT 0
client
dev tun
proto tcp
remote bug.com 443
http-proxy $MYIP $PORT_OHP
http-proxy-option CUSTOM-HEADER "X-Forwarded-Host bug.com"
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>
EOF

# Ganti placeholder IP
sed -i $MYIP2 /etc/openvpn/tcp-ohp.ovpn

# Copy ke public_html untuk download
cp /etc/openvpn/tcp-ohp.ovpn /home/vps/public_html/tcp-ohp.ovpn

# ==================================================
#  Buat Service OHP
# ==================================================
cat > /etc/systemd/system/ohp.service <<-EOF
[Unit]
Description=Direct Squid Proxy For OpenVPN TCP By VPN Legasi
Documentation=${host}
Documentation=${host}
Wants=network.target
After=network.target

[Service]
ExecStart=/usr/local/bin/ohp -port $PORT_OHP -proxy 127.0.0.1:$PORT_SQUID -tunnel 127.0.0.1:$PORT_OVPN_TCP
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ==================================================
#  Enable & Restart Service
# ==================================================
systemctl daemon-reload
systemctl enable ohp
systemctl restart ohp

# ==================================================
#  Info
# ==================================================
clear
echo -e "${GREEN}✅ OHP Server Installed Successfully${NC}"
echo -e "Port OVPN OHP TCP : $PORT_OHP"
echo -e "Download Config   : http://$MYIP:81/tcp-ohp.ovpn"
echo -e "Script By VPN Legasi"

# Cleanup
rm -f /root/ohp.sh  2>/dev/null
