cat << 'EOF' > /tmp/expand_overlay.sh
#!/bin/sh

# Linksys MX4300 (LN1301) 全局 /overlay 扩容脚本
set -e

echo "------------------------------------------------"
echo "⚠️  注意：即将将 MTD30 (353MB) 设为系统全局 /overlay"
echo "这会扩展整个路由器的可用空间，建议在配置好基础网络后执行。"
echo "------------------------------------------------"
printf "确认执行并重启路由器？(y/n): "
read confirm
[ "$confirm" != "y" ] && exit 1

# 1. 准备 UBI 分区
echo "[1/5] 初始化 MTD30..."
if ! ubiattach -p /dev/mtd30 2>/dev/null; then
    [ $? -ne 17 ] && ubiformat /dev/mtd30 -y && ubiattach -p /dev/mtd30
fi

# 2. 创建 UBI 卷并格式化
echo "[2/5] 格式化 UBIFS..."
# 如果卷已存在则跳过创建
if ! ubinfo /dev/ubi1_0 >/dev/null 2>&1; then
    ubimkvol /dev/ubi1 -N rootfs_data -m
fi

# 3. 临时挂载并迁移数据
echo "[3/5] 迁移当前配置数据 (防止配置丢失)..."
mkdir -p /tmp/new_overlay
mount -t ubifs ubi1_0 /tmp/new_overlay
# 同步当前 overlay 的所有内容（包括配置、插件）到新分区
cp -a /overlay/. /tmp/new_overlay/
sync

# 4. 写入挂载配置 (fstab)
echo "[4/5] 更新系统挂载表..."
# 这种方法最稳定：直接修改 /etc/config/fstab 或使用 block-mount
# 但针对 Linksys 固件，我们采用更底层的挂载脚本确保优先执行
if ! grep -q "mtd30" /etc/rc.local; then
    # 清理之前可能存在的 OpenClash 挂载逻辑
    sed -i '/mtd30/d' /etc/rc.local
    sed -i '/clash/d' /etc/rc.local
    # 插入全局挂载逻辑
    sed -i '/exit 0/i # Global Overlay Expansion\nubiattach -p /dev/mtd30 2>/dev/null\nmount -t ubifs ubi1_0 /overlay' /etc/rc.local
fi

# 5. 扫尾
umount /tmp/new_overlay
echo "------------------------------------------------"
echo "✅ 扩容完成！路由器将在 3 秒后重启以应用更改。"
echo "重启后，运行 'df -h' 看到 /overlay 大约为 300MB+ 即成功。"
echo "------------------------------------------------"
sleep 3
reboot
EOF

chmod +x /tmp/expand_overlay.sh
/tmp/expand_overlay.sh
