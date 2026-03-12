#!/bin/sh

# =================================================================
# Linksys MX4300 (LN1301) mtd30 扩容 OpenClash 一键脚本
# 适用空间：353MB (mtd30) -> 挂载至 /etc/openclash
# =================================================================

set -e

echo "开始执行 MX4300 mtd30 扩容脚本..."

# 1. 安装必要工具
echo "[1/6] 正在安装 UBI 工具..."
opkg update && opkg install kmod-ubi ubi-utils

# 2. 检查 mtd30 状态并关联
echo "[2/6] 正在检查并关联 mtd30..."
if ! ubiattach -p /dev/mtd30 2>/dev/null; then
    if [ $? -eq 17 ]; then
        echo "mtd30 已经关联，跳过..."
    else
        echo "正在格式化 mtd30 为 UBI 格式..."
        ubiformat /dev/mtd30 -y
        ubiattach -p /dev/mtd30
    fi
fi

# 3. 创建 UBI 卷 (如果不存在)
echo "[3/6] 检查 UBI 卷..."
if ! ubinfo /dev/ubi1_0 >/dev/null 2>&1; then
    echo "创建 clash_data 逻辑卷..."
    ubimkvol /dev/ubi1 -N clash_data -m
fi

# 4. 挂载分区
echo "[4/6] 挂载分区至 /mnt/clash_storage..."
mkdir -p /mnt/clash_storage
if ! mount | grep -q "/mnt/clash_storage"; then
    mount -t ubifs ubi1_0 /mnt/clash_storage
fi

# 5. 迁移 OpenClash 数据并建立软链接
echo "[5/6] 迁移数据并建立软链接..."
# 停止 OpenClash
if [ -f "/etc/init.d/openclash" ]; then
    /etc/init.d/openclash stop || true
fi

# 备份原配置（如果存在且不是链接）
if [ -d "/etc/openclash" ] && [ ! -L "/etc/openclash" ]; then
    echo "备份现有配置中..."
    cp -a /etc/openclash/* /mnt/clash_storage/ 2>/dev/null || true
    rm -rf /etc/openclash
fi

# 强制建立软链接
ln -sf /mnt/clash_storage /etc/openclash

# 补全必要目录结构
mkdir -p /etc/openclash/core /etc/openclash/config /etc/openclash/rule_bak
chmod -R 777 /mnt/clash_storage

# 6. 写入开机自启脚本
echo "[6/6] 配置开机自动挂载..."
if ! grep -q "mtd30" /etc/rc.local; then
    sed -i '/exit 0/i # OpenClash MTD30 Mount\nubiattach -p /dev/mtd30 2>/dev/null\nmount -t ubifs ubi1_0 /mnt/clash_storage' /etc/rc.local
    echo "已添加至 /etc/rc.local"
fi

echo "------------------------------------------------"
echo "恭喜！扩容完成。"
echo "当前 /etc/openclash 剩余空间："
df -h /etc/openclash | grep -v Filesystem
echo "------------------------------------------------"
echo "现在可以去 Web 界面启动 OpenClash 并下载内核了。"
