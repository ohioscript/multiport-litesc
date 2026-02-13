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

clear
echo "Checking VPS..."
PERMISSION

check_port() {
echo -e "\033[0;34m------------------------------------------------------------\033[0m"
echo -e "\E[44;1;39m                        INFO SCRIPTS INSTALL                \E[0m"
echo -e "\033[0;34m------------------------------------------------------------\033[0m"
cat /root/log-install.txt
echo -e "\033[0;34m------------------------------------------------------------\033[0m"
read -n 1 -s -r -p "Press any key to back on menu"
menu-vps
}

autoreboot() {
    local cron_file="/etc/cron.d/reboot_otomatis"
    local reboot_script="/usr/local/bin/reboot_otomatis"
    local log_file="/root/log-reboot.txt"

    # Create reboot script if not exist
    if [ ! -e "$reboot_script" ]; then
        cat <<'EOF' > "$reboot_script"
#!/bin/bash
echo "Server successfully rebooted on $(date +"%m-%d-%Y %T")." >> /root/log-reboot.txt
/sbin/shutdown -r now
EOF
        chmod +x "$reboot_script"
    fi

    # Menu display
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo -e "\E[44;1;39m          Menu Auto Reboot System       \E[0m"
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo -e " [\e[36m1\e[0m] Every 1 hr"
    echo -e " [\e[36m2\e[0m] Every 6 hrs"
    echo -e " [\e[36m3\e[0m] Every 12 hrs"
    echo -e " [\e[36m4\e[0m] Every 1 day"
    echo -e " [\e[36m5\e[0m] Every 1 week"
    echo -e " [\e[36m6\e[0m] Every 1 month"
    echo -e " [\e[36m7\e[0m] Turn Off Auto-Reboot"
    echo -e " [\e[36m8\e[0m] View reboot log"
    echo -e " [\e[36m9\e[0m] Remove reboot log"
    echo -e " Press x to back to menu or Ctrl+C to exit"
    echo -e "\033[0;34m----------------------------------------\033[0m"

    read -p "Select menu: " opt
    opt=$(echo "$opt" | sed 's/^0*//')

    case $opt in
        1) echo "10 * * * * root $reboot_script" > "$cron_file"; msg="Auto-Reboot set every 1 hour";;
        2) echo "10 */6 * * * root $reboot_script" > "$cron_file"; msg="Auto-Reboot set every 6 hours";;
        3) echo "10 */12 * * * root $reboot_script" > "$cron_file"; msg="Auto-Reboot set every 12 hours";;
        4) echo "00 5 * * * root $reboot_script" > "$cron_file"; msg="Auto-Reboot set once a day";;
        5) echo "00 5 */7 * * root $reboot_script" > "$cron_file"; msg="Auto-Reboot set once a week";;
        6) echo "00 5 1 * * * root $reboot_script" > "$cron_file"; msg="Auto-Reboot set once a month";;
        7) rm -f "$cron_file"; msg="Auto-Reboot TURNED OFF";;
        8)
            if [ -s "$log_file" ]; then
                echo -e "\033[0;34m--------------------------\033[0m"
                echo -e "\E[44;1;39m       VPS REBOOT LOG      \E[0m"
                echo -e "\033[0;34m--------------------------\033[0m"
                cat "$log_file"
            else
                echo -e "\033[0;34m--------------------------\033[0m"
                echo -e "\E[44;1;39m No reboot activity found \E[0m"
                echo -e "\033[0;34m--------------------------\033[0m"
            fi
            read -n1 -s -r -p "Press any key to return..."
            return
            ;;
        9) > "$log_file"; msg="Auto Reboot Log deleted!";;
        x|X) menu-vps; return;;
        *) echo -e "\033[0;34mOptions not found!\033[0m"; sleep 2; return;;
    esac

    # Show message for actions 1-7,9
    if [[ -n $msg ]]; then
        echo -e "\033[0;34m----------------------------------------\033[0m"
        echo -e "\E[44;1;39m  $msg  \E[0m"
        echo -e "\033[0;34m----------------------------------------\033[0m"
        read -n1 -s -r -p "Press any key to return..."
        menu-vps
    fi
}

add-host() {
    local domain_file="/etc/xray/domain"
    local scdomain_file="/etc/xray/scdomain"
    local root_domain="/root/domain"
    local conf_file="/var/lib/premium-script/ipvps.conf"

    clear
    green='\e[0;32m'; red='\e[0;31m'; NC='\e[0m'

    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m        CHANGE DOMAIN VPS           \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo ""
    read -rp "Add New Domain / Host: " -e domain
    echo ""

    if [[ -z "$domain" ]]; then
        echo -e "[ ${red}ERROR${NC} ] Domain tidak dimasukkan!"
        sleep 2
        menu-vps
        return
    fi

    # Update domain files
    rm -f "$domain_file" "$scdomain_file" "$root_domain" "$conf_file"
    echo "$domain" | tee "$domain_file" "$scdomain_file" "$root_domain" >/dev/null
    echo "IP=$domain" > "$conf_file"

    echo -e "[ ${green}INFO${NC} ] Stop services..."
    systemctl stop nginx xray.service

    # Cek & kill proses port 80
    local pid
    pid=$(lsof -ti:80 | head -n1)
    if [[ -n "$pid" ]]; then
        echo -e "[ ${red}WARNING${NC} ] Port 80 used by PID: $pid, killing..."
        kill -9 "$pid" 2>/dev/null
    fi

    echo -e "[ ${green}INFO${NC} ] Renew SSL Certificate..."
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d "$domain" \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc

    echo -e "[ ${green}INFO${NC} ] Update nginx config..."
    sed -i "s|server_name .*;|server_name ${domain};|g" /etc/nginx/conf.d/xray.conf

    echo -e "[ ${green}INFO${NC} ] Restarting services..."
    systemctl daemon-reload
    systemctl restart nginx xray.service

    clear
    echo -e "[ ${green}SUCCESS${NC} ] Domain changed to: \033[1;36m${domain}\033[0m"
    echo ""
    read -n1 -s -r -p "Press any key to return to menu..."
    menu-vps
}

