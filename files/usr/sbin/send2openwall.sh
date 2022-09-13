#!/bin/sh

plugin="openwall"
source /usr/sbin/plugins-common

show_help() {
  echo "Usage: $0 [-v] [-h]
  -v          Verbose output.
  -h          Show this help.
"
  exit 0
}

# default values
flash_size=$(awk '{sum+=sprintf("0x%s", $2);} END{print sum/1048576;}' /proc/mtd)
fw_variant=$(grep "BUILD_OPTION" /etc/os-release | cut -d= -f2 | tr -d /\"/); [ -z "$fw_variant" ] && fw_variant="lite"
fw_version=$(grep "OPENIPC_VERSION" /etc/os-release | cut -d= -f2 | tr -d /\"/)
network_hostname=$(hostname -s)
network_macaddr=$(ifconfig -a | grep HWaddr | sed s/.*HWaddr// | sed "s/ //g" | uniq | tail -1)
sensor=$(ipcinfo --short-sensor)
#sensor_config=$(yaml-cli -g .isp.sensorConfig)
soc=$(ipcinfo --chip-name)
soc_temperature=$(ipcinfo --temp)
uptime=$(uptime | sed -r 's/^.+ up ([^,]+), .+$/\1/')

# override config values with command line arguments
while getopts vh flag; do
  case ${flag} in
  v) verbose=1 ;;
  h) show_help ;;
  esac
done

[ "false" = "$openwall_enabled" ] &&
  log "Sending to OpenIPC Wall is disabled." && exit 10

if [ "true" = "$openwall_use_heif" ] && [ "h265" = "$(yaml-cli -g .video0.codec)" ]; then
  snapshot=/tmp/snapshot4cron.heif
  curl --silent --fail --url http://127.0.0.1/image.heif?t=$(date +"%s") --output ${snapshot}
else
  snapshot4cron.sh
  # [ $? -ne 0 ] && echo "Cannot get a snapshot" && exit 2
  snapshot=/tmp/snapshot4cron.jpg
fi
[ ! -f "$snapshot" ] && log "Cannot find a snapshot" && exit 3

# validate mandatory values
[ ! -f "$snapshot" ] &&
  log "Snapshot file not found" && exit 11
[ -z "$network_macaddr" ] &&
  log "MAC address not found" && exit 12

command="curl --verbose"
command="${command} --connect-timeout ${curl_timeout}"
command="${command} --max-time ${curl_timeout}"

# SOCK5 proxy, if needed
if [ "true" = "$yadisk_socks5_enabled" ]; then
  source /etc/webui/socks5.conf
  command="${command} --socks5-hostname ${socks5_host}:${socks5_port}"
  command="${command} --proxy-user ${socks5_login}:${socks5_password}"
fi

command="${command} --url https://openipc.org/snapshots"
command="${command} -F 'mac_address=${network_macaddr}'"
command="${command} -F 'firmware=${fw_version}-${fw_variant}'"
command="${command} -F 'flash_size=${flash_size}'"
command="${command} -F 'hostname=${network_hostname}'"
command="${command} -F 'sensor=${sensor}'"
# command="${command} -F 'sensor_config=${sensor_config}'"
command="${command} -F 'soc=${soc}'"
command="${command} -F 'soc_temperature=${soc_temperature}'"
command="${command} -F 'uptime=${uptime}'"
command="${command} -F 'file=@${snapshot}'"

log "$command"
eval "$command" >>$LOG_FILE 2>&1

[ "1" = "$verbose" ] && cat $LOG_FILE

exit 0
