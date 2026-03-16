cat << 'EOF' > /tmp/fix_overlay.sh
#!/bin/sh
set -e

echo "------------------------------------------------"
echo "🛠️  正在修复 Linksys MX4300 存储挂载逻辑..."
echo "------------------------------------------------"

# 1. 清理之前脚本在 rc.local 中插入的冲突代码
echo "[1/4] 清理 rc.local 冗余挂载..."
sed -i '/mtd30/d' /etc/rc.local
sed -i '/ubi1_0/d' /etc/rc.local
sed -i '/clash/d' /etc/rc.local

# 2. 确保 UBI 卷存在并格式化 (如果之前成功了这一步会很快)
echo "[2/4] 检查 UBI 卷状态..."
if ! ubiattach -p /dev/mtd30 2>/dev/null; then
    [ $? -ne 17 ] && ubiformat /dev/mtd30 -y && ubiattach -p /dev/mtd30
fi

if ! ubinfo /dev/ubi1_0 >/dev/null 2>&1; then
    ubimkvol /dev/ubi1 -N rootfs_data -m
fi

# 3. 使用 UCI 配置标准的 fstab 挂载
echo "[3/4] 写入系统级挂载配置 (UCI)..."
# 移除旧的 overlay 配置防止冲突
while uci -q delete fstab.@mount[0]; do :; done

# 添加新的挂载点
uci add fstab mount
uci set fstab.@mount[-1].device='ubi1_0'
uci set fstab.@mount[-1].target='/overlay'
uci set fstab.@mount[-1].fstype='ubifs'
uci set fstab.@mount[-1].options='rw,noatime'
uci set fstab.@mount[-1].enabled='1'
uci commit fstab

# 4. 触发系统同步
echo "[4/4] 同步数据并准备重启..."
mkdir -p /tmp/new_overlay
mount -t ubifs ubi1_0 /tmp/new_overlay
cp -a /overlay/. /tmp/new_overlay/ 2>/dev/null || true
sync
umount /tmp/new_overlay

echo "------------------------------------------------"
echo "✅ 修复完成！"
echo "重启后请运行 'df -h'，观察 'overlayfs:/overlay' 的 Size。"
echo "如果显示为 250MB+，则代表根目录真正扩容成功。"
echo "------------------------------------------------"
sleep 2
reboot
EOF

chmod +x /tmp/fix_overlay.sh
/tmp/fix_overlay.sh