add_dns() {
    local green='\e[0;32m'; red='\e[0;31m'; NC='\e[0m'
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m         ADD DNS SERVER        \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo "AUTO SCRIPT BY VPN LEGASI"
    echo "TELEGRAM : https://t.me/vpnlegasi / @vpnlegasi"
    echo "1 : TEMPORARY DNS (reboot reset)"
    echo "2 : PERMANENT DNS"
    echo -e "\033[0;34m-------------------------------\033[0m"
    read -p "OPTION NUMBER or x return: " option

    [[ "$option" =~ ^[xX]$ ]] && menu-vps && return

    # Install resolvconf jika tiada
    if ! command -v resolvconf >/dev/null 2>&1; then
        echo "Installing resolvconf..."
        apt-get update -y >/dev/null 2>&1
        apt-get install -y resolvconf >/dev/null 2>&1
    fi

    read -p "KEY IN IP DNS (contoh: 8.8.8.8 1.1.1.1): " dns_list

    case "$option" in
        1) # Temporary DNS
            if systemctl list-unit-files | grep -q resolvconf.service; then
                systemctl enable --now resolvconf.service >/dev/null 2>&1
            fi
            ;;
        2) # Permanent DNS
            if systemctl list-unit-files | grep -q resolvconf.service; then
                systemctl enable --now resolvconf.service >/dev/null 2>&1
                mkdir -p /etc/resolvconf/resolv.conf.d
                : > /etc/resolvconf/resolv.conf.d/head
                for ip in $dns_list; do
                    echo "nameserver $ip" >> /etc/resolvconf/resolv.conf.d/head
                done
                resolvconf --enable-updates >/dev/null 2>&1
                resolvconf -u >/dev/null 2>&1
            fi
            ;;
        *) echo "Invalid option. Returning to menu..."; sleep 2; menu-vps; return;;
    esac

    # Update /etc/resolv.conf fallback
    : > /etc/resolv.conf
    for ip in $dns_list; do
        echo "nameserver $ip" >> /etc/resolv.conf
    done

    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m         CURRENT DNS SERVER    \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    cat /etc/resolv.conf
    echo -e "\033[0;34m-------------------------------\033[0m"
    read -n1 -s -r -p "Press any key to return to menu..."
    menu-vps
}

cek-nf() {
clear
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36";
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)";
DisneyAuth="grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Atoken-exchange&latitude=0&longitude=0&platform=browser&subject_token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJiNDAzMjU0NS0yYmE2LTRiZGMtOGFlOS04ZWI3YTY2NzBjMTIiLCJhdWQiOiJ1cm46YmFtdGVjaDpzZXJ2aWNlOnRva2VuIiwibmJmIjoxNjIyNjM3OTE2LCJpc3MiOiJ1cm46YmFtdGVjaDpzZXJ2aWNlOmRldmljZSIsImV4cCI6MjQ4NjYzNzkxNiwiaWF0IjoxNjIyNjM3OTE2LCJqdGkiOiI0ZDUzMTIxMS0zMDJmLTQyNDctOWQ0ZC1lNDQ3MTFmMzNlZjkifQ.g-QUcXNzMJ8DwC9JqZbbkYUSKkB1p4JGW77OON5IwNUcTGTNRLyVIiR8mO6HFyShovsR38HRQGVa51b15iAmXg&subject_token_type=urn%3Abamtech%3Aparams%3Aoauth%3Atoken-type%3Adevice"
DisneyHeader="authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84"
Font_Black="\033[30m";
Font_Red="\033[31m";
Font_Green="\033[32m";
Font_Yellow="\033[33m";
Font_Blue="\033[34m";
Font_Purple="\033[35m";
Font_SkyBlue="\033[36m";
Font_White="\033[37m";
Font_Suffix="\033[0m";
tele="https://t.me/vpnlegasi"
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m   CHECK DNS REGION BY VPN LEGASI   \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo ""
echo -e "${Font_Blue}SCRIPT EDIT MOD BY VPN LEGASI"
echo -e "Streaming Unlock Content Checker By VPN Legasi" 
echo -e "Contact     : ${tele} / @vpnlegasi"
echo -e "system time : $(date)"
echo -e "Message     : Keputusan ujian adalah untuk rujukan sahaja,"
echo -e "              sila rujuk penggunaan sebenar${Font_Suffix}"
if ! locale -a | grep -qi "en_US.utf8"; then
    apt-get update -y >/dev/null 2>&1
    apt-get install -y locales >/dev/null 2>&1
    locale-gen en_US.UTF-8 >/dev/null 2>&1
    locale-gen en_US.utf8 >/dev/null 2>&1
    dpkg-reconfigure -f noninteractive locales >/dev/null 2>&1
fi

if locale -a | grep -qi "en_US.utf8"; then
    export LANG="en_US.utf8" >/dev/null 2>&1
    export LANGUAGE="en_US:en" >/dev/null 2>&1
    export LC_ALL="en_US.utf8" >/dev/null 2>&1
else
    export LANG="C.UTF-8" >/dev/null 2>&1
    export LANGUAGE="C" >/dev/null 2>&1
    export LC_ALL="C.UTF-8" >/dev/null 2>&1
fi

function InstallJQ() {
    #Install JQ
    if [ -e "/etc/redhat-release" ];then
        echo -e "${Font_Green} is installing dependencies: epel-release${Font_Suffix}"
        yum install epel-release -y -q > /dev/null;
        echo -e "${Font_Green} is installing dependencies: jq${Font_Suffix}";
        yum install jq -y -q > /dev/null;
        elif [[ $(cat /etc/os-release | grep '^ID=') =~ ubuntu ]] || [[ $(cat /etc/os-release | grep '^ID=') =~ debian ]];then
        echo -e "${Font_Green} is updating package list...${Font_Suffix}";
        apt-get update -y > /dev/null;
        echo -e "${Font_Green} is installing dependencies: jq${Font_Suffix}";
        apt-get install jq -y > /dev/null;
        elif [[ $(cat /etc/issue | grep '^ID=') =~ alpine ]];then
        apk update > /dev/null;
        echo -e "${Font_Green} is installing dependencies: jq${Font_Suffix}";
        apk add jq > /dev/null;
    else
        echo -e "${Font_Red}Please manually install jq${Font_Suffix}";
        exit;
    fi
}

function PharseJSON() {
    # Usage: PharseJSON "Original JSON text to parse" "Key value to parse"
    # Example: PharseJSON ""Value":"123456"" "Value" [Return result: 123456]
    echo -n $1 | jq -r .$2;
}

