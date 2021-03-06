#!/bin/sh /etc/rc.common
status=$(ps|grep -c /usr/share/openclash/yml_proxys_set.sh)
[ "$status" -gt "3" ] && exit 0

START_LOG="/tmp/openclash_start.log"
SERVER_FILE="/tmp/yaml_servers.yaml"
PROXY_PROVIDER_FILE="/tmp/yaml_provider.yaml"
servers_if_update=$(uci get openclash.config.servers_if_update 2>/dev/null)
config_auto_update=$(uci get openclash.config.auto_update 2>/dev/null)
CONFIG_FILE=$(uci get openclash.config.config_path 2>/dev/null)
CONFIG_NAME=$(echo $CONFIG_FILE |awk -F '/' '{print $5}' 2>/dev/null)
UPDATE_CONFIG_FILE=$(uci get openclash.config.config_update_path 2>/dev/null)
UPDATE_CONFIG_NAME=$(echo $UPDATE_CONFIG_FILE |awk -F '/' '{print $5}' 2>/dev/null)

if [ ! -z "$UPDATE_CONFIG_FILE" ]; then
   CONFIG_FILE="$UPDATE_CONFIG_FILE"
   CONFIG_NAME="$UPDATE_CONFIG_NAME"
fi

if [ -z "$CONFIG_FILE" ]; then
	CONFIG_FILE="/etc/openclash/config/$(ls -lt /etc/openclash/config/ | grep -E '.yaml|.yml' | head -n 1 |awk '{print $9}')"
	CONFIG_NAME=$(echo $CONFIG_FILE |awk -F '/' '{print $5}' 2>/dev/null)
fi

if [ -z "$CONFIG_NAME" ]; then
   CONFIG_FILE="/etc/openclash/config/config.yaml"
   CONFIG_NAME="config.yaml"
fi

#写入代理集到配置文件
yml_proxy_provider_set()
{
   local section="$1"
   config_get_bool "enabled" "$section" "enabled" "1"
   config_get "config" "$section" "config" ""
   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "path" "$section" "path" ""
   config_get "provider_url" "$section" "provider_url" ""
   config_get "provider_interval" "$section" "provider_interval" ""
   config_get "health_check" "$section" "health_check" ""
   config_get "health_check_url" "$section" "health_check_url" ""
   config_get "health_check_interval" "$section" "health_check_interval" ""
   
   if [ ! -z "$config" ] && [ "$config" != "$CONFIG_NAME" ] && [ "$config" != "all" ]; then
      return
   fi
   
   if [ "$enabled" = "0" ]; then
      return
   fi

   if [ -z "$type" ]; then
      return
   fi
   
   if [ -z "$name" ]; then
      return
   fi
   
   if [ -z "$path" ]; then
      return
   fi
   
   if [ -z "$health_check" ]; then
      return
   fi
   
   echo "正在写入【$type】-【$name】代理集到配置文件【$CONFIG_NAME】..." >$START_LOG
   echo "$name" >> /tmp/Proxy_Provider
   
cat >> "$PROXY_PROVIDER_FILE" <<-EOF
  $name:
    type: $type
    path: $path
EOF
   if [ ! -z "$provider_url" ]; then
cat >> "$PROXY_PROVIDER_FILE" <<-EOF
    url: $provider_url
    interval: $provider_interval
EOF
   fi
cat >> "$PROXY_PROVIDER_FILE" <<-EOF
    health-check:
      enable: $health_check
      url: $health_check_url
      interval: $health_check_interval
EOF

}

