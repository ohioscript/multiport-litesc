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

red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

clear

# =========================================
# SSH/VPN Installer — VPN Legasi (multi-OS)
# Support: Debian 10/11/12, Ubuntu 18/20/22/24
# =========================================
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

# ====== Vars ======
MYIP=$(wget -qO- ipinfo.io/ip)
MYIP2="s/xxxxxxxxx/$MYIP/g"
NAME_FILE="/root/servername"
NAME="$( [ -f "$NAME_FILE" ] && cat "$NAME_FILE" || echo "VPNLegasi" )"
NAME2="s/xxxx12xxxxx/$NAME/g"
NET=$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' | head -n1)
[ -z "$NET" ] && NET="eth0"

source /etc/os-release
OS_ID="${ID:-debian}"
OS_VER="${VERSION_ID:-0}"
OS_VER_MAIN="$(echo "$OS_VER" | awk -F. '{print $1}')"

# SSL Cert Info (stunnel)
C="MY"; ST="Johor"; L="KotaTinggi"; O="vpnlegasi"; OU="vpnlegasi"
CN="vpnlegasi.com"; EMAIL="ovpnlegasi@gmail.com"

# ====== Helpers ======
is_cmd() { command -v "$1" >/dev/null 2>&1; }

svc_enable_restart() {
  local SVC="$1"
  if is_cmd systemctl && systemctl list-unit-files | grep -q "^${SVC}\.service"; then
    systemctl daemon-reload || true
    systemctl enable "$SVC" >/dev/null 2>&1 || true
    systemctl restart "$SVC" || systemctl start "$SVC" || true
  elif [ -x "/etc/init.d/$SVC" ]; then
    update-rc.d "$SVC" defaults >/dev/null 2>&1 || true
    /etc/init.d/"$SVC" restart || /etc/init.d/"$SVC" start || true
  else
    service "$SVC" restart 2>/dev/null || service "$SVC" start 2>/dev/null || true
  fi
}

append_once() { # append_once "line" "file"
  local LINE="$1" FILE="$2"
  grep -qxF "$LINE" "$FILE" 2>/dev/null || echo "$LINE" >>"$FILE"
}

# ====== Base packages ======
echo "[+] Update & install base packages"
apt-get update -y
apt-get install -y curl wget ca-certificates lsb-release gnupg \
  iproute2 net-tools screen sudo unzip tar build-essential \
  nginx dropbear squid stunnel4 fail2ban vnstat libsqlite3-dev \
  iptables-persistent netfilter-persistent

# ====== Enable rc.local (systemd) & disable IPv6 ======
echo "[+] Configure rc.local & disable IPv6"
cat >/etc/systemd/system/rc-local.service <<'EOF'
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=journal
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/rc.local <<'EOF'
#!/bin/sh -e
exit 0
EOF
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1 || true
systemctl start rc-local.service >/dev/null 2>&1 || true

echo 1 >/proc/sys/net/ipv6/conf/all/disable_ipv6
append_once "echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6" /etc/rc.local

# ====== Password policy (optional remote) ======
if [ -n "$gitlink" ] && [ -n "$owner" ]; then
  echo "[+] Apply password policy (remote)"
  wget -qO /etc/pam.d/common-password "${gitlink}/${owner}/resources/main/service/password" || true
  chmod 644 /etc/pam.d/common-password 2>/dev/null || true
fi

# ====== Nginx minimal config (port 81 for public_html) ======
echo "[+] Configure Nginx"
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default /etc/nginx/nginx.conf

cat >/etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes 1;
pid /var/run/nginx.pid;

events {
  multi_accept on;
  worker_connections 1024;
}