function GameTest_Steam(){
    echo -n -e " Steam Currency : \c";
    local result=`curl --user-agent "${UA_Browser}" -${1} -fsSL --max-time 30 https://store.steampowered.com/app/761830 2>&1 | grep priceCurrency | cut -d '"' -f4`;
    
    if [ ! -n "$result" ]; then
        echo -n -e "\r Steam Currency : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n" 
        echo -n -e ""
    else
        echo -n -e "\r Steam Currency : ${Font_Green}${result}${Font_Suffix}\n" 
        echo -n -e ""
    fi
}


function MediaUnlockTest_Netflix() {
    echo -n -e " Netflix        :\c";
    local result=`curl -${1} --user-agent "${UA_Browser}" -sSL "https://www.netflix.com/" 2>&1`;
    if [ "$result" == "Not Available" ];then
        echo -n -e "\r Netflix Access : ${Font_Red}Unsupport${Font_Suffix}\n"
        echo -n -e "\r Info           : ${Font_Purple}PM @vpnlegasi for rent DNS Unlock Netflix SG + MY${Font_Suffix}\n"
        return;
    fi
    
    if [[ "$result" == "curl"* ]];then
        echo -n -e "\r Netflix Access : ${Font_Red}No : Failed (Network Connection) ${Font_Suffix}\n"
        echo -n -e "\r Info           : ${Font_Purple}PM @vpnlegasi for rent DNS Unlock Netflix SG + MY${Font_Suffix}\n"
        return;
    fi
    
    local result=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/80018499" 2>&1`;
    if [[ "$result" == *"page-404"* ]] || [[ "$result" == *"NSEZ-403"* ]];then
        echo -n -e "\r Netflix Access : ${Font_Red}No${Font_Suffix}\n"
        echo -n -e "\r Info           : ${Font_Purple}PM @vpnlegasi for rent DNS Unlock Netflix SG + MY${Font_Suffix}\n"
        return;
    fi
    
    local result1=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70143836" 2>&1`;
    local result2=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/80027042" 2>&1`;
    local result3=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70140425" 2>&1`;
    local result4=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70283261" 2>&1`;
    local result5=`curl -${1} --user-agent "${UA_Browser}"-sL "https://www.netflix.com/title/70143860" 2>&1`;
    local result6=`curl -${1} --user-agent "${UA_Browser}" -sL "https://www.netflix.com/title/70202589" 2>&1`;

    if [[ "$result1" == *"page-404"* ]] && [[ "$result2" == *"page-404"* ]] && [[ "$result3" == *"page-404"* ]] && [[ "$result4" == *"page-404"* ]] && [[ "$result5" == *"page-404"* ]] && [[ "$result6" == *"page-404"* ]];then
        echo -n -e "\r Netflix Access : ${Font_Green}Yes${Font_Suffix}\n"
        echo -n -e "\r Netflix Type   : ${Font_Yellow}Only Homemade : Limited Movie :) ${Font_Suffix}\n"
        echo -n -e "\r Info           : ${Font_Purple}PM @vpnlegasi for rent DNS Unlock Netflix SG + MY${Font_Suffix}\n"
        return;
    fi
    
    local region=`tr [:lower:] [:upper:] <<< $(curl -${1} --user-agent "${UA_Browser}" -fs --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1)` ;
    
    if [[ ! -n "$region" ]];then
        region="US";
    fi
        echo -n -e "\r Netflix Access : ${Font_Green}Yes${Font_Suffix}\n"
        echo -n -e "\r Netflix Type   : ${Font_SkyBlue}Full (Region: ${region}) : Enjoy Your Movie :) ${Font_Suffix}\n" 
    return;
}    


