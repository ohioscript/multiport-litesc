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

# Warna
green() { echo -e "\033[32;1m$*\033[0m"; }
red() { echo -e "\033[31;1m$*\033[0m"; }
NC='\033[0m'

echo -e "[ ${green}INFO${NC} ] XRAY Core Vless,gRPC,Xhttp & Http Upgrade"
sleep 3

date
echo ""

sleep 1
mkdir -p /etc/xray

echo -e "[ ${green}INFO${NC} ] Setting time synchronization..."
# Force sync time once
ntpdate pool.ntp.org || echo "ntpdate failed, skipping initial sync"
# Enable automatic NTP via chrony/timedatectl
timedatectl set-ntp true

echo -e "[ ${green}INFO${NC} ] Enable and restart chrony service..."
systemctl enable chrony
systemctl restart chrony
chronyc makestep

echo -e "[ ${green}INFO${NC} ] Set timezone..."
timedatectl set-timezone Asia/Kuala_Lumpur

echo -e "[ ${green}INFO${NC} ] Show chrony status..."
chronyc sourcestats -v
chronyc tracking -v

# Setup xray log folders & files
echo -e "[ ${green}INFO${NC} ] Setting up Xray log directories and permissions..."
domainSock_dir="/run/xray"
mkdir -p "$domainSock_dir"
chown www-data:www-data "$domainSock_dir"

mkdir -p /var/log/xray /etc/xray
chown www-data:www-data /var/log/xray
chmod +x /var/log/xray

touch /var/log/xray/access.log
touch /var/log/xray/error.log

# Install Xray Core latest
echo -e "[ ${green}INFO${NC} ] Downloading & Installing xray core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data

# Setup ACME certificate with acme.sh
echo -e "[ ${green}INFO${NC} ] Setup ACME SSL certificate..."
systemctl stop nginx 2>/dev/null

mkdir -p /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh

/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256
/root/.acme.sh/acme.sh --installcert -d "$domain" \
    --fullchainpath /etc/xray/xray.crt \
    --keypath /etc/xray/xray.key --ecc

chown -R nobody:nogroup /etc/xray
chmod 644 /etc/xray/xray.key
chmod 644 /etc/xray/xray.crt

# Setup Genkey
wget -O /usr/local/bin/genkey "https://github.com/vpnlegasi/resources/raw/main/service/genkey"
chmod +x /usr/local/bin/genkey

# Setup cron job to renew SSL cert for nginx
echo -n '#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
' > /usr/local/bin/ssl_renew.sh
chmod +x /usr/local/bin/ssl_renew.sh

