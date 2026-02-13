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

# Cek root dan OpenVZ
if [[ $EUID -ne 0 ]]; then
    echo "You need to run this script as root"
    exit 1
fi

if [[ "$(systemd-detect-virt)" == "openvz" ]]; then
    echo "OpenVZ is not supported"
    exit 1
fi

# Fix hosts
localip=$(hostname -I | cut -d\  -f1)
hst=$(hostname)
dart=$(awk '{print $2}' /etc/hosts | grep -w "$hst")
if [[ "$hst" != "$dart" ]]; then
    echo "$localip $hst" >> /etc/hosts
fi

# Start timer
start=$(date +%s)

# ===== Add Domain Setup Xray =====
clear
echo -e "=== Add Domain Setup Xray ==="
mkdir -p /var/lib/premium-script >/dev/null 2>&1
rm -rf /xray/{scdomain,domain} /v2ray/domain /root/domain
rm -f /var/lib/premium-script/ipvps.conf

# Input Dropbear Name Server
read -rp "Input Dropbear Name Server (No spaces) : " ans
[[ -z "$ans" ]] && ans="@vpnlegasi"
echo "$ans" > /root/servername

# Input Domain (MANDATORY)
pp=""
while [[ -z "$pp" ]]; do
    read -rp "Input your domain (MANDATORY) : " pp
    if [[ -z "$pp" ]]; then
        echo -e "${red}[ERROR]${NC} Domain cannot be empty! Please try again."
    fi
done

echo "$pp" > /root/domain
echo "IP=$pp" > /var/lib/premium-script/ipvps.conf

clear
echo "Begin Update Tools!"
sleep 2
clear

# ===== Set timezone & disable IPv6 =====
timedatectl set-timezone Asia/Kuala_Lumpur
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1

# ===== Install essentials =====
echo -e "[ ${green}INFO${NC} ] Installing required packages..."
sleep 2

# Update & Upgrade System
apt update -y
apt upgrade -y
apt dist-upgrade -y

# Remove unwanted packages
apt remove --purge ufw firewalld exim4 -y
apt autoremove -y
apt clean -y

# ===== Install required packages =====
echo -e "[ ${green}INFO${NC} ] Installing dependencies..."

# Detect OS and Version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=${VERSION_ID%%.*}
else
    OS="unknown"; VER="0"
fi

# Handle deprecated package names
declare -A PKG_MAP=(
    [python]="python3"
    [neofetch]="fastfetch"
    [squid3]="squid"
    [ntpdate]="chrony"
    [libssl1.0-dev]="libssl-dev"
)

# List of required packages
required_pkgs=(
  python make cmake coreutils rsyslog net-tools zip unzip nano sed
  gnupg gnupg1 bc jq apt-transport-https build-essential dirmngr
  libxml-parser-perl neofetch git lsof libsqlite3-dev libz-dev gcc
  shc g++ libreadline-dev zlib1g-dev libssl-dev libssl1.0-dev
  screen curl wget bzip2 gzip iftop htop gnupg2 screenfetch openssl
  openvpn easy-rsa fail2ban tmux stunnel4 vnstat squid3 dropbear
  socat cron bash-completion ntpdate xz-utils dnsutils lsb-release
  chrony nodejs netfilter-persistent iptables iptables-persistent
)

# Replace old packages with new ones
final_pkgs=()
for pkg in "${required_pkgs[@]}"; do
    [[ -n "${PKG_MAP[$pkg]}" ]] && final_pkgs+=("${PKG_MAP[$pkg]}") || final_pkgs+=("$pkg")
done

# Ubuntu 18 compatibility
if [[ "$OS" == "ubuntu" && "$VER" -lt 20 ]]; then
    final_pkgs+=(python-is-python3)
fi

# Debian contrib/non-free repo enable
if [[ "$OS" == "debian" ]]; then
    apt install -y software-properties-common || true

    sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list

    apt update -y || true
fi

# Detect missing packages
missing_pkgs=()
for pkg in "${final_pkgs[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null && ! command -v "$pkg" &>/dev/null; then
        missing_pkgs+=("$pkg")
    fi
done

# Install missing packages only
if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo -e "[ ${green}INFO${NC} ] Installing missing packages: ${missing_pkgs[*]}"
    apt update -y
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends "${missing_pkgs[@]}" || {
        echo -e "[ ${red}WARNING${NC} ] Some packages failed, attempting fix..."
        apt --fix-broken install -y
        apt install -y "${missing_pkgs[@]}"
    }
else
    echo -e "[ ${green}INFO${NC} ] All required packages already installed."
fi

# Ensure basic tools exist
for pkg in bc wget curl; do
    if ! command -v "$pkg" &>/dev/null; then
        echo -e "[ ${red}WARNING${NC} ] $pkg missing, installing..."
        apt update -y
        apt install -y "$pkg"
    fi
done

# ===== Set iptables legacy =====
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
update-alternatives --set arptables /usr/sbin/arptables-legacy
update-alternatives --set ebtables /usr/sbin/ebtables-legacy

# Restart netfilter persistent
systemctl restart netfilter-persistent