function MediaUnlockTest_HotStar() {
    echo -n -e " Hotstar Region :\c";
    local result=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -${1} ${ssll} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.hotstar.com/o/v1/page/1557?offset=0&size=20&tao=0&tas=20")
    if [ "$result" = "000" ]; then
        echo -n -e "\r HotStar        : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "401" ]; then
        local region=$(curl $useNIC $xForward --user-agent "${UA_Browser}" -${1} ${ssll} -sI "https://www.hotstar.com" | grep 'geo=' | sed 's/.*geo=//' | cut -f1 -d",")
        local site_region=$(curl $useNIC $xForward -${1} ${ssll} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.hotstar.com" | sed 's@.*com/@@' | tr [:lower:] [:upper:])
        if [ -n "$region" ] && [ "$region" = "$site_region" ]; then
            echo -n -e "\r HotStar Region : ${Font_SkyBlue}Full (Region: ${region}) : Enjoy Your Movie :) ${Font_Suffix}\n"
            return
        else
            eecho -n -e "\r Hotstar Region : ${Font_Red}No${Font_Suffix}\n"
            return
        fi
    elif [ "$result" = "475" ]; then
        echo -n -e "\r Hotstar Region : ${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Hotstar Region : ${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_iQiyi(){
    echo -n -e " iQiyi Region   :\c";
    local tmpresult=$(curl -${1} -s -I "https://www.iq.com/" 2>&1);
    if [[ "$tmpresult" == "curl"* ]];then
        	echo -n -e "\r iQiyi Region   : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        	return;
    fi
    
    local result=$(echo "${tmpresult}" | grep 'mod=' | awk '{print $2}' | cut -f2 -d'=' | cut -f1 -d';');
    if [ -n "$result" ]; then
		if [[ "$result" == "ntw" ]]; then
			echo -n -e "\r iQiyi Region   : ${Font_Green}Yes(Region: TW)${Font_Suffix}\n"
			return;
		else
			region=$(echo ${result} | tr 'a-z' 'A-Z') 
			echo -n -e "\r iQiyi Region   : ${Font_SkyBlue}Full (Region: ${region}) : Enjoy Your Movie :) ${Font_Suffix}\n"
			return;
		fi	
    else
		echo -n -e "\r iQiyi Region   : ${Font_Red}Failed${Font_Suffix}\n"
		return;
	fi	
}

function MediaUnlockTest_Viu_com() {
    echo -n -e " Viu.com        :\c";
    local tmpresult=$(curl -${1} -s -o /dev/null -L --max-time 30 -w '%{url_effective}\n' "https://www.viu.com/" 2>&1);
	if [[ "${tmpresult}" == "curl"* ]];then
        echo -n -e "\r Viu.com        : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return;
    fi
	
	local result=$(echo ${tmpresult} | cut -f5 -d"/")
	if [ -n "${result}" ]; then
		if [[ "${result}" == "no-service" ]]; then
			echo -n -e "\r Viu.com Region : ${Font_Red}No${Font_Suffix}\n"
			return;
		else
			region=$(echo ${result} | tr 'a-z' 'A-Z')
			echo -n -e "\r Viu.com Region : ${Font_SkyBlue}Full (Region: ${region}) : Enjoy Your Movie :) ${Font_Suffix}\n"
			return;
		fi
    else
		echo -n -e "\r Viu.com Region : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
		return;
	fi
}


function MediaUnlockTest_YouTube_Region() {
    echo -n -e " YouTube Region : ->\c";
    local result=`curl --user-agent "${UA_Browser}" -${1} -sSL "https://www.youtube.com/" 2>&1`;
    
    if [[ "$result" == "curl"* ]];then
        echo -n -e "\r YouTube Region : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        echo -n -e ""
        return;
    fi
    
    local result=`curl --user-agent "${UA_Browser}" -${1} -sL "https://www.youtube.com/red" | sed 's/,/\n/g' | grep "countryCode" | cut -d '"' -f4`;
    if [ -n "$result" ]; then
        echo -n -e "\r YouTube Region : ${Font_Green}${result}${Font_Suffix}\n" 
        return;
    fi
    
    echo -n -e "\r YouTube Region : ${Font_Red}No${Font_Suffix}\n"
    return;
}

function MediaUnlockTest_DisneyPlus() {
    echo -n -e " DisneyPlus     : \c";
    local result=`curl -${1} --user-agent "${UA_Browser}" -sSL "https://global.edge.bamgrid.com/token" 2>&1`;
    
    if [[ "$result" == "curl"* ]];then
        echo -n -e "\r DisneyPlus     : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n" 
        return;
    fi
    
    local previewcheck=`curl -sSL -o /dev/null -L --max-time 30 -w '%{url_effective}\n' "https://disneyplus.com" 2>&1`;
    if [[ "${previewcheck}" == "curl"* ]];then
        echo -n -e "\r DisneyPlus     : ${Font_Red}Failed (Network Connection)${Font_Suffix}\n" 
        return;
    fi
    
    if [[ "${previewcheck}" == *"preview"* ]];then
        echo -n -e "\r DisneyPlus     : ${Font_Red}No${Font_Suffix}\n" 
        return;
    fi
    
    local result=`curl -${1} --user-agent "${UA_Browser}" -fs --write-out '%{redirect_url}\n' --output /dev/null "https://www.disneyplus.com" 2>&1`;
    if [[ "${website}" == "https://disneyplus.disney.co.jp/" ]];then
        echo -n -e "\r DisneyPlus     : ${Font_Green}Yes(Region: JP)${Font_Suffix}\n"
        return;
    fi
    
    local result=`curl -${1} -sSL --user-agent "$UA_Browser" -H "Content-Type: application/x-www-form-urlencoded" -H "${DisneyHeader}" -d "${DisneyAuth}" -X POST  "https://global.edge.bamgrid.com/token" 2>&1`;
    PharseJSON "${result}" "access_token" 2>&1 > /dev/null;
    if [[ "$?" -eq 0 ]]; then
        local region=$(curl -${1} -sSL https://www.disneyplus.com | grep 'region: ' | awk '{print $2}')
        if [ -n "$region" ];then
            echo -n -e "\r DisneyPlus     : ${Font_Green}Yes(Region: $region)${Font_Suffix}\n"
            return;
        fi
        echo -n -e "\r DisneyPlus     : ${Font_Green}Yes${Font_Suffix}\n" 
        return;
    fi
        echo -n -e "\r DisneyPlus     : ${Font_Red}No${Font_Suffix}\n" 
}

function ISP(){
    local result=`curl -sSL -${1} "https://api.ip.sb/geoip" 2>&1`;
    if [[ "$result" == "curl"* ]];then
        return
    fi
    local ip=$(wget -qO- ipinfo.io/ip);
    local isp=$(curl -s ipinfo.io/org | cut -d " " -f 2-10 )
    if [ $? -eq 0 ];then
        echo " ** Your IP     : ${ip}"
        echo " ** Your ISP    : ${isp}"
    fi
}

function MediaUnlockTest() {
    ISP ${1};
    MediaUnlockTest_Netflix ${1};
    MediaUnlockTest_YouTube_Region ${1};
    MediaUnlockTest_DisneyPlus ${1};
    MediaUnlockTest_HotStar ${1};
    MediaUnlockTest_Viu_com ${1};
    MediaUnlockTest_iQiyi ${1};
    GameTest_Steam ${1};
}

curl -V > /dev/null 2>&1;
if [ $? -ne 0 ];then
    echo -e "${Font_Red}Please install curl${Font_Suffix}";
    exit;
fi

jq -V > /dev/null 2>&1;
if [ $? -ne 0 ];then
    InstallJQ;
fi
echo " ** Testing IPv4 unlocking"
check4=`ping 1.1.1.1 -c 1 2>&1`;
if [[ "$check4" != *"unreachable"* ]] && [[ "$check4" != *"Unreachable"* ]];then
    MediaUnlockTest 4;
else
    echo -e "${Font_SkyBlue}The current host does not support IPv4, skip...${Font_Suffix}"
fi
    echo -n -e " "
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m   CHECK DNS REGION BY VPN LEGASI   \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-vps
}

backupmenu-bot() {
    clear
    sts="Off"
    [[ $(grep -c -E "^# BOTBEGIN_Backupp" /etc/crontab) = "1" ]] && sts="On"

    green='\e[0;32m'; NC='\e[0m'

    start() {
        token=$(awk '{print $2}' /etc/token_bott 2>/dev/null)
        [[ -z $token ]] && { echo -e "[ ${green}INFO${NC} ] Please Setbot FIRST!!!"; sleep 3; return; }

        sed -i "/^# BOTBEGIN_Backupp/,/^# BOTEND_Backupp/d" /etc/crontab
        sed -i "/Auto Backup Status/c\   - Auto Backup Status      : [ON]" /root/log-install.txt
        cat << EOF >> /etc/crontab
# BOTBEGIN_Backupp
5 0 * * * root botautobckp
# BOTEND_Backupp
EOF
        service cron restart
        clear
        echo -e "\033[0;34m-------------------------------\033[0m"
        echo -e "\E[44;1;39m Autobackup Has Been Started   \E[0m"
        echo -e "Data will be backed up automatically at 00:05"
        echo -e "\033[0;34m-------------------------------\033[0m"
        read -n1 -s -r -p "Press any key to back on menu"
    }

    stop() {
        sed -i "/^# BOTBEGIN_Backupp/,/^# BOTEND_Backupp/d" /etc/crontab
        sed -i "/Auto Backup Status/c\   - Auto Backup Status      : [OFF]" /root/log-install.txt
        service cron restart
        clear
        echo -e "\033[0;34m-------------------------------\033[0m"
        echo -e "\E[44;1;39m Autobackup Has Been Stopped   \E[0m"
        echo -e "\033[0;34m-------------------------------\033[0m"
        read -n1 -s -r -p "Press any key to back on menu"
    }

    restore() {
        read -rp "Link : " link
        read -rp "Password (default 123): " InputPass
        InputPass=${InputPass:-123}

        mkdir -p /root/backup
        echo -e "[ ${green}INFO${NC} ] Downloading backup..."
        wget -q -O /root/backup/backup.zip "$link"

        echo -e "[ ${green}INFO${NC} ] Extracting backup..."
        unzip -P "$InputPass" /root/backup/backup.zip -d /root/backup >/dev/null 2>&1

        echo -e "[ ${green}INFO${NC} ] Restoring data..."
        [[ -f /root/backup/passwd ]] && cp /root/backup/passwd /etc/
        [[ -f /root/backup/group ]] && cp /root/backup/group /etc/
        [[ -f /root/backup/shadow ]] && cp /root/backup/shadow /etc/
        [[ -f /root/backup/gshadow ]] && cp /root/backup/gshadow /etc/
        [[ -d /root/backup/xray ]] && cp -r /root/backup/xray /usr/local/etc/

        rm -rf /root/backup

        echo -e "[ ${green}INFO${NC} ] Restarting services..."
        systemctl restart cron nginx squid xray
        sleep 1
        echo -e "[ ${green}INFO${NC} ] Restore completed."
        read -n1 -s -r -p "Press any key to back on menu"
    }

    while true; do
        clear
        echo -e "\033[0;34m-------------------------------\033[0m"
        echo -e "\E[44;1;39m   Telegram Backup Data Menu   \E[0m"
        echo -e "\033[0;34m-------------------------------\033[0m"
        echo -e " Status AutoBackup : $sts"
        echo -e " 1. Setup Telegram Bot"
        echo -e " 2. Start Autobackup Telegram Bot"
        echo -e " 3. Stop Autobackup Telegram Bot"
        echo -e " 4. Backup VPS (Telegram Bot)"
        echo -e " 5. Restore Backup VPS"
        echo -e " x. Return to Main Menu"
        echo -e "\033[0;34m-------------------------------\033[0m"
        read -rp "Enter option: " num

        case "$num" in
            1) setbot ;;
            2) start ;;
            3) stop ;;
            4) backup_bot ;;
            5) restore ;;
            x|X) menu-vps ;;
            *) echo "Invalid input!"; sleep 2 ;;
        esac
    done
}