#写入服务器节点到配置文件
yml_servers_set()
{

   local section="$1"
   config_get_bool "enabled" "$section" "enabled" "1"
   config_get "config" "$section" "config" ""
   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "server" "$section" "server" ""
   config_get "port" "$section" "port" ""
   config_get "cipher" "$section" "cipher" ""
   config_get "password" "$section" "password" ""
   config_get "securitys" "$section" "securitys" ""
   config_get "udp" "$section" "udp" ""
   config_get "obfs" "$section" "obfs" ""
   config_get "obfs_vmess" "$section" "obfs_vmess" ""
   config_get "host" "$section" "host" ""
   config_get "mux" "$section" "mux" ""
   config_get "custom" "$section" "custom" ""
   config_get "tls" "$section" "tls" ""
   config_get "skip_cert_verify" "$section" "skip_cert_verify" ""
   config_get "path" "$section" "path" ""
   config_get "alterId" "$section" "alterId" ""
   config_get "uuid" "$section" "uuid" ""
   config_get "auth_name" "$section" "auth_name" ""
   config_get "auth_pass" "$section" "auth_pass" ""
   config_get "psk" "$section" "psk" ""
   config_get "obfs_snell" "$section" "obfs_snell" ""
   
   if [ ! -z "$config" ] && [ "$config" != "$CONFIG_NAME" ] && [ "$config" != "all" ]; then
      return
   fi
   
   if [ "$enabled" = "0" ]; then
      return
   fi

   if [ -z "$type" ]; then
      return
   fi
   
   if [ -z "$name" ]; then
      return
   fi
   
   if [ -z "$server" ]; then
      return
   fi
   
   if [ -z "$port" ]; then
      return
   fi
   
   if [ -z "$password" ] && [ "$type" = "ss" ]; then
      return
   fi
   
   echo "正在写入【$type】-【$name】节点到配置文件【$CONFIG_NAME】..." >$START_LOG
   
   if [ "$obfs" != "none" ]; then
      if [ "$obfs" = "websocket" ]; then
         obfss="plugin: v2ray-plugin"
      else
         obfss="plugin: obfs"
      fi
   fi
   
   if [ ! -z "$udp" ] && [ "$obfs" = "none" ]; then
      udp=", udp: $udp"
   fi
   
   if [ "$obfs_snell" = "none" ]; then
      obfs_snell=""
   fi
   
   if [ "$obfs_vmess" != "none" ]; then
      obfs_vmess=", network: ws"
   else
      obfs_vmess=""
   fi
   
   if [ ! -z "$host" ]; then
      host="host: $host"
   fi
   
   if [ ! -z "$custom" ] && [ "$type" = "vmess" ]; then
      custom=", ws-headers: { Host: $custom }"
   fi
   
   if [ ! -z "$tls" ] && [ "$type" != "ss" ]; then
      tls=", tls: $tls"
   elif [ ! -z "$tls" ]; then
      tls="tls: $tls"
   fi
   
   if [ ! -z "$path" ]; then
      if [ "$type" != "vmess" ]; then
         path="path: '$path'"
      else
         path=", ws-path: $path"
      fi
   fi
   
   if [ ! -z "$skip_cert_verify" ] && [ "$type" != "ss" ]; then
      skip_cert_verify=", skip-cert-verify: $skip_cert_verify"
   elif [ ! -z "$skip_cert_verify" ]; then
      skip_cert_verify="skip-cert-verify: $skip_cert_verify"
   fi

   if [ "$type" = "ss" ] && [ "$obfs" = "none" ]; then
      echo "- { name: \"$name\", type: $type, server: $server, port: $port, cipher: $cipher, password: \"$password\"$udp }" >>$SERVER_FILE
   elif [ "$type" = "ss" ] && [ "$obfs" != "none" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  cipher: $cipher
  password: "$password"
EOF
  if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
  udp: $udp
EOF
  fi
if [ ! -z "$obfss" ] && [ ! -z "$host" ]; then
cat >> "$SERVER_FILE" <<-EOF
  $obfss
  plugin-opts:
    mode: $obfs
    $host
EOF
  fi
  if [ ! -z "$tls" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $tls
EOF
  fi
  if [ ! -z "$skip_cert_verify" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $skip_cert_verify
EOF
  fi
  if [ ! -z "$path" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $path
EOF
  fi
  if [ ! -z "$mux" ]; then
cat >> "$SERVER_FILE" <<-EOF
    mux: $mux
EOF
  fi
  if [ ! -z "$custom" ]; then
cat >> "$SERVER_FILE" <<-EOF
    headers:
      custom: $custom
EOF
  fi
   fi
   
   if [ "$type" = "vmess" ]; then
      echo "- { name: \"$name\", type: $type, server: $server, port: $port, uuid: $uuid, alterId: $alterId, cipher: $securitys$skip_cert_verify$obfs_vmess$path$custom$tls }" >>$SERVER_FILE
   fi
   
   if [ "$type" = "socks5" ] || [ "$type" = "http" ]; then
      echo "- { name: \"$name\", type: $type, server: $server, port: $port, username: $auth_name, password: $auth_pass$skip_cert_verify$tls }" >>$SERVER_FILE
   fi
   
   if [ "$type" = "snell" ]; then
cat >> "$SERVER_FILE" <<-EOF
- name: "$name"
  type: $type
  server: $server
  port: $port
  psk: $psk
EOF
   if [ "$obfs_snell" != "none" ] && [ ! -z "$host" ]; then
cat >> "$SERVER_FILE" <<-EOF
  obfs-opts:
    mode: $obfs_snell
    $host
EOF
   fi
   fi

}


#创建配置文件
#proxy-provider
echo "开始写入配置文件【$CONFIG_NAME】的代理集信息..." >$START_LOG
echo "proxy-provider:" >$PROXY_PROVIDER_FILE
rm -rf /tmp/Proxy_Provider
config_load "openclash"
config_foreach yml_proxy_provider_set "proxy-provider"
sed -i "s/^ \{0,\}/  - /" /tmp/Proxy_Provider 2>/dev/null #添加参数
if [ "$(grep "-" /tmp/Proxy_Provider |wc -l)" -eq 0 ]; then
   rm -rf $PROXY_PROVIDER_FILE
   rm -rf /tmp/Proxy_Provider
fi

#proxy
rule_sources=$(uci get openclash.config.rule_sources 2>/dev/null)
create_config=$(uci get openclash.config.create_config 2>/dev/null)
echo "开始写入配置文件【$CONFIG_NAME】的服务器节点信息..." >$START_LOG
echo "Proxy:" >$SERVER_FILE
config_foreach yml_servers_set "servers"
egrep '^ {0,}-' $SERVER_FILE |grep name: |awk -F 'name: ' '{print $2}' |sed 's/,.*//' 2>/dev/null >/tmp/Proxy_Server 2>&1
if [ -s "/tmp/Proxy_Server" ]; then
   sed -i "s/^ \{0,\}/  - /" /tmp/Proxy_Server 2>/dev/null #添加参数
else
   rm -rf $SERVER_FILE
   rm -rf /tmp/Proxy_Server
fi

#一键创建配置文件
if [ "$rule_sources" = "ConnersHua" ] && [ "$servers_if_update" != "1" ]; then
echo "使用ConnersHua规则创建中..." >$START_LOG
echo "Proxy Group:" >>$SERVER_FILE
cat >> "$SERVER_FILE" <<-EOF
- name: Auto - UrlTest
  type: url-test
EOF
if [ -f "/tmp/Proxy_Server" ]; then
cat >> "$SERVER_FILE" <<-EOF
  proxies:
EOF
fi
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  url: http://www.gstatic.com/generate_204
  interval: "600"
- name: Proxy
  type: select
  proxies:
  - Auto - UrlTest
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Domestic
  type: select
  proxies:
  - DIRECT
  - Proxy
- name: Others
  type: select
  proxies:
  - Proxy
  - DIRECT
  - Domestic
- name: AdBlock
  type: select
  proxies:
  - REJECT
  - DIRECT
  - Proxy
- name: Apple
  type: select
  proxies:
  - DIRECT
  - Proxy
- name: AsianTV
  type: select
  proxies:
  - DIRECT
  - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: GlobalTV
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
uci set openclash.config.rule_source="ConnersHua"
uci set openclash.config.GlobalTV="GlobalTV"
uci set openclash.config.AsianTV="AsianTV"
uci set openclash.config.Proxy="Proxy"
uci set openclash.config.Apple="Apple"
uci set openclash.config.AdBlock="AdBlock"
uci set openclash.config.Domestic="Domestic"
uci set openclash.config.Others="Others"
[ "$config_auto_update" -eq 1 ] && {
	uci set openclash.config.servers_update="1"
	uci del openclash.config.new_servers_group >/dev/null 2>&1
	uci add_list openclash.config.new_servers_group="Auto - UrlTest"
	uci add_list openclash.config.new_servers_group="Proxy"
 	uci add_list openclash.config.new_servers_group="AsianTV"
	uci add_list openclash.config.new_servers_group="GlobalTV"
}
elif [ "$rule_sources" = "lhie1" ] && [ "$servers_if_update" != "1" ]; then
echo "使用lhie1规则创建中..." >$START_LOG
echo "Proxy Group:" >>$SERVER_FILE
cat >> "$SERVER_FILE" <<-EOF
- name: Auto - UrlTest
  type: url-test
EOF
if [ -f "/tmp/Proxy_Server" ]; then
cat >> "$SERVER_FILE" <<-EOF
  proxies:
EOF
fi
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  url: http://www.gstatic.com/generate_204
  interval: "600"
- name: Proxy
  type: select
  proxies:
  - Auto - UrlTest
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Domestic
  type: select
  proxies:
  - DIRECT
  - Proxy
- name: Others
  type: select
  proxies:
  - Proxy
  - DIRECT
  - Domestic
- name: AsianTV
  type: select
  proxies:
  - DIRECT
  - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: GlobalTV
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Speedtest
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Telegram
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Netease Music
  type: select
  proxies:
  - DIRECT
  - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
uci set openclash.config.rule_source="lhie1"
uci set openclash.config.GlobalTV="GlobalTV"
uci set openclash.config.AsianTV="AsianTV"
uci set openclash.config.Proxy="Proxy"
uci set openclash.config.Netease_Music="Netease Music"
uci set openclash.config.Speedtest="Speedtest"
uci set openclash.config.Telegram="Telegram"
uci set openclash.config.Domestic="Domestic"
uci set openclash.config.Others="Others"
[ "$config_auto_update" -eq 1 ] && {
	uci set openclash.config.servers_update="1"
	uci del openclash.config.new_servers_group >/dev/null 2>&1
	uci add_list openclash.config.new_servers_group="Auto - UrlTest"
	uci add_list openclash.config.new_servers_group="Proxy"
 	uci add_list openclash.config.new_servers_group="AsianTV"
	uci add_list openclash.config.new_servers_group="GlobalTV"
	uci add_list openclash.config.new_servers_group="Telegram"
	uci add_list openclash.config.new_servers_group="Speedtest"
	uci add_list openclash.config.new_servers_group="Netease Music"
}
elif [ "$rule_sources" = "ConnersHua_return" ] && [ "$servers_if_update" != "1" ]; then
echo "使用ConnersHua回国规则创建中..." >$START_LOG
echo "Proxy Group:" >>$SERVER_FILE
cat >> "$SERVER_FILE" <<-EOF
- name: Auto - UrlTest
  type: url-test
EOF
if [ -f "/tmp/Proxy_Server" ]; then
cat >> "$SERVER_FILE" <<-EOF
  proxies:
EOF
fi
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  url: http://www.gstatic.com/generate_204
  interval: "600"
- name: Proxy
  type: select
  proxies:
  - Auto - UrlTest
  - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
  use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
- name: Others
  type: select
  proxies:
  - Proxy
  - DIRECT
EOF
uci set openclash.config.rule_source="ConnersHua_return"
uci set openclash.config.Proxy="Proxy"
uci set openclash.config.Others="Others"
[ "$config_auto_update" -eq 1 ] && {
	uci set openclash.config.servers_update="1"
	uci del openclash.config.new_servers_group >/dev/null 2>&1
	uci add_list openclash.config.new_servers_group="Auto - UrlTest"
	uci add_list openclash.config.new_servers_group="Proxy"
}
fi

if [ "$create_config" != "0" ] && [ "$servers_if_update" != "1" ]; then
   echo "Rule:" >>$SERVER_FILE
   echo "配置文件【$CONFIG_NAME】创建完成，正在更新服务器、代理集、策略组信息..." >$START_LOG
   cat "$PROXY_PROVIDER_FILE" > "$CONFIG_FILE" 2>/dev/null
   cat "$SERVER_FILE" >> "$CONFIG_FILE" 2>/dev/null
   /usr/share/openclash/yml_groups_get.sh >/dev/null 2>&1
else
   echo "服务器、代理集、策略组信息修改完成，正在更新配置文件【$CONFIG_NAME】..." >$START_LOG
   #判断各个区位置
   proxy_len=$(sed -n '/^Proxy:/=' "$CONFIG_FILE" 2>/dev/null)
   group_len=$(sed -n '/^ \{0,\}Proxy Group:/=' "$CONFIG_FILE" 2>/dev/null)
   provider_len=$(sed -n '/^proxy-provider:/=' "$CONFIG_FILE" 2>/dev/null)
   if [ "$provider_len" -le "$proxy_len" ]; then
      sed -i '/^ \{0,\}proxy-provider:/i\#change server#' "$CONFIG_FILE" 2>/dev/null
      sed -i '/^ \{0,\}Rule:/i\#change server end#' "$CONFIG_FILE" 2>/dev/null
      sed -i '/^ \{0,\}proxy-provider:/,/#change server end#/d' "$CONFIG_FILE" 2>/dev/null
   elif [ "$provider_len" -le "$group_len" ] && [ -z "$proxy_len" ]; then
      sed -i '/^ \{0,\}proxy-provider:/i\#change server#' "$CONFIG_FILE" 2>/dev/null
      sed -i '/^ \{0,\}Rule:/i\#change server end#' "$CONFIG_FILE" 2>/dev/null
      sed -i '/^ \{0,\}proxy-provider:/,/#change server end#/d' "$CONFIG_FILE" 2>/dev/null
   elif [ "$provider_len" -ge "$group_len" ] && [ -z "$proxy_len" ]; then
      sed -i '/^ \{0,\}Proxy Group:/i\#change server#' "$CONFIG_FILE" 2>/dev/null
      sed -i '/^ \{0,\}Rule:/i\#change server end#' "$CONFIG_FILE" 2>/dev/null
      sed -i '/^ \{0,\}Proxy Group:/,/#change server end#/d' "$CONFIG_FILE" 2>/dev/null
   else
      sed -i '/^ \{0,\}Proxy:/i\#change server#' "$CONFIG_FILE" 2>/dev/null
   	  sed -i '/^ \{0,\}Rule:/i\#change server end#' "$CONFIG_FILE" 2>/dev/null
      sed -i '/^ \{0,\}Proxy:/,/#change server end#/d' "$CONFIG_FILE" 2>/dev/null
   fi

   sed -i '/#change server#/r/tmp/yaml_groups.yaml' "$CONFIG_FILE" 2>/dev/null
   sed -i '/#change server#/r/tmp/yaml_servers.yaml' "$CONFIG_FILE" 2>/dev/null
   sed -i '/#change server#/r/tmp/yaml_provider.yaml' "$CONFIG_FILE" 2>/dev/null
   sed -i '/#change server#/d' "$CONFIG_FILE" 2>/dev/null
fi
echo "配置文件【$CONFIG_NAME】写入完成！" >$START_LOG
sleep 3
echo "" >$START_LOG
rm -rf $SERVER_FILE 2>/dev/null
rm -rf /tmp/Proxy_Server 2>/dev/null
rm -rf /tmp/yaml_groups.yaml 2>/dev/null
rm -rf $PROXY_PROVIDER_FILE 2>/dev/null
rm -rf /tmp/Proxy_Provider 2>/dev/null
uci set openclash.config.enable=1 2>/dev/null
[ "$(uci get openclash.config.servers_if_update)" == "0" ] && /etc/init.d/openclash restart >/dev/null 2>&1
uci set openclash.config.servers_if_update=0
uci commit openclash