if ! crontab -l | grep -q 'ssl_renew.sh'; then
    (crontab -l 2>/dev/null; echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab -
fi

echo -e "[ ${green}INFO${NC} ] Setup completed."

#clean config
rm -rf /usr/local/etc/xray/*.json

# set uuid
uuid=$(cat /proc/sys/kernel/random/uuid)

# set key
mkdir -p /tmp/key1
/usr/local/bin/genkey register <<< "yes" >/dev/null 2>&1
/usr/local/bin/genkey generate <<< "yes" >/dev/null 2>&1
KEY1=$(grep 'PrivateKey' /tmp/key1/wgcf-profile.conf | awk '{print $3}')

mkdir -p /tmp/key2
/usr/local/bin/genkey register <<< "yes" >/dev/null 2>&1
/usr/local/bin/genkey generate <<< "yes" >/dev/null 2>&1
KEY2=$(grep 'PrivateKey' /tmp/key2/wgcf-profile.conf | awk '{print $3}')

#Vless Json
cat > /usr/local/etc/xray/api.json <<END
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls","quic"]
      }
    }
  ]
}
END

cat > /usr/local/etc/xray/vless.json <<END
{
  "inbounds": [
    {
      "tag": "in-01",
      "listen": "127.0.0.1",
      "port": 14016,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "${uuid}"
#vless
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls","quic"],
        "routeOnly": true
      }
    },
    {
      "tag": "in-02",
      "listen": "127.0.0.1",
      "port": 14017,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "${uuid}"
#vless
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vless-grpc"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls","quic"],
        "routeOnly": true
      }
    },
    {
      "tag": "in-03",
      "listen": "127.0.0.1",
      "port": 14018,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "${uuid}"
#vless
          }
        ]
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "path": "/httpupgrade",
          "acceptProxyProtocol": false
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls","quic"],
        "routeOnly": true
      }
    },
    {
      "tag": "in-04",
      "listen": "127.0.0.1",
      "port": 14019,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "${uuid}"
#vless
          }
        ]
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "path": "/xhttp",
          "acceptProxyProtocol": false
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls","quic"],
        "routeOnly": true
      }
    }
  ]
}
END

cat > /usr/local/etc/xray/dns.json <<END
{
  "dns": {
    "queryStrategy": "UseIPv4",
    "servers": [
      "8.8.8.8",
      "8.8.4.4"
    ]
  }
}
END

cat > /usr/local/etc/xray/log.json <<END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  }
}
END

cat > /usr/local/etc/xray/outbounds.json <<END
{
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "wireguard",
      "settings": {
        "secretKey": "${KEY1}",
        "address": ["172.16.0.2/32"],
        "peers": [
          {
            "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
            "endpoint": "engage.cloudflareclient.com:2408"
          }
        ]
      },
      "tag": "legasi-1"
    },
    {
      "protocol": "wireguard",
      "settings": {
        "secretKey": "${KEY2}",
        "address": ["172.16.0.3/32"],
        "peers": [
          {
            "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
            "endpoint": "engage.cloudflareclient.com:2408"
          }
        ]
      },
      "tag": "legasi-2"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ]
}
END

cat > /usr/local/etc/xray/policy.json <<END
{
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  }
}
END

cat > /usr/local/etc/xray/routing.json <<END
{
  "routing": {
    "domainStrategy": "AsIs",
    "balancers": [
      {
        "tag": "sock-legasi",
        "selector": ["legasi-1","legasi-2"],
        "strategy": {
          "type": "leastPing"
        },
        "fallback": "direct"
      }
    ],
    "rules": [
      {
        "type": "field",
        "port": "22",
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "inboundTag": ["sock-client"],
        "balancerTag": "sock-legasi"
      },
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": [
          "domain:fast.com",
          "domain:maybank2u.com.my"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": [
          "geosite:akamai",
          "geosite:amazon",
          "geosite:primevideo",
          "geosite:hbo",
          "geosite:hotstar",
          "geosite:disney",
          "geosite:netflix",
          "geosite:spotify",
          "geosite:viu",
          "geosite:dailymotion",
          "geosite:apple",
          "geosite:youtube",
          "geosite:facebook",
          "geosite:twitter",
          "geosite:tiktok",
          "geosite:iqiyi",
          "geosite:google",
          "regexp:.*\\.my$"
        ],
        "balancerTag": "sock-legasi"
      },
      {
        "type": "field",
        "ip": [
          "geoip:my"
        ],
        "balancerTag": "sock-legasi"
      },
      {
        "type": "field",
        "ip": ["0.0.0.0/0"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "direct"
      }
    ]
  }
}

END

cat > /usr/local/etc/xray/stats.json <<END
{
  "stats": {}
}
END

cat > /usr/local/etc/xray/observatory.json <<END
{
  "observatory": {
    "subjectSelector": [
      "legasi-1",
      "legasi-2"
    ],
    "probeURL": "https://www.google.com/generate_204",
    "probeInterval": "10s",
    "probeTimeout": "5s",
    "enableConcurrency": true
  }
}
END

cat > /usr/local/etc/xray/socks.json <<END
{
  "inbounds": [
    {
      "tag": "sock-client",
      "listen": "0.0.0.0",
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "udp": true,
        "accounts": [
          {
            "user": "vpn",
            "pass": "legasi"
          }
        ]
      }
    }
  ]
}
END

rm -rf /etc/systemd/system/xray*
cat> /etc/systemd/system/xray.service << END
[Unit]
Description=XRAY Service  By VPN Legasi
Documentation=${host}
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray/
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

END

cat > /etc/systemd/system/runn.service <<EOF
[Unit]
Description=Xray Service By VPN Legasi
Documentation=${host}
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
# // Iptable xray
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 14016 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 14017 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 14018 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 14019 -j ACCEPT

# // Iptable xray
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 14016 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 14017 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 14018 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 14019 -j ACCEPT

# // Iptable Sock
iptables -C INPUT -p tcp --dport $PORT -j DROP 2>/dev/null || iptables -A INPUT -p tcp --dport $PORT -j DROP
iptables -C INPUT -p udp --dport $PORT -j DROP 2>/dev/null || iptables -A INPUT -p udp --dport $PORT -j DROP
iptables -C INPUT -i lo -p tcp --dport $PORT -j ACCEPT 2>/dev/null || iptables -I INPUT -i lo -p tcp --dport $PORT -j ACCEPT
iptables -C INPUT -i lo -p udp --dport $PORT -j ACCEPT 2>/dev/null || iptables -I INPUT -i lo -p udp --dport $PORT -j ACCEPT

iptables-save >/etc/iptables.rules.v4
netfilter-persistent save
netfilter-persistent reload

# // Starting
systemctl daemon-reload
systemctl restart xray
systemctl enable xray
systemctl restart xray.service
systemctl enable xray.service

#nginx config
cat >/etc/nginx/conf.d/xray.conf <<EOF
    server {
             listen 80;
             listen [::]:80;
             listen 8080;
             listen [::]:8080;
             listen 443 ssl http2 reuseport;
             listen [::]:443 ssl http2 reuseport;
             server_name ${domain};
             ssl_certificate /etc/xray/xray.crt;
             ssl_certificate_key /etc/xray/xray.key;
             ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
             ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
             root /home/vps/public_html;

             location / {
                       proxy_http_version 1.1;
                       proxy_set_header Host ccc;
             proxy_set_header X-Real-IP aaa;
             proxy_set_header X-Forwarded-For bbb;
             proxy_set_header Upgrade ddd;
             proxy_set_header Connection "upgrade";

             if (ddd = "websocket") {
                rewrite ^.*$ / break;
                proxy_pass http://127.0.0.1:14016;
                break;
             }

             proxy_pass http://127.0.0.1:700;
 }
             location ~* httpupgrade {
                       rewrite ^.*httpupgrade.*$ /httpupgrade break;
                       proxy_redirect off;
                       proxy_pass http://127.0.0.1:14018;
                       proxy_http_version 1.1;
             proxy_set_header X-Real-IP aaa;
             proxy_set_header X-Forwarded-For bbb;
             proxy_set_header Upgrade ddd;
             proxy_set_header Connection "upgrade";
             proxy_set_header Host eee;
 }
             location ^~ /vless-grpc {
                      proxy_redirect off;
                      grpc_set_header X-Real-IP aaa;
                      grpc_set_header X-Forwarded-For bbb;
             grpc_set_header Host eee;
             grpc_pass grpc://127.0.0.1:14017;
 }
             location ~* xhttp {
                      proxy_redirect off;
                      proxy_pass http://127.0.0.1:14019;
                      proxy_http_version 1.1;
             proxy_set_header Host ccc;
             proxy_set_header X-Real-IP aaa;
             proxy_set_header X-Forwarded-For bbb;
             proxy_set_header Connection "";
 }
        }
EOF

# // Move
sed -i 's/aaa/$remote_addr/g' /etc/nginx/conf.d/xray.conf
sed -i 's/bbb/$proxy_add_x_forwarded_for/g' /etc/nginx/conf.d/xray.conf
sed -i 's/ccc/$host/g' /etc/nginx/conf.d/xray.conf
sed -i 's/ddd/$http_upgrade/g' /etc/nginx/conf.d/xray.conf
sed -i 's/eee/$http_host/g' /etc/nginx/conf.d/xray.conf
sed -i 's/fff/"upgrade"/g' /etc/nginx/conf.d/xray.conf
sed -i 's/ggg/"websocket"/g' /etc/nginx/conf.d/xray.conf

systemctl stop nginx
rm -rf /lib/systemd/system/nginx.service

echo -e "$yell[SERVICE]$NC Restart All service"

systemctl stop nginx

if [ -f /lib/systemd/system/nginx.service ]; then
    mv /lib/systemd/system/nginx.service /lib/systemd/system/nginx.service.bak-$(date +%F-%T)
fi

cat > /lib/systemd/system/nginx.service <<EOF
[Unit]
Description=High performance web server and a reverse proxy server by VPN Legasi
Documentation=${host}
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry=5 --pidfile /run/nginx.pid
ExecStartPost=/bin/sleep 1
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

sleep 1
echo -e "[ ${green}ok${NC} ] Enable & restart Xray"
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
sleep 1

echo -e "[ ${green}ok${NC} ] Enable & restart Nginx"
systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx
sleep 1

rm -rf /etc/log-create-user.log
sleep 1

clear
rm -rf /rtmp/key1
rm -rf /tmp/key2
rm -rf ins-xray.sh