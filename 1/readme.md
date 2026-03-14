这份 expand_storage.sh 脚本旨在利用 Linksys MX4300 (LN1301) 内部闲置的 353MB mtd30 分区，将其转换为系统主存储（/overlay），从而彻底解决 OpenWrt 空间不足的问题。
------------------------------
📂 脚本简介与使用说明1. 脚本核心功能

* 自动检测：检查并安装必要的 ubi-utils 工具。
* 格式化分区：将原厂闲置的 mtd30 (app2_data) 转换为 UBI 格式。
* 无损迁移：自动将你现有的所有配置、插件、拨号账号克隆到新分区。
* 静默挂载：修改 fstab 配置，重启后自动启用 350MB 的大容量空间。

2. 准备工作

* 确认设备：仅适用于 Linksys MX4300 / LN1301。
* 网络连接：确保路由器联网（用于脚本开头安装 ubi-utils，如已安装则不联网也可以）。
* 系统备份：虽然脚本会自动迁移数据，但重大分区操作建议先在 Web 界面备份配置。

3. 使用方法（一键指令）
直接在 SSH 终端粘贴以下代码并按回车：

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

4. 扩容后验证
重启后，输入以下命令确认：

* df -h /overlay：Size 字段应显示为 300M+。
* ls /usr/bin：确认你之前安装的插件依然存在。

5. 注意事项（必读）

* 重置说明：如果你执行了 OpenWrt 的“恢复出厂设置”，系统会清空这个新分区的配置，但由于 fstab 还在，它依然会挂载这个 350MB 的分区作为主存储。
* 双系统切换：Linksys 固件有 A/B 分区。如果你通过命令强行切换了启动分区（例如从 mtd21 切换到 mtd23），新系统可能需要重新运行此脚本。

------------------------------
Suggested Next Step
如果在安装 ubi-utils 时遇到 "Signature check failed" 或软件源报错，通常是因为系统时间不准。你需要先运行 ntpd -q -p pool.ntp.org 同步时间吗？

