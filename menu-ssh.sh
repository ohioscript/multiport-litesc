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

autokill-menu() {
    # Status warna
    Info="\033[32m[ON]\033[0m"
    Error="\033[31m[OFF]\033[0m"

    cek=$(grep -c -E "^# Autokill" /etc/cron.d/tendang 2>/dev/null || echo 0)
    sts=$([[ "$cek" == "1" ]] && echo -e "$Info" || echo -e "$Error")

    clear
    echo -e "-------------------------------"
    echo -e "       AUTOKILL SSH"
    echo -e "-------------------------------"
    echo -e "Status Autokill : $sts"
    echo -e ""
    echo -e "[1] AutoKill After 5 Minutes"
    echo -e "[2] AutoKill After 10 Minutes"
    echo -e "[3] AutoKill After 15 Minutes"
    echo -e "[4] Turn Off AutoKill/MultiLogin"
    echo -e "-------------------------------"
    echo ""

    read -rp "Select From Options [1-4 or x] : " AutoKill
    [[ -z $AutoKill ]] && autokill-menu && return

    if [[ $AutoKill =~ ^[1-3]$ ]]; then
        read -rp "Maximum MultiLogin Allowed: " max
        [[ -z $max || ! $max =~ ^[0-9]+$ ]] && echo "Invalid input" && sleep 1 && autokill-menu && return
    fi

    clear
    case $AutoKill in
        1|2|3)
            minutes=$((5 * AutoKill))
            echo -e "# Autokill\n*/$minutes * * * * root /usr/bin/tendang $max" >/etc/cron.d/tendang
            echo "Allowed MultiLogin : $max"
            echo "AutoKill Every     : $minutes Minutes"
            ;;
        4)
            rm -f /etc/cron.d/tendang
            echo "AutoKill MultiLogin Turned Off"
            ;;
        x|X)
            autokill-menu
            return
            ;;
        *)
            echo "Invalid option"
            sleep 1
            autokill-menu
            return
            ;;
    esac

    systemctl restart cron >/dev/null 2>&1
    systemctl reload cron >/dev/null 2>&1

    read -n 1 -s -r -p "Press any key to return"
    menu-ssh
}

