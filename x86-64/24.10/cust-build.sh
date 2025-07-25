#!/bin/bash
# Log file for debugging
LOGFILE="/tmp/build-log.txt"
echo "Starting cust-build.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译..."

# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
# 服务-FileBrowser 用户名admin 密码admin
PACKAGES="$PACKAGES luci-i18n-filebrowser-go-zh-cn"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
#24.10
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ddns-go-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES cfdisk"
PACKAGES="$PACKAGES open-vm-tools"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ramfree-zh-cn"

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
  PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
  echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
  exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