update_sc() {
    versi=$(curl -sS "${gitlink}/${owner}/${sc}/main/versi/main" | awk '{print $3}')
    cversion=$(awk '{print $3}' /opt/.ver 2>/dev/null)
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m        UPDATE SCRIPT VPS      \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"

    if [[ "$versi" == "$cversion" ]]; then
        echo "Script already up to date (version $versi)."
        read -p "Do you still want to update? (y/n): " ans
    else
        echo "Script outdated (current: $cversion, latest: $versi)."
        read -p "Update now? (y/n): " ans
    fi

    [[ ! $ans =~ ^[Yy]$ ]] && { echo -e "\n\033[0;33mUpdate canceled.\033[0m"; read -n 1 -s -r -p "Press any key..."; menu-vps; return; }

    echo "Updating script..."
    files=(
        menu
        menu-ssh
        menu-vps
        menu-xray
        xp
        botautobckp
        clearlog
        running
    )

    for f in "${files[@]}"; do
        wget -q -O "/usr/bin/$f" "${gitlink}/${int}/${sc}/main/$f.sh" && chmod +x "/usr/bin/$f"
    done

    # Update version file
    rm -f /opt/.ver
    curl -sS "${gitlink}/${owner}/${sc}/main/versi/main" > /opt/.ver
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\n\033[0;32mUpdate completed successfully.\033[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-vps
}

swap_kvm() {
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m       SWAP VPS KVM MEMORY     \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"

    # Buat 2 swapfile 512MB
    for i in 1 2; do
        swapfile="/swapfile$i"
        dd if=/dev/zero of="$swapfile" bs=1M count=512 status=none
        mkswap "$swapfile"
        chmod 600 "$swapfile"
        chown root:root "$swapfile"
        swapon "$swapfile"

        # Auto mount on boot
        grep -q "$swapfile" /etc/fstab || echo "$swapfile swap swap defaults 0 0" >> /etc/fstab
        grep -q "$swapfile" /etc/rc.local || sed -i "\$i swapon $swapfile" /etc/rc.local
    done

    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39mSWAP VPS KVM MEMORY SUCCESSFULLY\E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-vps
}

clear_log() {
    clear
    GREEN='\e[0;32m'
    RED='\e[0;31m'
    NC='\e[0m'

    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m           CLEAR LOG VPS       \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"

    # Aktifkan nullglob supaya glob yang tak jumpa fail tak error
    shopt -s nullglob

    logs=(
        /var/log/*.log /var/log/*.err /var/log/mail.* 
        /var/log/syslog /var/log/btmp /var/log/messages /var/log/debug /var/log/auth.log
        /var/log/alternatives.log /var/log/cloud-init.log /var/log/cloud-init-output.log
        /var/log/daemon.log /var/log/dpkg.log /var/log/droplet-agent.update.log
        /var/log/fail2ban.log /var/log/kern.log /var/log/user.log
        /var/log/xray/*.log /var/log/nginx/*.log
    )

    for log in "${logs[@]}"; do
        if [[ -f "$log" ]]; then
            : > "$log"
            echo -e "${GREEN}Cleared${NC}: $log"
        fi
    done

    # Buang semua log rotate files
    rm -f /var/log/*.log.* /var/log/*.err.* /var/log/xray/*.log.* /var/log/nginx/*.log.*

    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m    CLEAR LOG VPS SUCCESSFULLY  \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"

    read -n 1 -s -r -p "Press any key to back on menu"
    menu-vps
}

running_1() {
    export IP=$(curl -s https://ipinfo.io/ip/)
    clear

    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m     STATUS SERVICE INFORMATION     \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "Server Uptime        : $(uptime -p | cut -d ' ' -f2-)"
    echo -e "Current Time         : $(date '+%d-%m-%Y %X')"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "    $PURPLE Service        :  Status$NC"
    echo -e "\033[0;34m------------------------------------\033[0m"

    # Helper function check service
    check_svc() {
        local svc=$1
        local type=$2   # systemctl / init.d
        local status

        if [[ "$type" == "systemctl" ]]; then
            status=$(systemctl is-active "$svc" 2>/dev/null)
            [[ $status == "active" ]] && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Error${NC}"
        else
            /etc/init.d/$svc status >/dev/null 2>&1 && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Error${NC}"
        fi
    }

    declare -A services=(
        [OpenSSH]="ssh"
        [Dropbear]="dropbear"
        [Stunnel5]="stunnel4"
        [Squid]="squid"
        [NGINX]="nginx"
        [SSH_NonTLS]="ws-stunnel"
        [SSH_TLS]="ws-stunnel"
        [Xray]="xray"
    )

    for svc_name in "${!services[@]}"; do
        svc=${services[$svc_name]}
        # xray, nginx, ws-stunnel pakai systemctl
        if [[ "$svc" =~ ^(xray|nginx|ws-stunnel)$ ]]; then
            status=$(check_svc "$svc" "systemctl")
        else
            status=$(check_svc "$svc" "systemctl")
        fi
        printf "%-20s : %s\n" "$svc_name" "$status"
    done

    echo -e "\033[0;34m------------------------------------\033[0m"
    read -n1 -s -r -p "Press any key to back on menu"
    menu-vps
}


check_ram() {
    clear
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo -e "\E[44;1;39m           CHECK VPS RAM SERVICE        \E[0m"
    echo -e "\033[0;34m----------------------------------------\033[0m"
    ram
    echo -e "\033[0;34m----------------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    menu-vps 
}

cert_xray() {
    clear
    green='\e[0;32m'; red='\e[0;31m'; NC='\e[0m'

    domain=$(< /root/domain)

    if [[ -z "$domain" ]]; then
        echo -e "[ ${red}ERROR${NC} ] Domain tidak ditemui di /root/domain"
        read -n1 -s -r -p "Tekan sebarang key untuk kembali..."
        menu-vps
        return
    fi

    echo -e "[ ${green}INFO${NC} ] Renew SSL untuk domain: $domain"

    # Stop nginx & check port 80
    systemctl stop nginx 2>/dev/null
    pid=$(lsof -ti:80 | head -n1)
    svc=""
    if [[ -n "$pid" ]]; then
        svc=$(ps -p "$pid" -o comm=)
        echo -e "[ ${red}WARNING${NC} ] Port 80 digunakan oleh $svc (PID $pid), hentikan sementara..."
        systemctl stop "$svc" 2>/dev/null
    fi

    # Issue & install cert
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    if ! ~/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256; then
        echo -e "[ ${red}ERROR${NC} ] Gagal renew cert untuk $domain"
        [[ -n "$svc" ]] && systemctl start "$svc"
        systemctl start nginx
        read -n1 -s -r -p "Tekan sebarang key untuk kembali..."
        menu-vps
        return
    fi

    ~/.acme.sh/acme.sh --installcert -d "$domain" \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc

    # Restart services
    [[ -n "$svc" ]] && systemctl restart "$svc"
    systemctl restart nginx xray 2>/dev/null

    clear
    echo -e "[ ${green}SUCCESS${NC} ] SSL siap untuk domain: \033[1;36m$domain\033[0m"
    read -n1 -s -r -p "Tekan sebarang key untuk kembali ke menu..."
    menu-vps
}

wgf() {
    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m            Update Proxy Key        \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"

    declare -A keys
    for i in 1 2; do
        tmpdir="/tmp/key$i"
        mkdir -p "$tmpdir"
        /usr/local/bin/genkey register <<< "yes" >/dev/null 2>&1
        /usr/local/bin/genkey generate <<< "yes" >/dev/null 2>&1
        keys[$i]=$(grep 'PrivateKey' "$tmpdir/wgcf-profile.conf" | awk '{print $3}')
    done

    # Safety check
    if [[ -z "${keys[1]}" || -z "${keys[2]}" ]]; then
        echo -e "\033[0;31mError generating keys! Aborting...\033[0m"
        rm -rf /tmp/key1 /tmp/key2
        read -n1 -s -r -p "Press any key to return..."
        menu-vps
        return
    fi

    # Update JSON
    sed -i "/\"tag\": \"legasi-1\"/{n;s/\"secretKey\": \".*\"/\"secretKey\": \"${keys[1]}\"/}" /usr/local/etc/xray/outbounds.json
    sed -i "/\"tag\": \"legasi-2\"/{n;s/\"secretKey\": \".*\"/\"secretKey\": \"${keys[2]}\"/}" /usr/local/etc/xray/outbounds.json

    # Cleanup
    rm -rf /tmp/key1 /tmp/key2

    # Show keys
    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m               Key Updated          \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "KEY1: ${keys[1]}"
    echo -e "KEY2: ${keys[2]}"
    echo -e "\033[0;34m------------------------------------\033[0m"
    read -n1 -s -r -p "Press any key to return to menu..."
    menu-vps
}

restart_all() {
    clear
    echo -e "\033[0;34m-------------------------------\033[0m"
    echo -e "\E[44;1;39m     RESTART ALL SERVICE VPS   \E[0m"
    echo -e "\033[0;34m-------------------------------\033[0m"

    # Semua service untuk restart
    services=(ssh dropbear stunnel4 openvpn fail2ban cron nginx squid xray ws-stunnel)

    for svc in "${services[@]}"; do
        printf "Restarting %-15s ... " "$svc"

        # Systemd vs init.d
        if systemctl list-unit-files | grep -qw "$svc"; then
            systemctl restart "$svc" >/dev/null 2>&1
            systemctl is-active --quiet "$svc" && echo -e "${GREEN}Restarted${NC}" || echo -e "${RED}Error${NC}"
        else
            /etc/init.d/$svc restart >/dev/null 2>&1
            /etc/init.d/$svc status >/dev/null 2>&1 && echo -e "${GREEN}Restarted${NC}" || echo -e "${RED}Error${NC}"
        fi
    done

    # Restart badvpn
    printf "Starting %-15s ... " "badvpn"
    screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000
    screen -list | grep -q "badvpn" && echo -e "${GREEN}Restarted${NC}" || echo -e "${RED}Error${NC}"

    sleep 2

    # Status helper
    check_status() {
        local svc=$1
        if systemctl list-unit-files | grep -qw "$svc"; then
            systemctl is-active --quiet "$svc" && echo "${GREEN}Running${NC}" || echo "${RED}Error${NC}"
        else
            /etc/init.d/$svc status >/dev/null 2>&1 && echo "${GREEN}Running${NC}" || echo "${RED}Error${NC}"
        fi
    }

    # Tampilkan status
    clear
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo -e "\E[44;1;39m       SYSTEM       :       STATUS      \E[0m"
    echo -e "\033[0;34m----------------------------------------\033[0m"

    echo -e "OpenSSH             : $(check_status ssh)"
    echo -e "Dropbear            : $(check_status dropbear)"
    echo -e "Stunnel5            : $(check_status stunnel4)"
    echo -e "Squid               : $(check_status squid)"
    echo -e "NGINX               : $(check_status nginx)"
    echo -e "SSH NonTLS/WS       : $(check_status ws-stunnel)"
    echo -e "Xray                : $(check_status xray)"
    
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo -e "\E[44;1;39m       SUCCESSFULLY RESTART VPS        \E[0m"
    echo -e "\033[0;34m----------------------------------------\033[0m"
    read -n1 -s -r -p "Press any key to back on menu"
    menu-vps
}

running_1() {
    export IP=$(curl -s https://ipinfo.io/ip/)
    clear

    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m     STATUS SERVICE INFORMATION     \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "Server Uptime        : $(uptime -p | cut -d ' ' -f2-)"
    echo -e "Current Time         : $(date '+%d-%m-%Y %X')"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "    $PURPLE Service        :  Status$NC"
    echo -e "\033[0;34m------------------------------------\033[0m"

    # Helper function check service
    check_svc() {
        local svc=$1
        local type=$2   # systemctl / init.d
        local status

        if [[ "$type" == "systemctl" ]]; then
            status=$(systemctl is-active "$svc" 2>/dev/null)
            [[ $status == "active" ]] && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Error${NC}"
        else
            /etc/init.d/$svc status >/dev/null 2>&1 && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Error${NC}"
        fi
    }

    declare -A services=(
        [OpenSSH]="ssh"
        [Dropbear]="dropbear"
        [Stunnel5]="stunnel4"
        [Squid]="squid"
        [NGINX]="nginx"
        [SSH_NonTLS]="ws-stunnel"
        [SSH_TLS]="ws-stunnel"
        [Xray]="xray"
    )

    for svc_name in "${!services[@]}"; do
        svc=${services[$svc_name]}
        # xray, nginx, ws-stunnel pakai systemctl
        if [[ "$svc" =~ ^(xray|nginx|ws-stunnel)$ ]]; then
            status=$(check_svc "$svc" "systemctl")
        else
            status=$(check_svc "$svc" "systemctl")
        fi
        printf "%-20s : %s\n" "$svc_name" "$status"
    done

    echo -e "\033[0;34m------------------------------------\033[0m"
    read -n1 -s -r -p "Press any key to back on menu"
    menu-vps
}

sock_menu() {
SOCK_FILE="/usr/local/etc/xray/sock_user.conf"
[[ ! -f "$SOCK_FILE" ]] && touch "$SOCK_FILE"
PORT=1080
hariini=$(date +%F)

# ===== Helper: Validate unique IP =====
get_unique_ip() {
    read -p "Enter IP (or press Enter to cancel): " IP
    [[ -z "$IP" ]] && echo "Dibatalkan!" && return 1
    if grep -q "^### $IP" "$SOCK_FILE"; then
        echo "IP $IP sudah wujud!"
        return 1
    fi
    return 0
}

# ===== Helper: Create SOCK user =====
create_sock_user() {
    local IP=$1
    local USER=$2
    local DAYS=$3
    exp=$(date -d "+$DAYS days" +%F)
    echo "### $IP $USER $exp" >> "$SOCK_FILE"

    # Insert ACCEPT rule on top
    iptables -I INPUT -p tcp -s "$IP" --dport $PORT -j ACCEPT
    iptables -I INPUT -p udp -s "$IP" --dport $PORT -j ACCEPT
    iptables-save >/etc/iptables.rules.v4
    netfilter-persistent save
    netfilter-persistent reload

    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m             Sock Account           \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "Sock IP       : $IP"
    echo -e "PORT          : $PORT"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "Created On    : $hariini"
    echo -e "Expired On    : $exp"
    echo -e "\033[0;34m------------------------------------\033[0m"
    read -n 1 -s -r -p "Press any key to back on menu"
    sock_menu
}

# ===== Trial SOCK user =====
trial_sock_user() {
    if ! get_unique_ip; then sock_menu; return; fi
    USER="SOCKTRIAL$(tr -dc A-Z0-9 </dev/urandom | head -c4)"
    create_sock_user "$IP" "$USER" 1
}

# ===== Add SOCK user =====
add_sock_user() {
    read -p "Enter username: " USER
    if ! get_unique_ip; then sock_menu; return; fi
    read -p "Enter expiry days: " DAYS
    create_sock_user "$IP" "$USER" "$DAYS"
}

# ===== Renew SOCK user =====
renew_sock_user() {
    tmpfile="/tmp/sock_tmp.txt"
    grep -E "^### " "$SOCK_FILE" | awk '{print $2" "$3" "$4}' | sort -u > "$tmpfile"
    NUMBER_OF_CLIENTS=$(wc -l < "$tmpfile" | tr -d ' ')

    if [[ $NUMBER_OF_CLIENTS -eq 0 ]]; then
        echo "Tiada SOCKS user untuk renew!"
        rm -f "$tmpfile"
        read -n 1 -s -r -p "Press any key to back on menu"
        sock_menu
        return
    fi

    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m         Renew Sock Account        \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    nl -s ') ' "$tmpfile"
    echo -e "\033[0;34m------------------------------------\033[0m"

    read -rp "Select one client [1-${NUMBER_OF_CLIENTS}, or 'x' to cancel]: " CLIENT_NUMBER
    [[ "$CLIENT_NUMBER" =~ ^[xXqQ]$ || -z "$CLIENT_NUMBER" ]] && { echo "Dibatalkan!"; rm -f "$tmpfile"; sock_menu; return; }

    if ! [[ "$CLIENT_NUMBER" =~ ^[0-9]+$ ]] || (( CLIENT_NUMBER < 1 || CLIENT_NUMBER > NUMBER_OF_CLIENTS )); then
        echo "Pilihan tidak sah!"
        rm -f "$tmpfile"
        sock_menu
        return
    fi

    IP=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $1}' "$tmpfile")
    USER=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $2}' "$tmpfile")
    EXP_OLD=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $3}' "$tmpfile")

    read -rp "Extend by (days): " DAYS

    now=$(date +%F)
    d1=$(date -d "$EXP_OLD" +%s)
    d2=$(date -d "$now" +%s)
    remaining=$(( (d1 - d2) / 86400 ))
    new_exp=$(( remaining + DAYS ))
    EXP_NEW=$(date -d "+$new_exp days" +%F)

    sed -i "\|### $IP|c\### $IP $USER $EXP_NEW" "$SOCK_FILE"

    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m         Renew Sock Account        \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo " Account Was Successfully Renewed"
    echo " Sock IP     : $IP"
    echo " Username    : $USER"
    echo " Expired On  : $EXP_NEW"
    echo -e "\033[0;34m------------------------------------\033[0m"

    rm -f "$tmpfile"
    read -n 1 -s -r -p "Press any key to back on menu"
    sock_menu
}

# ===== Delete SOCK user =====
delete_sock_user() {
    tmpfile="/tmp/sock_tmp.txt"
    grep -E "^### " "$SOCK_FILE" | awk '{print $2" "$3" "$4}' | sort -u > "$tmpfile"
    NUMBER_OF_CLIENTS=$(wc -l < "$tmpfile" | tr -d ' ')

    if [[ $NUMBER_OF_CLIENTS -eq 0 ]]; then
        echo "Tiada SOCKS user untuk delete!"
        rm -f "$tmpfile"
        read -n 1 -s -r -p "Press any key to back on menu"
        sock_menu
        return
    fi

    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\E[44;1;39m         Delete Sock Account       \E[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    nl -s ') ' "$tmpfile"
    echo -e "\033[0;34m------------------------------------\033[0m"

    read -rp "Select one client [1-${NUMBER_OF_CLIENTS}, or 'x' to cancel]: " CLIENT_NUMBER
    [[ "$CLIENT_NUMBER" =~ ^[xXqQ]$ || -z "$CLIENT_NUMBER" ]] && { echo "Dibatalkan!"; rm -f "$tmpfile"; sock_menu; return; }

    if ! [[ "$CLIENT_NUMBER" =~ ^[0-9]+$ ]] || (( CLIENT_NUMBER < 1 || CLIENT_NUMBER > NUMBER_OF_CLIENTS )); then
        echo "Pilihan tidak sah!"
        rm -f "$tmpfile"
        sock_menu
        return
    fi

    IP=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $1}' "$tmpfile")
    USER=$(awk -v n="$CLIENT_NUMBER" 'NR==n {print $2}' "$tmpfile")

    sed -i "\|### $IP|d" "$SOCK_FILE"
    iptables -D INPUT -p tcp -s "$IP" --dport $PORT -j ACCEPT
    iptables -D INPUT -p udp -s "$IP" --dport $PORT -j ACCEPT
    iptables-save >/etc/iptables.rules.v4
    netfilter-persistent save
    netfilter-persistent reload

    echo "Account SOCK $USER ($IP) deleted successfully!"
    rm -f "$tmpfile"
    read -n 1 -s -r -p "Press any key to back on menu"
    sock_menu
}

# ===== Main menu =====
while true; do
clear
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m               VPS MENU             \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo ""
echo -e " [\e[36m 01 \e[0m] Trial Sock Access"
echo -e " [\e[36m 02 \e[0m] Add Sock Access"
echo -e " [\e[36m 03 \e[0m] Delete Sock Access"
echo -e " [\e[36m 04 \e[0m] Renew Sock Access"
echo -e " [\e[36m x  \e[0m] Back to Main Menu"
echo ""
echo -e "\033[0;34m------------------------------------\033[0m"
read -p " Select menu : " opt
opt=$(echo "$opt" | sed 's/^0*//')

case $opt in
1) trial_sock_user ;;
2) add_sock_user ;;
3) delete_sock_user ;;
4) renew_sock_user ;;
x|X) menu-vps; break ;;
*) echo "Sila Pilih Semula"; sleep 1 ;;
esac
done
}

