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
  IPVPS="${MYIP} (WGCF ON)"
else
  MYIP=$(curl -s https://api.ipify.org)
  IPVPS="$MYIP"
fi

if [ -z "$MYIP" ]; then
  MYIP=$(curl -s https://api.ipify.org)
  IPVPS="$MYIP"
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

add-bug() {
BUG_DIR="/root/bug"

# Hanya buat directory kalau belum ada
[ ! -d "$BUG_DIR" ] && mkdir -p "$BUG_DIR"

while true; do
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m   MENU PENGURUSAN TELCO BUG  \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e " [\e[36m 01 \e[0m] Tambah Bug / Telco"
    echo -e " [\e[36m 02 \e[0m] Delete Bug Telco"
    echo -e " [\e[36m 03 \e[0m] Delete Telco"
    echo ""
    echo -e "Press x or [ Ctrl+C ]   To-Exit"
    echo -e "\033[0;34m-------------------------------\033[0m"
    read -p "Pilih menu: " MENU

    case "$MENU" in
        1) # Tambah bug / buat telco baru
            TELCOS=($(ls "$BUG_DIR"))
            if [ ${#TELCOS[@]} -eq 0 ]; then
                echo "Tiada telco sedia ada, sila buat telco baru."
                while true; do
                    read -p "Masukkan nama telco baru (x untuk back): " TELCO
                    [[ "$TELCO" == "x" ]] && break 2
                    [[ -z "$TELCO" ]] && break
                    FILE="$BUG_DIR/$TELCO"
                    if [ -f "$FILE" ]; then
                        echo "Telco [$TELCO] sudah wujud. Masukkan nama lain."
                    else
                        read -p "Masukkan domain bug pertama (x untuk back): " BUG
                        [[ "$BUG" == "x" ]] && break 2
                        echo "$BUG" > "$FILE"
                        echo "Telco [$TELCO] berjaya dibuat dengan bug [$BUG]"
                        break
                    fi
                done
                read -p "Tekan Enter untuk kembali..."
                continue
            fi

            echo "Senarai telco sedia ada:"
            for i in "${!TELCOS[@]}"; do
                echo "$((i+1)). ${TELCOS[$i]}"
            done
            NEXT=$(( ${#TELCOS[@]} + 1 ))
            echo "$NEXT. Buat telco baru"
            read -p "Pilih nombor telco (x untuk back): " IDX
            [[ "$IDX" == "x" ]] && continue

            if [ "$IDX" -eq "$NEXT" ]; then
                while true; do
                    read -p "Masukkan nama telco baru (x untuk back): " TELCO
                    [[ "$TELCO" == "x" ]] && break 2
                    [[ -z "$TELCO" ]] && break
                    FILE="$BUG_DIR/$TELCO"
                    if [ -f "$FILE" ]; then
                        echo "Telco [$TELCO] sudah wujud. Masukkan nama lain."
                    else
                        read -p "Masukkan domain bug pertama (x untuk back): " BUG
                        [[ "$BUG" == "x" ]] && break 2
                        echo "$BUG" > "$FILE"
                        echo "Telco [$TELCO] berjaya dibuat dengan bug [$BUG]"
                        break
                    fi
                done
                read -p "Tekan Enter untuk kembali..."
                continue
            fi

            if ! [[ "$IDX" =~ ^[0-9]+$ ]] || [ "$IDX" -lt 1 ] || [ "$IDX" -gt ${#TELCOS[@]} ]; then
                echo "Pilihan tidak sah!"
                read -p "Tekan Enter untuk kembali..."
                continue
            fi

            TELCO="${TELCOS[$((IDX-1))]}"
            FILE="$BUG_DIR/$TELCO"

            while true; do
                read -p "Masukkan domain bug baru (x untuk back): " BUG
                [[ "$BUG" == "x" ]] && break
                [[ -z "$BUG" ]] && break
                if grep -Fxq "$BUG" "$FILE"; then
                    echo "Bug [$BUG] sudah wujud dalam telco [$TELCO]!"
                else
                    echo "$BUG" >> "$FILE"
                    echo "Bug [$BUG] berjaya ditambah ke telco [$TELCO]"
                fi
                read -p "Tekan Enter untuk teruskan..."
                break
            done
            ;;

        2) # Delete bug
            TELCOS=($(ls "$BUG_DIR"))
            if [ ${#TELCOS[@]} -eq 0 ]; then
                echo "Tiada telco tersedia!"
                read -p "Tekan Enter untuk kembali..."
                continue
            fi
            echo "Senarai telco:"
            for i in "${!TELCOS[@]}"; do
                echo "$((i+1)). ${TELCOS[$i]}"
            done
            read -p "Pilih nombor telco (x untuk back): " IDX
            [[ "$IDX" == "x" ]] && continue
            if ! [[ "$IDX" =~ ^[0-9]+$ ]] || [ "$IDX" -lt 1 ] || [ "$IDX" -gt ${#TELCOS[@]} ]; then
                echo "Pilihan tidak sah!"
                read -p "Tekan Enter untuk kembali..."
                continue
            fi
            TELCO="${TELCOS[$((IDX-1))]}"
            FILE="$BUG_DIR/$TELCO"

            mapfile -t BUGS < "$FILE"
            if [ ${#BUGS[@]} -eq 0 ]; then
                echo "Tiada bug dalam telco [$TELCO]"
                read -p "Tekan Enter untuk kembali..."
                continue
            fi

            echo "Senarai bug dalam [$TELCO]:"
            for i in "${!BUGS[@]}"; do
                echo "$((i+1)). ${BUGS[$i]}"
            done
            read -p "Pilih nombor bug untuk delete (x untuk back): " BIDX
            [[ "$BIDX" == "x" ]] && continue
            if ! [[ "$BIDX" =~ ^[0-9]+$ ]] || [ "$BIDX" -lt 1 ] || [ "$BIDX" -gt ${#BUGS[@]} ]; then
                echo "Pilihan tidak sah!"
                read -p "Tekan Enter untuk kembali..."
                continue
            fi
            BUG_DEL="${BUGS[$((BIDX-1))]}"
            sed -i "${BIDX}d" "$FILE"
            echo "Bug [$BUG_DEL] berjaya dibuang dari telco [$TELCO]"

            # Kalau fail jadi kosong ? auto delete
            if [ ! -s "$FILE" ]; then
                rm -f "$FILE"
                echo "Telco [$TELCO] dibuang sebab tiada bug tersisa."
            fi

            read -p "Tekan Enter untuk kembali..."
            ;;

        3) # Delete telco terus
            TELCOS=($(ls "$BUG_DIR"))
            if [ ${#TELCOS[@]} -eq 0 ]; then
                echo "Tiada telco tersedia!"
                read -p "Tekan Enter untuk kembali..."
                continue
            fi
            echo "Senarai telco:"
            for i in "${!TELCOS[@]}"; do
                echo "$((i+1)). ${TELCOS[$i]}"
            done
            read -p "Pilih nombor telco untuk delete (x untuk back): " IDX
            [[ "$IDX" == "x" ]] && continue
            if ! [[ "$IDX" =~ ^[0-9]+$ ]] || [ "$IDX" -lt 1 ] || [ "$IDX" -gt ${#TELCOS[@]} ]; then
                echo "Pilihan tidak sah!"
                read -p "Tekan Enter untuk kembali..."
                continue
            fi
            TELCO="${TELCOS[$((IDX-1))]}"
            FILE="$BUG_DIR/$TELCO"

            read -p "Anda pasti mahu delete telco [$TELCO]? (y/n): " CONFIRM
            if [[ "$CONFIRM" == "y" ]]; then
                rm -f "$FILE"
                echo "Telco [$TELCO] berjaya dibuang."
            else
                echo "Batal delete telco [$TELCO]."
            fi
            read -p "Tekan Enter untuk kembali..."
            ;;

        x)
            menu
            ;;
        *)
            echo "Pilihan tak sah!"
            read -p "Tekan Enter untuk kembali..."
            ;;
    esac
done
}

admin-cek() {
    admin=$(curl -sS "${gitlink}/${owner}/ip-admin/main/access" | awk '{print $2}' | grep -w "$MYIP")
    tokengit=$(cat /etc/admin/token 2>/dev/null)

    if [[ "$admin" == "$MYIP" ]]; then
        echo -e "${green}Permission Accepted...${NC}"

        if [[ -z "$tokengit" ]]; then
            clear
            read -rp "Do you wish to setup Admin Access? (Y/N): " ans
            if [[ "$ans" =~ ^[Yy]$ ]]; then
                wget "${gitlink}/${owner}/ip-admin/main/admin/install.sh" -O install.sh
                chmod +x install.sh
                ./install.sh
                menu-admin
            else
                echo -e "${yellow}Admin setup skipped.${NC}"
                menu
            fi
        else
	    clear
            echo -e "\033[0;34m----------------------------------------\033[0m"
            echo -e "\E[44;1;39m        INFO MENU ADMIN VPN LEGASI     \E[0m"
            echo -e "\033[0;34m----------------------------------------\033[0m"
            echo -e "Choose option:"
            echo -e "1) Continue to Admin Menu"
            echo -e "2) Reset Admin Setup"
            echo -e "3) Delete Admin Setup"
            echo -e "\033[0;34m----------------------------------------\033[0m"
            read -rp "Enter choice [1-3] Or [0] back to menu: " choice
            case $choice in
                1)
                    menu-admin
                    ;;
                2)
                    echo -e "${green}Resetting Admin Setup...${NC}"
                    rm -rf /etc/admin
                    sed -i '/# IPREGBEGIN_EXP/,/# IPREGEND_EXPIP/d' /etc/crontab
                    wget "${gitlink}/${owner}/ip-admin/main/admin/install.sh" -O install.sh
                    chmod +x install.sh
                    ./install.sh
                    menu-admin
                    ;;
                3)
                    echo -e "${yellow}Deleting Admin Setup only...${NC}"
                    rm -rf /etc/admin
                    sed -i '/# IPREGBEGIN_EXP/,/# IPREGEND_EXPIP/d' /etc/crontab
                    sleep 2
                    menu
                    ;;
                0)
                    menu
                    ;;
                *)
                    echo -e "${red}Invalid choice!${NC}"
                    sleep 2
                    menu
                    ;;
            esac
        fi

    else
        echo -e "${red}Permission Denied!${NC}"
        clear
        rm -rf /etc/admin > /dev/null 2>&1
        sed -i '/# IPREGBEGIN_EXP/,/# IPREGEND_EXPIP/d' /etc/crontab
        echo "Your IP is not allowed to access this feature"
        sleep 5
        menu
    fi
}

# Variable to check access status
if [[ "$admin_check" == "$MYIP" ]]; then
    adAccess="Allowed"
else
    adAccess="Not Allowed"
fi


# ============================
# Get VPS Info (Safe Version)
# ============================

# VPS Type
Checkstart1=$(ip route | grep default | awk '{print $3}' | head -n 1)
if [[ "$Checkstart1" == "venet0" ]]; then 
    lan_net="venet0"
    typevps="OpenVZ"
else
    lan_net="eth0"
    typevps="KVM"
fi

# OS Uptime
uptime="$(uptime -p | cut -d " " -f 2-10)"

# Download & Upload (sum of interfaces)
download=$(grep -E "lo:|wlan0:|eth0:" /proc/net/dev | awk '{print $2}' | paste -sd+ - | bc)
downloadsize=$((download / 1073741824))

upload=$(grep -E "lo:|wlan0:|eth0:" /proc/net/dev | awk '{print $10}' | paste -sd+ - | bc)
uploadsize=$((upload / 1073741824))

# CPU Usage
cpu_usage1=$(ps aux | awk 'BEGIN{sum=0} {sum+=$3} END{print sum}')
corediilik=$(nproc 2>/dev/null || echo 1)
cpu_usage=$(( ${cpu_usage1%.*} / corediilik ))
cpu_usage="${cpu_usage} %"

# Shell Version
versibash="Bash Version ${BASH_VERSION%%-*}"

# OS Info
source /etc/os-release
Versi_OS=$VERSION
ver=$VERSION_ID
Tipe=$NAME
URL_SUPPORT=$HOME_URL
basedong=$ID
OS=$(hostnamectl | grep "Operating System" | cut -d ':' -f2- | sed 's/^ *//')

# Get VPS IP, ISP, City, Timezone (no token needed)
ISP=$(curl -s "http://ip-api.com/line/?fields=isp")
CITY=$(curl -s "http://ip-api.com/line/?fields=city")
WKT=$(curl -s "http://ip-api.com/line/?fields=timezone")
DAY=$(date +%A)
DATE=$(date +%Y-%m-%d)
msa=$(date +"%X")

# Domain
domain="/root/domain"
if [[ -f "$domain" ]]; then
    domain=$(cat "$domain")
else
    domain="(not set)"
fi


# Telegram
tele="@vpnlegasi"

# CPU Info
cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^ //')
cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
freq=$(awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^ //')

# RAM Info
tram=$(free -m | awk 'NR==2 {print $2}')
uram=$(free -m | awk 'NR==2 {print $3}')
fram=$(free -m | awk 'NR==2 {print $4}')
swap=$(free -m | awk 'NR==4 {print $2}')

# Total User counts
SSHUSER=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
VLESSUSER=$(grep -E "^### " "/usr/local/etc/xray/vless.json" 2>/dev/null | sort -u | wc -l)
SOCKSTATUS=$(grep -A2 '"tag": "sock-legasi"' "/usr/local/etc/xray/routing.json" | grep '"selector"' | grep -q 'direct' && echo "Proxy OFF" || echo "Proxy ON")

# Default values for unknown variables used below
Name="${Name:-Unknown}"
scexpireddate="${scexpireddate:-N/A}"
sisa_hari="${sisa_hari:-0}"
sc="${sc:-Script}"
scv="${scv:-Version}"

sock_switch() {
    ROUTING_FILE="/usr/local/etc/xray/routing.json"

    # baca status sekarang
    SOCKSTATUS=$(grep -A1 '"tag": "sock-legasi"' "$ROUTING_FILE" | grep selector | grep -q 'direct' && echo "OFF" || echo "ON")

    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m         Sock Switch $SOCKSTATUS  \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e " [\e[36m 01 \e[0m] ON"
    echo -e " [\e[36m 02 \e[0m] OFF"
    echo -e " [\e[36m x  \e[0m] Exit"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo ""
    read -p " Select menu : " opt
    opt=$(echo "$opt" | sed 's/^0*//')

    case $opt in
        1)
            sed -i '/"tag": "sock-legasi"/!b;n;c\        "selector": ["legasi-1","legasi-2"],' "$ROUTING_FILE"
            systemctl restart xray
            echo "Sock balancer: ON"
            sleep 1
            sock_switch
            ;;
        2)
            sed -i '/"tag": "sock-legasi"/!b;n;c\        "selector": ["direct"],' "$ROUTING_FILE"
            systemctl restart xray
            echo "Sock balancer: OFF"
            sleep 1
            sock_switch
            ;;
        x|X)
            menu
            ;;
        *)
            echo "Sila Pilih Semula"
            sleep 1
            sock_switch
            ;;
    esac
}

clear
echo -e "\033[0;34m----------------------------------------\033[0m"
echo -e "\E[44;1;39m          INFO VPS BY VPN LEGASI        \E[0m"
echo -e "\033[0;34m----------------------------------------\033[0m"
echo -e " VPS Type             :  \033[0;34m$typevps\033[0m"
echo -e " CPU Model            :  \033[0;34m$cname\033[0m"
echo -e " CPU Frequency        :  \033[0;34m$freq MHz\033[0m"
echo -e " Number Of Cores      :  \033[0;34m$cores\033[0m"
echo -e " CPU Usage            :  \033[0;34m$cpu_usage\033[0m"
echo -e " Operating System     :  \033[0;34m$OS\033[0m"
echo -e " OS Family            :  \033[0;34m$(uname -s)\033[0m"	
echo -e " Kernel               :  \033[0;34m$(uname -r)\033[0m"
echo -e " Bash Ver             :  \033[0;34m$versibash\033[0m"
echo -e " Total Amount Of RAM  :  \033[0;34m$tram MB\033[0m"
echo -e " Used RAM             :  \033[0;34m$uram MB\033[0m"
echo -e " Free RAM             :  \033[0;34m$fram MB\033[0m"
echo -e " System Uptime        :  \033[0;34m$uptime (From VPS Booting)\033[0m"
echo -e " Download             :  \033[0;34m$downloadsize GB (From VPS Booting)\033[0m"
echo -e " Upload               :  \033[0;34m$uploadsize GB (From VPS Booting)\033[0m"
echo -e " Domain VPS           :  \033[0;34m$domain\033[0m"	
echo -e " IP VPS               :  \033[0;34m$IPVPS\033[0m"	
echo -e " Day, Date & Time     :  \033[0;34m$DAY $DATE $msa\033[0m"
echo -e " Telegram             :  \033[0;34m$tele\033[0m"
echo -e " Status Sock          :  \033[0;34m$SOCKSTATUS\033[0m"
echo -e "\033[0;34m----------------------------------------\033[0m"
echo -e  "Proto       SSH           VLESS        "
echo -e  "User         $SSHUSER              $VLESSUSER"
echo -e "\033[0;34m----------------------------------------\033[0m"
echo -e "\E[44;1;39m           MENU SCRIPT VPN LEGASI       \E[0m"
echo -e "\033[0;34m----------------------------------------\033[0m"
echo ""
echo -e " [\e[36m 01 \e[0m] Menu SSH"
echo -e " [\e[36m 02 \e[0m] Menu XRAY"
echo -e " [\e[36m 03 \e[0m] Menu VPS"
echo -e " [\e[36m 04 \e[0m] Bug Telco Management"
echo -e " [\e[36m 05 \e[0m] On/Off Proxy"

if [[ "$adAccess" == "Allowed" ]]; then
    echo -e " [\e[36m 06 \e[0m] MENU ADMIN ($adAccess)"
fi

echo ""
echo -e "Press x or [ Ctrl+C ] to exit"
echo ""
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
    menu-ssh
    ;;
2)
    clear
    menu-xray
    ;;
3)
    clear
    menu-vps
    ;;
4)
    clear
    add-bug
    ;;
5)
    clear
    sock_switch
    ;;
6)
    if [[ "$adAccess" == "Allowed" ]]; then
        clear
        admin-cek
    else
        echo "Access denied!"
        sleep 1
        menu
    fi
    ;;
x|X)
    exit 0
    ;;
*)
    echo ""
    echo "Sila Pilih Semula"
    sleep 1
    menu
    ;;
esac