echo -e "[ ${green}INFO${NC} ] Essentials installation completed."
sleep 2
clear

# ===== Install SSH & WS =====
echo -e "${green}Install SSH & WS${NC}"
sleep 2
wget "${gitlink}/${int}/${sc}/main/ssh-vpn.sh" -O ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
clear

# ===== Install OHP =====
echo -e "${green}Install OHP${NC}"
sleep 2
wget "${gitlink}/${int}/${sc}/main/ohp.sh" -O ohp.sh && chmod +x ohp.sh && ./ohp.sh
clear

# ===== Install XRAY =====
echo -e "${green}Install XRAY${NC}"
sleep 2
wget "${gitlink}/${int}/${sc}/main/ins-xray.sh" -O ins-xray.sh && chmod +x ins-xray.sh && ./ins-xray.sh
clear

# ===== Install XRAY =====
echo -e "${green}Install SSHWS${NC}"
sleep 2
wget "${gitlink}/${int}/${sc}/main/sshws/insshws.sh" -O insshws.sh && chmod +x insshws.sh && ./insshws.sh
clear

# ===== Install Menu =====
echo -e "${green}Install Menu${NC}"
declare -A menu_files=(
    ["menu"]="main/menu.sh"
    ["menu-ssh"]="main/menu-ssh.sh"
    ["menu-xray"]="main/menu-xray.sh"
    ["menu-vps"]="main/menu-vps.sh"
    ["ram"]="resources/main/service/ram.sh"
    ["speedtest"]="resources/main/service/speedtest_cli.py"
    ["running"]="main/running.sh"
    ["clearlog"]="main/clear-log.sh"
    ["xp"]="main/xp.sh"
)

for cmd in "${!menu_files[@]}"; do
    url="${gitlink}/${int}/${sc}/${menu_files[$cmd]}"
    if [[ "$cmd" == "ram" || "$cmd" == "speedtest" ]]; then
        url="${gitlink}/${owner}/${menu_files[$cmd]}"
    fi
    wget -O "/usr/bin/$cmd" "$url" && chmod +x "/usr/bin/$cmd"
done

# ===== Setup cron jobs =====
grep -q "/sbin/hwclock -w" /etc/crontab || echo "0 0 * * * root /sbin/hwclock -w" >> /etc/crontab
grep -q "/usr/bin/clearlog" /etc/crontab || echo "0 */2 * * * root /usr/bin/clearlog" >> /etc/crontab
grep -q "/usr/bin/xp" /etc/crontab || echo "2 0 * * * root /usr/bin/xp" >> /etc/crontab

# ===== Update .profile =====
cat > /root/.profile << EOF
if [ "\$BASH" ] && [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
mesg n || true
running
sleep 2
clear
menu
EOF
chmod 644 /root/.profile

# ===== Port Info =====
cat > /root/log-install.txt << 'EOF'
===============-[ VPN LEGASI Premium Script ]-==============

------------------------------------------------------------
                   Service & Port Information               
------------------------------------------------------------
                             OpenVPN                        
------------------------------------------------------------
   - OpenSSH                 : 22
   - SSH Websocket           : 80,8080 [OFF]
   - SSH SSL Websocket       : 443
   - Stunnel4                : 447, 777
   - Dropbear                : 109, 143
   - Badvpn                  : 7100-7900
   - Nginx                   : 81
   - Squid                   : 8000
   - OHP                     : 8000
   - Wireguard               : 443,80
------------------------------------------------------------
                            XRAY HTTPS                      
------------------------------------------------------------
   - XRAY  Vless TLS         : 443
   - XRAY  Vless HttpUpgrade : 443
   - XRAY  Vless gRPC        : 443
------------------------------------------------------------
                            XRAY HTTP                       
------------------------------------------------------------
   - XRAY  Vless None TLS    : 80,8080
   - XRAY  Vless HttpUpgrade : 80,8080

------------------------------------------------------------
               Server Information & Other Features          
------------------------------------------------------------
   - Timezone                : Asia/Kuala_Lumpur (GMT +8)
   - Auto Backup Status      : [OFF]
   - Fail2Ban                : [ON]
   - Dflate                  : [ON]
   - IPtables                : [ON]
   - IPv6                    : [OFF]
   - AutoKill Multi Login User
   - Auto Delete Expired Account
   - Fully automatic script
   - VPS settings
   - Backup Data
   - Restore Data
   - Full Orders For Various Services
------------------------------------------------------------

===============-[ Script MOD By VPN Legasi ]-===============
EOF

# ===== Masa proses =====
secs_to_human() { echo "$(($1/3600))h $((($1%3600)/60))m $(($1%60))s"; }
secs_to_human "$(( $(date +%s) - start ))" >> /root/log-install.txt

# ===== Cleanup =====
rm -f /etc/afak.conf
[ ! -f /etc/log-create-user.log ] && echo "Log All Account" > /etc/log-create-user.log
rm -f /root/*.sh
history -c && history -w

# =====  Reboot & Show Port Info =====
clear
cat /root/log-install.txt
echo -e "\nSystem will reboot in 10 seconds..."

sleep 10
reboot