http {
  gzip on;
  gzip_vary on;
  gzip_comp_level 5;
  gzip_types text/plain application/x-javascript text/xml text/css;
  autoindex on;
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  server_tokens off;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;
  client_max_body_size 32M;
  client_header_buffer_size 4k;
  large_client_header_buffers 8 16k;
  fastcgi_buffer_size 32k;
  fastcgi_buffers 8 16k;
  fastcgi_read_timeout 600;
  real_ip_header CF-Connecting-IP;

  include /etc/nginx/conf.d/*.conf;
}
EOF

mkdir -p /home/vps/public_html
cat >/etc/nginx/conf.d/vps.conf <<'EOF'
server {
  listen 81;
  server_name 127.0.0.1 localhost;
  root /home/vps/public_html;

  access_log /var/log/nginx/vps-access.log;
  error_log /var/log/nginx/vps-error.log error;

  location / {
    index index.html index.htm index.php;
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include /etc/nginx/fastcgi_params;
    fastcgi_pass 127.0.0.1:9000;  # pastikan php-fpm listen ke 9000 jika perlu
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  }
}
EOF
svc_enable_restart nginx

# ====== BadVPN (multi-port via systemd) ======
echo "[+] Install BadVPN"
if [ -n "$gitlink" ] && [ -n "$owner" ]; then
  wget -qO /usr/bin/badvpn-udpgw "${gitlink}/${owner}/resources/main/service/badvpn-udpgw64" || true
  chmod +x /usr/bin/badvpn-udpgw 2>/dev/null || true
fi

if [ -x /usr/bin/badvpn-udpgw ]; then
  cat >/etc/systemd/system/badvpn@.service <<'EOF'
[Unit]
Description=BadVPN UDPGW on port %i
Documentation=BadVPN by VPN Legasi - https://t.me/vpnlegasi
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:%i --max-clients 500
Restart=always
User=www-data
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

  chown www-data:www-data /usr/bin/badvpn-udpgw
  chmod +x /usr/bin/badvpn-udpgw

  systemctl daemon-reload
  echo "[+] Enabling BadVPN instances..."
  for port in {7100..7900..100}; do
    systemctl enable --now badvpn@$port >/dev/null 2>&1
  done
  echo "[+] All BadVPN instances enabled and running."
fi

# ====== OpenSSH (multi-port) ======
echo "[+] Configure OpenSSH ports"
SSHD_CFG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CFG" ]; then
  sed -i 's/^\s*#\?\s*Port\s\+22.*/Port 22/' "$SSHD_CFG"
  awk '!p&&/Port 22/{print;print "Port 200\nPort 500\nPort 51443\nPort 58080\nPort 40000";p=1;next}1' "$SSHD_CFG" > /tmp/sshd_config.new && mv /tmp/sshd_config.new "$SSHD_CFG"
fi
svc_enable_restart ssh

# ====== Dropbear (systemd-friendly) ======
echo "[+] Configure Dropbear (systemd + init.d compatible)"
# Legacy default file tetap buat (untuk tool lama yang refer /etc/default/dropbear)
cat >/etc/default/dropbear <<'EOF'
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_EXTRA_ARGS="-p 50000 -p 109 -p 110 -p 69 -b /etc/issue.net -w -g"
DROPBEAR_BANNER="/etc/issue.net"
EOF

mkdir -p /etc/systemd/system/dropbear.service.d
cat >/etc/systemd/system/dropbear.service.d/override.conf <<'EOF'
[Service]
Type=simple
ExecStart=
ExecStart=/usr/sbin/dropbear -F -E -p 143 -p 50000 -p 109 -p 110 -p 69 -b /etc/issue.net -w -g
Restart=on-failure
EOF

append_once "/bin/false" /etc/shells
append_once "/usr/sbin/nologin" /etc/shells

systemctl daemon-reload || true
svc_enable_restart dropbear

# ====== Squid ======
echo "[+] Configure Squid"
SQUID_CONF="/etc/squid/squid.conf"
cat >"$SQUID_CONF" <<'EOF'
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 442
acl Safe_ports port 21 70 80 210 443 280 488 591 777 1025-65535
acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 3128
coredump_dir /var/spool/squid
visible_hostname VPNLegasi
EOF
sed -i "$MYIP2" "$SQUID_CONF"
svc_enable_restart squid

# ====== VNStat (build 2.6) ======
echo "[+] Configure VNStat"
svc_enable_restart vnstat
if ! vnstat --version 2>/dev/null | grep -q '2\.6'; then
  wget -qO /root/vnstat.tar.gz https://humdi.net/vnstat/vnstat-2.6.tar.gz || true
  if [ -f /root/vnstat.tar.gz ]; then
    tar xzf /root/vnstat.tar.gz -C /root/
    (cd /root/vnstat-2.6 && ./configure --prefix=/usr --sysconfdir=/etc && make && make install) || true
    rm -rf /root/vnstat-2.6 /root/vnstat.tar.gz
  fi
fi
vnstat -u -i "$NET" 2>/dev/null || true
sed -i "s/Interface.*/Interface \"$NET\"/" /etc/vnstat.conf 2>/dev/null || true
chown vnstat:vnstat /var/lib/vnstat -R 2>/dev/null || true
svc_enable_restart vnstat

# ====== Stunnel4 (systemd enable + cert) ======
echo "[+] Configure Stunnel4"
mkdir -p /etc/stunnel

cat >/etc/stunnel/stunnel.conf <<'EOF'
cert = /etc/stunnel/stunnel.pem
client = no
foreground = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear-1]
accept = 789
connect = 127.0.0.1:109

[dropbear-2]
accept = 777
connect = 127.0.0.1:22

[ws-stunnel]
accept = 2096
connect = 127.0.0.1:700

[openvpn]
accept = 442
connect = 127.0.0.1:1194
EOF

# Generate self-signed cert (3 years)
openssl genrsa -out /etc/stunnel/key.pem 2048
openssl req -new -x509 -key /etc/stunnel/key.pem -out /etc/stunnel/cert.pem -days 1095 \
  -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}/emailAddress=${EMAIL}"

# Combine cert & key into PEM file
cat /etc/stunnel/key.pem /etc/stunnel/cert.pem > /etc/stunnel/stunnel.pem
rm -f /etc/stunnel/key.pem /etc/stunnel/cert.pem