create-ssh-user() {
  local username=$1
  local password=$2
  local expired_days=$3

  # Generate username if empty (trial)
  if [[ -z $username ]]; then
    username=trial$(</dev/urandom tr -dc X-Z0-9 | head -c4)
  fi

  # Default password if empty
  if [[ -z $password ]]; then
    password=1
  fi

  # Default expired_days if empty
  if [[ -z $expired_days ]]; then
    expired_days=1
  fi

  # Create user with expiry date
  useradd -e "$(date -d "$expired_days days" +%Y-%m-%d)" -s /bin/false -M "$username"
  echo -e "$password\n$password\n" | passwd "$username" &>/dev/null

  # Gather info for display
  local hariini=$(date +%d-%m-%Y)
  local expp=$(chage -l "$username" | grep "Account expires" | awk -F": " '{print $2}')
  local exp=$(date -d "$expp" "+%d-%m-%Y")
  local IP=$MYIP
  local domain=$(cat /root/domain)

  # Read ports and services from log-install.txt
  local portsshws=$(grep -w "SSH Websocket" ~/log-install.txt | cut -d: -f2 | tr -d ' ' | cut -d, -f1)
  local portsshws1=$(grep -w "SSH Websocket" ~/log-install.txt | cut -d: -f2 | tr -d ' ' | cut -d'[' -f1)
  local wsssl=$(grep -w "SSH SSL Websocket" /root/log-install.txt | cut -d: -f2 | awk '{print $1}')
  local ossl=$(grep -w "OpenVPN" /root/log-install.txt | cut -f2 -d: | awk '{print $6}')
  local opensh=$(grep -w "OpenSSH" /root/log-install.txt | cut -f2 -d: | awk '{print $1}')
  local db=$(grep -w "Dropbear" /root/log-install.txt | cut -f2 -d: | awk '{print $1,$2}')
  local ssl=$(grep -w "Stunnel4" ~/log-install.txt | cut -d: -f2)
  local sqd=$(grep -w "Squid" ~/log-install.txt | cut -d: -f2)
  local OHP=$(grep -w "OHP" /root/log-install.txt | cut -d: -f2 | awk '{print $1}')
  local ovpn=$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)
  local ovpn2=$(netstat -nlpu | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)
  
  clear
  echo -e "\033[0;34m------------------------------------\033[0m"
  echo -e "\E[44;1;39m        SSH USER ACCOUNT INFO       \E[0m"
  echo -e "\033[0;34m------------------------------------\033[0m"
  echo -e "Username     : $username"
  echo -e "Password     : $password"
  echo -e "Created date : $hariini"
  echo -e "Expired On   : $exp"
  echo -e "IP           : $IP"
  echo -e "Host         : $domain"
  echo -e "\033[0;34m------------------------------------\033[0m"
  echo -e "OpenSSH      : $opensh"
  echo -e "Dropbear     : $db"
  echo -e "SSH-WS       : $portsshws1"
  echo -e "SSH-SSL-WS   : $wsssl"
  echo -e "SSL/TLS      : $ssl"
  echo -e "Port Squid   : $sqd"
  echo -e "OHP SSH      : $OHP"
  echo -e "UDPGW        : 7100-7300"
  echo -e "\033[0;34m------------------------------------\033[0m"
  echo -e "Config OVPN"
  echo -e "OpenVPN      : TCP $ovpn http://$IP:81/client-tcp-$ovpn.ovpn"
  echo -e "OpenVPN      : UDP $ovpn2 http://$IP:81/client-udp-$ovpn2.ovpn"
  echo -e "OpenVPN      : SSL $ssl http://$IP:81/client-tcp-ssl.ovpn"
  echo -e "OHPVPN       : OHP $OHP http://$IP:81/tcp-ohp.ovpn"
  echo -e "\033[0;34m------------------------------------\033[0m"
  echo -e "Payload WS"
  echo -e ' ``` '
  echo -e "GET wss://bug.com HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
  echo ""
  echo -e ' ``` '
  echo -e "Payload WS"
  echo -e ' ``` '
  echo "GET /cdn-cgi/trace HTTP/1.1[crlf]Host: [host][crlf][crlf]CF-RAY / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: Websocket[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
  echo -e ' ``` '
  echo -e "\033[0;34m------------------------------------\033[0m"
  echo -e "Remote Proxy"
  echo -e ' ``` '
  echo -e "bug.com:$portsshws"
  echo -e ' ``` '
  echo ""
  echo -e "Remote Proxy"
  echo -e ' ``` '
  echo -e "bug.com:$wsssl"
  echo -e ' ``` '
  echo -e "\033[0;34m------------------------------------\033[0m"
  echo ""
  read -n 1 -s -r -p "Press any key to back on menu"
  menu-ssh
}

trial-ssh() {
  create-ssh-user
}

add-ssh() {
  read -rp "Username : " user
  read -rp "Password : " pass
  read -rp "Expired (hari): " days
  create-ssh-user "$user" "$pass" "$days"
}

