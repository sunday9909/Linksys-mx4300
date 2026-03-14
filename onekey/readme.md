为了方便你在 Windows (PowerShell) 或 Debian/Linux 终端直接通过 SSH 远程一键完成操作，我将脚本压缩并优化为远程指令模式。
你可以直接复制下面的代码到你的电脑终端执行。
1. Windows (PowerShell) 一键命令
打开 PowerShell，直接粘贴并回车（请将 192.168.1.1 替换为你的路由器 IP）：

ssh root@192.168.1.1 "cat << 'EOF' > /tmp/expand.sh#!/bin/sh
set -e
echo '[1/4] 正在激活 MTD30 分区...'if ! ubiattach -p /dev/mtd30 2>/dev/null; then
    ubiformat /dev/mtd30 -y && ubiattach -p /dev/mtd30
fi
echo '[2/4] 创建存储卷并同步数据...'
ubimkvol /dev/ubi1 -N rootfs_data -m 2>/dev/null || true
mkdir -p /tmp/new_ov
mount -t ubifs ubi1_0 /tmp/new_ov
cp -a /overlay/. /tmp/new_ov/
sync
echo '[3/4] 写入系统启动挂载配置...'
sed -i '/mtd30/d' /etc/rc.local
sed -i '/exit 0/i ubiattach -p /dev/mtd30 2>/dev/null\nmount -t ubifs ubi1_0 /overlay' /etc/rc.local
echo '[4/4] 扩容完成，系统即将重启...'
umount /tmp/new_ov
sleep 2 && reboot
EOF
sh /tmp/expand.sh"

------------------------------
2. Debian / Linux 一键命令
在 Debian 终端执行（同样替换 IP）：

ssh root@192.168.1.1 'sh -c "cat << \"EOF\" > /tmp/expand.sh
#!/bin/sh
set -e
echo \"[1/4] 正在初始化 MTD30...\"
ubiattach -p /dev/mtd30 2>/dev/null || (ubiformat /dev/mtd30 -y && ubiattach -p /dev/mtd30)
ubimkvol /dev/ubi1 -N rootfs_data -m 2>/dev/null || true
echo \"[2/4] 同步当前 /overlay 数据...\"
mkdir -p /tmp/new_ov && mount -t ubifs ubi1_0 /tmp/new_ov
cp -a /overlay/. /tmp/new_ov/ && sync
echo \"[3/4] 修改启动项...\"
sed -i \"/mtd30/d\" /etc/rc.local
sed -i \"/exit 0/i ubiattach -p /dev/mtd30 2>/dev/null\nmount -t ubifs ubi1_0 /overlay\" /etc/rc.local
echo \"[4/4] 扩容成功，重启中...\"
umount /tmp/new_ov && sleep 2 && reboot
EOF
chmod +x /tmp/expand.sh && /tmp/expand.sh"'

------------------------------
📖 脚本使用说明功能介绍
该脚本会在你的 Linksys MX4300 路由器上执行以下自动化流程：

   1. 激活隐藏分区：将 MTD30 (353MB) 格式化为 UBIFS（专为 NAND 闪存设计的系统）。
   2. 数据无损迁移：将你当前所有的路由器设置（拨号信息、插件配置、OpenClash 规则等）完整同步到新分区。
   3. 全局扩容：将该分区挂载为 /overlay。重启后，你的路由器可用空间将从几 MB 直接跃升至 300MB 以上。

如何验证成功？
重启完成后（约 2 分钟），重新 SSH 登录，输入：

* df -h /overlay：看到 Size 为 300M+ 即代表成功。
* 你的 OpenClash 现在可以随意下载各种 Core 和规则，再也不会提示空间不足。

风险提示

* 不要在执行中拔插电源：涉及分区格式化，中途断电可能导致系统配置丢失。
* SSH 密码：运行命令后，终端会提示你输入路由器的 root 密码。

------------------------------