# Secure permissions (important to avoid warning)
chown root:root /etc/stunnel/stunnel.pem
chmod 600 /etc/stunnel/stunnel.pem

# Ensure PID folder exists with correct ownership
mkdir -p /var/run/stunnel4
touch /var/run/stunnel4/stunnel4.pid
chown stunnel4:stunnel4 /var/run/stunnel4

# Enable stunnel in default config
if [ -f /etc/default/stunnel4 ]; then
  sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
fi

# Restart and enable service
systemctl daemon-reload
systemctl enable stunnel4
systemctl restart stunnel4

# ====== OpenVPN (ikut skrip asal jika ada) ======
if [ -n "$gitlink" ] && [ -n "$int" ] && [ -n "$sc" ]; then
  echo "[+] Run OpenVPN installer from remote"
  (cd /root && wget -q "${gitlink}/${int}/${sc}/main/vpn.sh" && chmod +x vpn.sh && ./vpn.sh) || echo "[!] OpenVPN script failed or skipped."
else
  echo "[i] OpenVPN remote not provided (skipped)."
fi

# ====== Fail2ban ======
echo "[+] Ensure Fail2Ban running"
svc_enable_restart fail2ban

# ====== Anti-DDoS (DOS-Deflate) ======
echo "[+] Install DOS-Deflate"
mkdir -p /usr/local/ddos
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
wget -q -O /usr/local/ddos/LICENSE   http://www.inetbase.com/scripts/ddos/LICENSE
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
wget -q -O /usr/local/ddos/ddos.sh  http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
ln -sf /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
/usr/local/ddos/ddos.sh --cron >/dev/null 2>&1 || true

# ====== Banner ======
echo "[+] Setup Banner"
cat >/etc/issue.net <<'EOF'
---------------------------------------------------------------------- 
                       AUTOSCRIPT BY VPN LEGASI
---------------------------------------------------------------------- 
                   Server  : xxxx12xxxxx
                   Contact : https://t.me/vpnlegasi
---------------------------------------------------------------------- 
Rules:
  • No SPAM         • No DDOS
  • No HACKING      • No CARDING
  • No TORRENT      • No MULTI-LOGIN
---------------------------------------------------------------------- 
⚠ Use responsibly.
⚠ Violations will result in BAN.
---------------------------------------------------------------------- 
EOF

sed -i "$NAME2" /etc/issue.net
append_once "Banner /etc/issue.net" /etc/ssh/sshd_config
if [ -f /etc/default/dropbear ]; then
  sed -i 's@^DROPBEAR_BANNER=.*@DROPBEAR_BANNER="/etc/issue.net"@' /etc/default/dropbear
fi
svc_enable_restart ssh
svc_enable_restart dropbear

# ====== Torrent block ======
echo "[+] Apply torrent block (iptables)"
TOR_STRINGS=("get_peers" "announce_peer" "find_node" "BitTorrent" "BitTorrent protocol" \
             "peer_id=" ".torrent" "announce.php?passkey=" "torrent" "announce" "info_hash")
for s in "${TOR_STRINGS[@]}"; do
  iptables -C FORWARD -m string --algo bm --string "$s" -j DROP 2>/dev/null || \
  iptables -A FORWARD -m string --algo bm --string "$s" -j DROP
done
iptables-save >/etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
netfilter-persistent save >/dev/null 2>&1 || true
netfilter-persistent reload >/dev/null 2>&1 || true

# ====== Cleanup & Web assets ======
echo "[+] Cleanup & deploy web assets"
apt-get -y autoremove --purge unscd samba* apache2* bind9* sendmail* 2>/dev/null || true
apt-get autoclean -y

if [ -n "$gitlink" ] && [ -n "$owner" ]; then
  wget -qO /root/web.tar.gz "${gitlink}/${owner}/resources/main/service/web.tar.gz" && \
  tar xzf /root/web.tar.gz -C /home/vps/public_html && rm -f /root/web.tar.gz
fi
chown -R www-data:www-data /home/vps/public_html 2>/dev/null || true
svc_enable_restart nginx

# ====== Ensure BadVPN sessions up after restarts ======
if [ -x /usr/bin/badvpn-udpgw ]; then
  for port in {7100..7900..100}; do
    # Start if not already
    pgrep -fa "badvpn-udpgw.*$port" >/dev/null || \
    screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:$port --max-clients 500
  done
fi

# ====== History & final cleanup ======
[ -f "$NAME_FILE" ] && rm -f "$NAME_FILE"
rm -f /root/ssh-vpn.sh
history -c 2>/dev/null || true
append_once "unset HISTFILE" /etc/profile

clear
echo "========================================"
echo "  SSH/VPN Setup Selesai — VPN Legasi"
echo "  OS: ${PRETTY_NAME:-$OS_ID $OS_VER}"
echo "  Interface: $NET | IP: $MYIP"
echo "========================================"