cek-ssh() {
clear
echo " "
echo " "
if [ -e "/var/log/auth.log" ]; then
        LOG="/var/log/auth.log";
fi
if [ -e "/var/log/secure" ]; then
        LOG="/var/log/secure";
fi            
data=( `ps aux | grep -i dropbear | awk '{print $2}'`);
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m         Dropbear User Login        \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo "ID  |  Username  |  IP Address";
echo -e "\033[0;34m------------------------------------\033[0m"
cat $LOG | grep -i dropbear | grep -i "Password auth succeeded" > /tmp/login-db.txt;
for PID in "${data[@]}"
do
        cat /tmp/login-db.txt | grep "dropbear\[$PID\]" > /tmp/login-db-pid.txt;
        NUM=`cat /tmp/login-db-pid.txt | wc -l`;
        USER=`cat /tmp/login-db-pid.txt | awk '{print $10}'`;
        IP=`cat /tmp/login-db-pid.txt | awk '{print $12}'`;
        if [ $NUM -eq 1 ]; then
        echo "$PID - $USER - $IP";
        fi
done

	echo -e "\033[0;34m------------------------------------\033[0m"
	echo -e "\E[44;1;39m         SSHWS TCP User Login       \E[0m"
	echo -e "\033[0;34m------------------------------------\033[0m"
  echo "ID  |  Username  |  IP Address  |  Connected Since";
  echo -e "\033[0;34m------------------------------------\033[0m"

for pid in $(ps -ef | grep "[d]ropbear" | awk '$3 != 1 {print $2}'); do
    # semak log untuk pid ni
    logline=$(journalctl -u dropbear --no-pager | grep "Password auth succeeded" | grep "\[$pid\]" | tail -n1)
    if [[ -n "$logline" ]]; then
        user=$(echo "$logline" | grep -oP "for '([^']+)'" | cut -d"'" -f2)
        ip=$(echo "$logline" | grep -oP "from ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" | awk '{print $2}')
        since=$(ps -o lstart= -p $pid 2>/dev/null)
        printf "%-5s | %-14s | %-15s | %s\n" "$pid" "$user" "$ip" "$since"
    fi
done | sort -n

echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m          OpenSSH User Login        \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo "ID  |  Username  |  IP Address";
echo -e "\033[0;34m------------------------------------\033[0m"
cat $LOG | grep -i sshd | grep -i "Accepted password for" > /tmp/login-db.txt
data=( `ps aux | grep "\[priv\]" | sort -k 72 | awk '{print $2}'`);
for PID in "${data[@]}"
do
        cat /tmp/login-db.txt | grep "sshd\[$PID\]" > /tmp/login-db-pid.txt;
        NUM=`cat /tmp/login-db-pid.txt | wc -l`;
        USER=`cat /tmp/login-db-pid.txt | awk '{print $9}'`;
        IP=`cat /tmp/login-db-pid.txt | awk '{print $11}'`;
        if [ $NUM -eq 1 ]; then
        echo "$PID - $USER - $IP";
        fi
echo -e "\033[0;34m------------------------------------\033[0m"
done
if [ -f "/etc/openvpn/server/openvpn-tcp.log" ]; then
	echo -e "\033[0;34m------------------------------------\033[0m"
	echo -e "\E[44;1;39m        OpenVPN TCP User Login      \E[0m"
	echo -e "\033[0;34m------------------------------------\033[0m"
        echo "Username  |  IP Address  |  Connected Since";
        echo -e "\033[0;34m------------------------------------\033[0m"
        cat /etc/openvpn/server/openvpn-tcp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-tcp.txt
        cat /tmp/vpn-login-tcp.txt
fi
if [ -f "/etc/openvpn/server/openvpn-udp.log" ]; then
	echo -e "\033[0;34m------------------------------------\033[0m"
	echo -e "\E[44;1;39m        OpenVPN UDP User Login      \E[0m"
	echo -e "\033[0;34m------------------------------------\033[0m"
        echo "Username  |  IP Address  |  Connected Since";
        echo -e "\033[0;34m------------------------------------\033[0m"
        cat /etc/openvpn/server/openvpn-udp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-udp.txt
        cat /tmp/vpn-login-udp.txt
fi
echo -e "\033[0;34m------------------------------------\033[0m"
echo "";
rm -f /tmp/login-db-pid.txt
rm -f /tmp/login-db.txt
rm -f /tmp/vpn-login-tcp.txt
rm -f /tmp/vpn-login-udp.txt
read -n 1 -s -r -p "Press any key to back on menu"
menu-ssh
}

