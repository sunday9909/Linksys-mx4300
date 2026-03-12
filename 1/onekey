cat << 'EOF' > /tmp/setup_clash.sh
#!/bin/sh

# Linksys MX4300 (LN1301) mtd30 扩容 OpenClash 一键脚本 (带写入校验版)
set -e

echo "------------------------------------------------"
echo "⚠️  注意：即将格式化或挂载 MTD30 (约 353MB) 分区"
echo "该分区通常为原厂 app2_data，请确保其中没有重要数据。"
echo "------------------------------------------------"
printf "请输入 'y' 确认继续执行: "
read confirm
if [ "$confirm" != "y" ]; then
    echo "用户取消，脚本退出。"
    exit 1
fi

# 1. 检查并安装工具 (已安装则跳过)
echo "[1/6] 检查 UBI 工具..."
if ! command -v ubinfo >/dev/null 2>&1; then
    echo "未检测到 UBI 工具，正在尝试安装..."
    opkg update && opkg install kmod-ubi ubi-utils || { echo "安装失败，请检查网络"; exit 1; }
else
    echo "工具已就绪，跳过安装。"
fi

# 2. 检查并关联 mtd30
echo "[2/6] 检查 mtd30 状态..."
if ! ubiattach -p /dev/mtd30 2>/dev/null; then
    RET=$?
    if [ $RET -eq 17 ]; then
        echo "mtd30 已经关联。"
    else
        echo "正在初始化/格式化 mtd30..."
        ubiformat /dev/mtd30 -y
        ubiattach -p /dev/mtd30
    fi
fi

# 3. 检查并创建 UBI 卷
echo "[3/6] 检查 UBI 卷..."
if ! ubinfo /dev/ubi1_0 >/dev/null 2>&1; then
    echo "创建 clash_data 卷..."
    ubimkvol /dev/ubi1 -N clash_data -m
fi

# 4. 挂载分区并进行写入测试
echo "[4/6] 挂载分区并验证写入权限..."
mkdir -p /mnt/clash_storage
if ! mount | grep -q "/mnt/clash_storage"; then
    mount -t ubifs ubi1_0 /mnt/clash_storage
fi

# 核心：确定 MTD30 可以写入
if touch /mnt/clash_storage/.write_test 2>/dev/null; then
    echo "✅ MTD30 写入测试成功！"
    rm /mnt/clash_storage/.write_test
else
    echo "❌ 错误：MTD30 挂载成功但无法写入，请检查分区状态。"
    exit 1
fi

# 5. 迁移 OpenClash 数据
echo "[5/6] 迁移数据并建立软链接..."
[ -f "/etc/init.d/openclash" ] && /etc/init.d/openclash stop 2>/dev/null || true

if [ -d "/etc/openclash" ] && [ ! -L "/etc/openclash" ]; then
    echo "搬家现有配置至 mtd30..."
    cp -a /etc/openclash/* /mnt/clash_storage/ 2>/dev/null || true
    rm -rf /etc/openclash
fi

ln -sf /mnt/clash_storage /etc/openclash
mkdir -p /etc/openclash/core /etc/openclash/config
chmod -R 777 /mnt/clash_storage

# 6. 配置开机自启
echo "[6/6] 配置开机自动挂载..."
if ! grep -q "mtd30" /etc/rc.local; then
    sed -i '/exit 0/i # OpenClash MTD30 Mount\nubiattach -p /dev/mtd30 2>/dev/null\nmount -t ubifs ubi1_0 /mnt/clash_storage' /etc/rc.local
fi

echo "------------------------------------------------"
echo "部署完成！当前 /etc/openclash 空间状态："
df -h /etc/openclash | grep -v Filesystem
echo "------------------------------------------------"
EOF

chmod +x /tmp/setup_clash.sh
/tmp/setup_clash.sh
