#!/bin/sh
# Define variables
TEMP_DIR="/tmp/pw"
UNZIP_URL="https://dl.openwrt.ai/packages-24.10/x86_64/packages/unzip_6.0-r8_x86_64.ipk"
UNZIP_PACKAGE="unzip_6.0-r8_x86_64.ipk"
RED='\033[0;31m'    # Red color
BLUE='\033[0;34m'   # Blue color
ORANGE='\033[0;33m' # Orange color
NC='\033[0m'        # No Color (reset)

# Echo message in red color
echo_red() {
  echo -e "${RED}$1${NC}"
}

# Echo message in blue color
echo_blue() {
  echo -e "${BLUE}$1${NC}"
}

# Echo message in orange color
echo_orange() {
  echo -e "${ORANGE}$1${NC}"
}

# Preparing for update (blue message)
echo_blue "正在做更新前的准备工作..."
# 检查 unzip 是否已安装
if opkg list-installed | grep -q unzip; then
  echo "unzip 已经安装，跳过安装步骤。"
else
  # 下载 unzip 包
  echo "开始下载 unzip 包..."
  wget -q "$UNZIP_URL" -O "$UNZIP_PACKAGE"

  # 检查下载是否成功
  if [ $? -eq 0 ]; then
    echo "下载成功，开始安装 unzip 包..."
    opkg install "$UNZIP_PACKAGE"

    # 检查安装是否成功
    if [ $? -eq 0 ]; then
      echo "unzip 安装成功！"
    else
      echo "unzip 安装失败！"
    fi
    rm -rf "$UNZIP_PACKAGE"
  else
    echo "unzip 下载失败！"
  fi
fi

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Get the latest release information from GitHub
latest_release=$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest)

# Extract version number from GitHub release (例如 "25.3.9-1")
version=$(echo "$latest_release" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')

# Extract download URLs
luci_app_passwall_url=$(echo "$latest_release" | grep -o '"browser_download_url": "[^"]*luci-24.10_luci-app-passwall_[^"]*"' | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')
luci_i18n_passwall_url=$(echo "$latest_release" | grep -o '"browser_download_url": "[^"]*luci-24.10_luci-i18n-passwall-zh-cn_[^"]*"' | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')
#passwall_packages_url=$(echo "$latest_release" | grep -o '"browser_download_url": "[^"]*passwall_packages_ipk_x86_64[^"]*"' | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')
passwall_packages_url="https://github.com/xiaorouji/openwrt-passwall/releases/download/$version/passwall_packages_ipk_x86_64.zip"

# 获取文件名（例如 luci-24.10_luci-app-passwall_25.3.9-r1_all.ipk）
app_file=$(basename "$luci_app_passwall_url")
i18n_file=$(basename "$luci_i18n_passwall_url")
#pks_file=$(basename "$passwall_packages_url")

# 从 app_file 中提取版本号部分，即 "25.3.9-r1"
version2410=$(echo "$app_file" | sed -E 's/^luci-24\.10_luci-app-passwall_([^_]+)_all\.ipk$/\1/')
echo_blue "最新云端版本号：$version2410"

# 提取当前安装的版本号
installed_version=$(opkg list-installed | grep luci-app-passwall | awk '{print $3}')
echo_blue "当前本地版本号：$installed_version"

# 检查版本是否已经是最新的，比较时使用 version2410 变量
if [ "$installed_version" = "$version2410" ]; then
  echo_red "已经是最新版本，还更新个鸡毛啊！"
  exit 0
fi

# 如果版本不一致，提示用户确认（10秒倒计时，默认 y）
echo_orange "你即将更新 passwall 为最新版本：$version2410，确定更新吗？(y/n, 回车默认y，10秒后自动执行y)"
read -t 10 -r confirmation
confirmation=${confirmation:-y}

if [ "$confirmation" != "y" ]; then
  echo_blue "已取消更新。"
  exit 0
fi

# 用户确认后继续更新
echo_blue "新版本可用，开始更新..."

# 是否更新软件包依赖（10秒倒计时，默认 n）
echo_orange "是否同时下载并更新软件包依赖？(y/n, 回车默认n，10秒后自动执行n)"
read -t 10 -r update_confirmation
update_confirmation=${update_confirmation:-n}

# 下载文件到临时目录（保持原文件名）
wget -O "$TEMP_DIR/$app_file" "$luci_app_passwall_url"
wget -O "$TEMP_DIR/$i18n_file" "$luci_i18n_passwall_url"
if [ "$update_confirmation" = "y" ]; then
  wget -O "$TEMP_DIR/passwall_packages_ipk_x86_64.zip" "$passwall_packages_url"
fi
sleep 5
echo "下载完成:"
echo "$TEMP_DIR/$app_file"
echo "$TEMP_DIR/$i18n_file"
if [ "$update_confirmation" = "y" ]; then
  echo "$TEMP_DIR/passwall_packages_ipk_x86_64.zip"
fi

# 安装下载的 IPK 包
/etc/init.d/passwall stop
sleep 5
if [ "$update_confirmation" = "y" ]; then
  unzip -d "$TEMP_DIR/pks" "$TEMP_DIR/passwall_packages_ipk_x86_64.zip"
  opkg install $TEMP_DIR/pks/*.ipk
fi
opkg install "$TEMP_DIR/$app_file" --force-overwrite
opkg install "$TEMP_DIR/$i18n_file" --force-overwrite

# 重启 passwall 服务
/etc/init.d/passwall restart

echo_blue "插件已安装并且 passwall 服务已重启。"

# 清理临时目录
rm -rf "$TEMP_DIR"

exit 0
