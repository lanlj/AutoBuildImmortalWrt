#!/bin/sh
# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE

# LAN口设置静态IP
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.50.4'
uci set network.lan.netmask='255.255.255.0'
echo "set 192.168.50.4 at $(date)" >> $LOGFILE

# 提交更改
uci commit

#设置快捷更新别名
if ! grep -q "Lenyu-pw" /etc/profile; then
  sed -i "$ a alias lenyu-pw='sh /usr/share/Lenyu-pw.sh'" /etc/profile
fi

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="by wukongdaily"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
