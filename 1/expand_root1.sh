cat << 'EOF' > /tmp/expand_root.sh
#!/bin/sh

# Linksys MX4300 (LN1301) mtd30 扩容 OpenClash 一键脚本 (修正版)
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

# 1. 检查并安装工具
echo "[1/4] 检查 UBI 工具..."
if ! command -v ubinfo >/dev/null 2>&1; then
    echo "未检测到 UBI 工具，正在尝试安装..."
    opkg update && opkg install kmod-ubi ubi-utils || { echo "安装失败，请检查网络或固件源"; exit 1; }
else
    echo "工具已就绪。"
fi

# 检查 mtd30 是否存在
if ! grep -q "mtd30" /proc/mtd; then
    echo "❌ 错误：未发现 mtd30 分区，请检查设备型号是否匹配！"
    exit 1
fi

# 2. 初始化 mtd30 (清理旧卷并重建)
echo "[2/4] 初始化 mtd30 分区..."
# 尝试卸载可能已挂载的旧卷
if ubiattach -p /dev/mtd30 2>/dev/null || [ $? -eq 17 ]; then
    ubidetach -p /dev/mtd30 2>/dev/null || true
fi

ubiformat /dev/mtd30 -y
ubiattach -p /dev/mtd30
ubimkvol /dev/ubi1 -N root_overlay -m

# 3. 同步数据 (将当前配置迁移到新分区)
echo "[3/4] 迁移当前 Overlay 数据..."
mkdir -p /mnt/new_overlay
mount -t ubifs ubi1_0 /mnt/new_overlay
cp -a /overlay/. /mnt/new_overlay/
sync
umount /mnt/new_overlay

# 4. 写入挂载配置 (fstab)
echo "[4/4] 更新挂载配置..."
# 建议先备份原始配置
[ -f /etc/config/fstab ] && cp /etc/config/fstab /etc/config/fstab.bak

cat << FSTAB > /etc/config/fstab
config global
	option anon_swap '0'
	option anon_mount '0'
	option auto_swap '1'
	option auto_mount '1'
	option check_fs '0'

config mount
	option target '/overlay'
	option device 'ubi1_0'
	option fstype 'ubifs'
	option enabled '1'
FSTAB

echo "------------------------------------------------"
echo "✅ 扩容配置完成！系统将在 3 秒后重启。"
echo "重启后，请运行 'df -h' 确认 /overlay 大小。"
echo "------------------------------------------------"
sleep 3
reboot
EOF

chmod +x /tmp/expand_root.sh
/tmp/expand_root.sh
