#!/bin/bash

# Warna
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\e[0m'
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
#  VPN Installer OpenVPN/Easy-RSA
# ==================================================
export DEBIAN_FRONTEND=noninteractive
OS=$(uname -m)
MYIP2="s/xxxxxxxxx/$MYIP/g"
ANU=$(ip -o -4 route show to default | awk '{print $5}')

apt update -y
apt install -y openvpn easy-rsa unzip iptables-persistent

mkdir -p /etc/openvpn/server/easy-rsa/
wget -qO /etc/openvpn/vpn.zip ${gitlink}/${owner}/resources/main/service/vpn.zip
unzip -o /etc/openvpn/vpn.zip -d /etc/openvpn/ && rm -f /etc/openvpn/vpn.zip
chown -R root:root /etc/openvpn/server/easy-rsa/

# Plugin PAM auth
mkdir -p /usr/lib/openvpn/
cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so \
   /usr/lib/openvpn/openvpn-plugin-auth-pam.so

# Auto start OpenVPN services
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
for svc in server-tcp-1194 server-udp-2200 server-tcp-ssl; do
    systemctl enable --now openvpn-server@$svc
done

# IPv4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# ==================================================
#  Generate Client Config
# ==================================================
make_client_conf() {
    local FILE=$1
    local PROTO=$2
    local PORT=$3
    local USE_PROXY=$4

    cat > /etc/openvpn/${FILE}.ovpn <<-EOF
setenv FRIENDLY_NAME "OVPN VPN LEGASI"
setenv CLIENT_CERT 0
client
dev tun
proto ${PROTO}
remote ${MYIP} ${PORT}
$( [ "$USE_PROXY" = "yes" ] && echo "http-proxy ${MYIP} 8000
http-proxy-option CUSTOM-HEADER X-Forwarded-Host domain.com" )
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

    cp /etc/openvpn/${FILE}.ovpn /home/vps/public_html/${FILE}.ovpn
    echo -e "${GREEN}Generated ${FILE}.ovpn${NC}"
}

make_client_conf client-tcp-1194 tcp 1194 yes
make_client_conf client-udp-2200 udp 2200
make_client_conf client-tcp-ssl tcp 442 yes

# ==================================================
#  Firewall Rules
# ==================================================
for subnet in 10.6.0.0/24 10.7.0.0/24; do
    iptables -t nat -I POSTROUTING -s $subnet -o $ANU -j MASQUERADE
done
iptables-save > /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Restart OpenVPN
systemctl restart openvpn

# Bersihkan
history -c
