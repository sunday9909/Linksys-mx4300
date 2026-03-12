#!/bin/sh

# =================================================================
# Linksys MX4300 (LN1301) mtd30 扩容 OpenClash 一键优化版
# =================================================================

set -e

# 1. 检查工具
echo "[1/6] 检查 UBI 工具..."
if ! command -v ubinfo >/dev/null 2>&1; then
    opkg update && opkg install kmod-ubi ubi-utils
else
    echo "工具已就绪，跳过安装。"
fi

# 2. 检查并关联 mtd30
echo "[2/6] 检查 mtd30 状态..."
if ! ubiattach -p /dev/mtd30 2>/dev/null; then
    # 错误码 17 表示已经关联 (File exists)
    [ $? -eq 17 ] || { echo "格式化 mtd30..."; ubiformat /dev/mtd30 -y && ubiattach -p /dev/mtd30; }
fi

# 3. 检查 UBI 卷
echo "[3/6] 检查 UBI 卷..."
if ! ubinfo /dev/ubi1_0 >/dev/null 2>&1; then
    ubimkvol /dev/ubi1 -N clash_data -m
fi

# 4. 挂载分区
echo "[4/6] 挂载至 /mnt/clash_storage..."
mkdir -p /mnt/clash_storage
mount | grep -q "/mnt/clash_storage" || mount -t ubifs ubi1_0 /mnt/clash_storage

# 5. 迁移 OpenClash 数据
echo "[5/6] 重定向 OpenClash 路径..."
/etc/init.d/openclash stop 2>/dev/null || true

if [ -d "/etc/openclash" ] && [ ! -L "/etc/openclash" ]; then
    cp -a /etc/openclash/* /mnt/clash_storage/ 2>/dev/null || true
    rm -rf /etc/openclash
fi

ln -sf /mnt/clash_storage /etc/openclash
mkdir -p /etc/openclash/core /etc/openclash/config
chmod -R 777 /mnt/clash_storage

# 6. 配置持久化
echo "[6/6] 配置开机自启..."
grep -q "mtd30" /etc/rc.local || sed -i '/exit 0/i # OpenClash MTD30 Mount\nubiattach -p /dev/mtd30 2>/dev/null\nmount -t ubifs ubi1_0 /mnt/clash_storage' /etc/rc.local

echo "------------------------------------------------"
df -h /etc/openclash | grep -v Filesystem
echo "部署完成！"