del-ssh() {
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m            DELETE USER        \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"

    # Buat array user yang memenuhi kriteria
    mapfile -t users < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

    if [ ${#users[@]} -eq 0 ]; then
        echo "No users available to delete."
        read -n 1 -s -r -p "Press any key to back on menu"
        menu-ssh
        return
    fi

    # Tampilkan daftar user dengan nomor dan expiry
    echo "No  | Username        | Expiry Date"
    echo -e "------------------------------------"

    for i in "${!users[@]}"; do
        AKUN=${users[$i]}
        exp=$(chage -l "$AKUN" | grep "Account expires" | awk -F": " '{print $2}')
        printf "%-3s | %-15s | %s\n" "$((i+1))" "$AKUN" "$exp"
    done

    echo -e "------------------------------------"
    echo "Masukkan nomor user yang ingin dihapus, atau 'x' untuk batal:"
    read -rp "Pilihan: " pilihan

    if [[ "$pilihan" =~ ^[Xx]$ ]]; then
        echo "Batal menghapus user."
        sleep 1
        menu-ssh
        return
    fi

    if ! [[ "$pilihan" =~ ^[0-9]+$ ]]; then
        echo "Input tidak valid."
        sleep 1
        del-ssh
        return
    fi

    if (( pilihan < 1 || pilihan > ${#users[@]} )); then
        echo "Nomor tidak valid."
        sleep 1
        del-ssh
        return
    fi

    # Ambil username dari pilihan
    AKUN="${users[$((pilihan-1))]}"

    if getent passwd "$AKUN" > /dev/null 2>&1; then
        userdel "$AKUN" > /dev/null 2>&1
        echo -e "User $AKUN telah dihapus."
    else
        echo -e "User $AKUN tidak ditemukan."
    fi

    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu"
    menu-ssh
}

hapus-ssh() {
    clear
    hariini=$(date +%d-%m-%Y)

    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m            AUTO DELETE        \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo "Thank you for removing the EXPIRED USERS"
    echo -e "\033[0;34m------------------------------------\033[0m"  

    # Buat list user dan expiry dari shadow (user:expire_days)
    grep -v '^$' /etc/shadow | cut -d: -f1,8 | sed '/:$/d' > /tmp/expirelist.txt

    totalaccounts=$(wc -l < /tmp/expirelist.txt)

    for (( i=1; i<=totalaccounts; i++ )); do
        tuserval=$(sed -n "${i}p" /tmp/expirelist.txt)
        username=$(echo "$tuserval" | cut -d: -f1)
        userexp=$(echo "$tuserval" | cut -d: -f2)
        userexpireinseconds=$(( userexp * 86400 ))
        tglexp=$(date -d @"$userexpireinseconds")
        tgl=$(echo "$tglexp" | awk '{print $3}')
        
        # Format tgl 2 digit
        while [ ${#tgl} -lt 2 ]; do
            tgl="0$tgl"
        done
        
        # Padding username 15 char (spasi)
        while [ ${#username} -lt 15 ]; do
            username="$username "
        done
        
        bulantahun=$(echo "$tglexp" | awk '{print $2, $6}')
        
        # Simpan log
        echo "echo \"Expired- User : $username Expire at : $tgl $bulantahun\"" >> /usr/local/bin/alluser

        todaystime=$(date +%s)

        if [ "$userexpireinseconds" -ge "$todaystime" ]; then
            : # belum expired, skip
        else
            echo "echo \"Expired- Username : $username expired at: $tgl $bulantahun and removed : $hariini\"" >> /usr/local/bin/deleteduser
            echo "Username $username expired at $tgl $bulantahun removed from the VPS $hariini"
            userdel "$username"
        fi
    done

    echo ""
    echo -e "\033[0;34m------------------------------------\033[0m"  

    read -n 1 -s -r -p "Press any key to back on menu"
    menu-ssh
}

member() {
    clear
    echo -e "\033[0;34m---------------------------------------------------\033[0m"
    echo -e "\E[44;1;39m                     LIST MEMBER SSH               \E[0m"
    echo -e "\033[0;34m---------------------------------------------------\033[0m"
    echo -e "USERNAME          EXP DATE          STATUS"
    echo -e "\033[0;34m---------------------------------------------------\033[0m"
    
    while read expired; do
        AKUN="$(echo $expired | cut -d: -f1)"
        ID="$(echo $expired | grep -v nobody | cut -d: -f3)"
        exp="$(chage -l "$AKUN" | grep "Account expires" | awk -F": " '{print $2}')"
        status="$(passwd -S "$AKUN" | awk '{print $2}')"
        
        if [[ $ID -ge 1000 ]]; then
            if [[ "$status" = "L" ]]; then
                printf "%-17s %-17s %-10s\n" "$AKUN" "$exp" "LOCKED"
            else
                printf "%-17s %-17s %-10s\n" "$AKUN" "$exp" "UNLOCKED"
            fi
        fi
    done < /etc/passwd
    
    JUMLAH="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
    echo -e "\033[0;34m---------------------------------------------------\033[0m"
    echo "Account number: $JUMLAH user"
    echo -e "\033[0;34m---------------------------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-ssh
}

renew-ssh() {
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m            RENEW USER          \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"  

    # Buat array user yang ada UID >= 1000 dan bukan nobody
    mapfile -t users < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

    # Papar senarai dengan nombor
    for i in "${!users[@]}"; do
        user=${users[$i]}
        exp=$(chage -l "$user" | grep "Account expires" | awk -F": " '{print $2}')
        status=$(passwd -S "$user" | awk '{print $2}')
        echo -e "$((i+1)). $user\t Exp: $exp\t Status: $status"
    done

    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -n "Select user number to renew (or x to cancel): "
    read pilihan

    if [[ "$pilihan" == "x" || "$pilihan" == "X" ]]; then
        menu-ssh
        return
    fi

    # Pastikan pilihan nombor valid
    if ! [[ "$pilihan" =~ ^[0-9]+$ ]] || (( pilihan < 1 || pilihan > ${#users[@]} )); then
        echo "Invalid selection."
        sleep 1
        renew-ssh
        return
    fi

    User="${users[$((pilihan-1))]}"
    echo "You chose user: $User"

    read -p "Days to extend: " Days
    if ! [[ "$Days" =~ ^[0-9]+$ && "$Days" -gt 0 ]]; then
        echo "Invalid number of days."
        sleep 1
        renew-ssh
        return
    fi

    Today=$(date +%s)
    Days_Detailed=$(( Days * 86400 ))
    Expire_On=$(( Today + Days_Detailed ))
    Expiration=$(date -u --date="1970-01-01 $Expire_On sec GMT" +%Y/%m/%d)
    Expiration_Display=$(date -d "$Expiration" "+%d-%m-%Y")

    passwd -u "$User"
    usermod -e "$Expiration" "$User"

    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m         RENEW SSH USER        \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e ""
    echo -e " Username   : $User"
    echo -e " Days Added : $Days Days"
    echo -e " Expires on : $Expiration_Display"
    echo -e ""
    echo -e "\033[0;34m-------------------------------\033[0m"

    read -n 1 -s -r -p "Press any key to back on menu"
    menu-ssh
}

sshws() {
    clear

    # Dapatkan port Dropbear dan SSH Websocket dari log-install.txt
    portdb=$(grep -w "Dropbear" ~/log-install.txt | cut -d: -f2 | sed 's/ //g' | cut -f2 -d",")
    portsshws=$(grep -w "SSH Websocket" ~/log-install.txt | cut -d: -f2 | awk '{print $1}')

    # Jika service sshws.service belum ada, buat service systemd
    if [ ! -f "/etc/systemd/system/sshws.service" ]; then
        wget -q -O /usr/bin/proxy3.js "${gitlink}/${owner}/resources/main/service/proxy3.js"
        cat <<EOF > /etc/systemd/system/sshws.service
[Unit]
Description=WSenabler By VPN Legasi
Documentation=VPNLegasi

[Service]
Type=simple
ExecStart=/usr/bin/ssh-wsenabler
KillMode=process
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF
    fi

    Green_font_prefix="\033[32m"
    Red_font_prefix="\033[31m"
    Font_color_suffix="\033[0m"

    start() {
        PID=$(pgrep sshws)
        if [[ -n "$PID" ]]; then
            echo "Already ON !"
        else
            wget -q -O /usr/bin/ssh-wsenabler "${gitlink}/${int}/${sc}/main/sshws/sshws-true.sh"
            chmod +x /usr/bin/ssh-wsenabler
            /usr/bin/ssh-wsenabler
            systemctl daemon-reload >/dev/null 2>&1
            systemctl enable sshws.service >/dev/null 2>&1
            systemctl start sshws.service >/dev/null 2>&1
            sed -i "/SSH Websocket/c\   - SSH Websocket           : $portsshws [ON]" /root/log-install.txt
            echo -e "${Green_font_prefix}SSH Websocket Started${Font_color_suffix}"
        fi
        read -n 1 -s -r -p "Press any key to back on menu"
        menu
    }

    stop() {
        PID=$(pgrep sshws)
        if [[ -n "$PID" ]]; then
            systemctl stop sshws.service
            tmux kill-session -t sshws
            sed -i "/SSH Websocket/c\   - SSH Websocket           : $portsshws [OFF]" /root/log-install.txt
            echo -e "${Red_font_prefix}SSH Websocket Stopped${Font_color_suffix}"
        fi
        read -n 1 -s -r -p "Press any key to back on menu"
        menu-ssh
    }

    # Menu utama pilihan enable/disable SSH Websocket
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m           SSH WEBSOCKET       \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo ""
    echo -e " 1. Enable SSH Websocket"
    echo -e " 2. Disable SSH Websocket"
    echo ""
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo ""
    read -rp "Input Number : " -e num

    case "$num" in
        1) start ;;
        2) stop ;;
        *) 
            clear
            read -n 1 -s -r -p "Invalid option. Press any key to back on menu"
            sshws
            ;;
    esac
}

multilogin() {
    CONF_DIR="/etc/openvpn/server"

    while true; do
        # Cek status multi-login untuk semua conf
        if grep -q "^duplicate-cn$" "$CONF_DIR"/*.conf 2>/dev/null; then
            STS="ON"
        else
            STS="OFF"
        fi

        clear
        echo -e "\033[0;34m----------------------------------------\033[0m"
        echo -e "\E[44;1;39m           MULTILOGIN MENU             \E[0m"
        echo -e "\033[0;34m----------------------------------------\033[0m"
        echo -e " Status Multi login : \e[32m${STS}\e[0m"
        echo -e " [\e[36m 01 \e[0m] Enable Multi-login"
        echo -e " [\e[36m 02 \e[0m] Disable Multi-login"
        echo -e "\033[0;34m----------------------------------------\033[0m"
        echo ""

        read -rp "Select option or [x] back to menu: " mlopt
        case "$mlopt" in
            1)
                for CONF in "$CONF_DIR"/*.conf; do
                    if ! grep -q "^duplicate-cn$" "$CONF"; then
                        sed -i '/^persist-key/i duplicate-cn' "$CONF"
                    fi
                done
                echo -e "\e[32mMulti-login enabled!\e[0m"
                systemctl restart openvpn
                read -n1 -s -r -p "Press any key to return to menu"
                menu-ssh
                ;;
            2)
                for CONF in "$CONF_DIR"/*.conf; do
                    if grep -q "^duplicate-cn$" "$CONF"; then
                        sed -i '/^duplicate-cn$/d' "$CONF"
                    fi
                done
                echo -e "\e[31mMulti-login disabled!\e[0m"
                systemctl restart openvpn
                read -n1 -s -r -p "Press any key to return to menu"
                menu-ssh
                ;;
            x|X)
                menu-ssh
                ;;
            *)
                echo -e "\e[31mSila pilih semula\e[0m"
                sleep 1
                ;;
        esac
    done
}

clear
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m               SSH MENU             \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo ""
echo -e " [\e[36m 01 \e[0m] Trial Ssh User"
echo -e " [\e[36m 02 \e[0m] Add Ssh User"
echo -e " [\e[36m 03 \e[0m] All Ssh User"
echo -e " [\e[36m 04 \e[0m] Delete Ssh"
echo -e " [\e[36m 05 \e[0m] Delete User Expired"
echo -e " [\e[36m 06 \e[0m] Extend Ssh"
echo -e " [\e[36m 07 \e[0m] Check User Login"
echo -e " [\e[36m 08 \e[0m] SSh WS Menu"
echo -e " [\e[36m 09 \e[0m] AutoKill Menu"
echo -e " [\e[36m 10 \e[0m] Enable/Disable Multi-login"
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
    trial-ssh
    ;;
2)
    clear
    add-ssh
    ;;
3)
    clear
    member
    ;;
4)
    clear
    del-ssh
    ;;
5)
    clear
    hapus-ssh
    ;;
6)
    clear
    renew-ssh
    ;;
7)
    clear
    cek-ssh
    ;;
8)
    clear
    sshws
    ;;
9)
    clear
    autokill-menu
    ;;
10)
    clear
    multilogin
    ;;
x)  clear
    menu
    ;;
*)
    echo -e ""
    echo "Sila Pilih Semula"
    sleep 1
    menu-ssh
    ;;
esac