clear
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m               VPS MENU             \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo ""
echo -e " [\e[36m 01 \e[0m] Change Domain VPS"
echo -e " [\e[36m 02 \e[0m] Renew Domain Xray Cert"
echo -e " [\e[36m 03 \e[0m] Backup/Restore VPS Use Bot Telegram"
echo -e " [\e[36m 04 \e[0m] Add DNS Server"
echo -e " [\e[36m 05 \e[0m] Check Netflix Region"
echo -e " [\e[36m 06 \e[0m] Update Script"
echo -e " [\e[36m 07 \e[0m] Clear Log VPS"
echo -e " [\e[36m 08 \e[0m] Info Script VPS"
echo -e " [\e[36m 09 \e[0m] Check VPS Ram Usage"
echo -e " [\e[36m 10 \e[0m] Restart All Service"
echo -e " [\e[36m 11 \e[0m] Check All Service Status"
echo -e " [\e[36m 12 \e[0m] Swap KVM Memory Service"
echo -e " [\e[36m 13 \e[0m] Set Auto Reboot VPS"
echo -e " [\e[36m 14 \e[0m] Speedtest VPS"
echo -e " [\e[36m 15 \e[0m] Update Key"
echo -e " [\e[36m 16 \e[0m] Sock User Menu"
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
    add-host
    ;;
2)
    cert_xray
    ;;  
3)
    clear
    backupmenu-bot
    ;;
4)
    clear
    add_dns
    ;;
5)
    clear
    cek-nf
    ;;
6)
    clear
    update_sc
    ;;
7)
    clear
    clear_log
    ;;
8)
    clear
    check_port
    ;;
9)
    clear
    check_ram
    ;; 
10)
    restart_all
    ;;
11)
    running_1
    ;;   
12)
    swap_kvm
    ;; 
13)
    autoreboot
    ;;
14)
    clear
    speedtest
    read -n 1 -s -r -p "Press any key to return to menu..."
    menu-vps
    ;;
15)
    clear
    wgf
    ;;
16)
    clear
    sock_user
    ;; 
x)  clear
    menu
    ;;
*)
    echo -e ""
    echo "Sila Pilih Semula"
    sleep 1
    menu-vps
    ;;
esac
