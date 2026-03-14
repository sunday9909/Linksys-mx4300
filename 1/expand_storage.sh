cat << 'EOF' > /tmp/expand_storage.sh
#!/bin/sh
echo "开始执行扩容脚本..."
# 1. 检查并安装 ubi-utils
if ! command -v ubiattach > /dev/null; then
    echo "正在安装 ubi-utils..."
    opkg update && opkg install ubi-utils
fi

# 2. 定位并清理 mtd30
MTD_DEV=$(grep "app2_data" /proc/mtd | cut -d: -f1)
[ -z "$MTD_DEV" ] && echo "错误: 未找到分区" && exit 1
MTD_NUM=${MTD_DEV#mtd}

ubidetach -p /dev/$MTD_DEV 2>/dev/null
ubiformat /dev/$MTD_DEV -y
ubiattach -p /dev/$MTD_DEV

# 3. 创建逻辑卷
UBI_NUM=$(ubinfo -a | grep -B 1 "mtd$MTD_NUM" | grep "UBI device number" | awk '{print $4}')
ubimkvol /dev/ubi$UBI_NUM -N overlay_new -m

# 4. 同步数据
mkdir -p /tmp/new_overlay
mount -t ubifs ubi${UBI_NUM}_0 /tmp/new_overlay
tar -C /overlay -cf - . | tar -C /tmp/new_overlay -xf -
sync
umount /tmp/new_overlay

# 5. 修改挂载配置
uci -q delete fstab.@mount
uci add fstab mount
uci set fstab.@mount[-1].enabled='1'
uci set fstab.@mount[-1].device="ubi${UBI_NUM}:overlay_new"
uci set fstab.@mount[-1].target='/overlay'
uci commit fstab

echo "扩容完成，5秒后重启生效..."
sleep 5
reboot
EOF

chmod +x /tmp/expand_storage.sh && /tmp/expand_storage.sh
