这是一份为您整理好的 GitHub 风格 README 文档，记录了在 Linksys MX4300 (LN1301) 上利用闲置的 mtd30 (353MB) 分区为 OpenClash 扩容的全过程。
------------------------------
Linksys MX4300 (LN1301) OpenWrt 闪存扩容指南 (OpenClash 专用)
本指南介绍了如何利用 Linksys MX4300 隐藏的 1GB 闪存空间，将闲置的 mtd30 分区挂载并软链接至 OpenClash 目录，彻底解决内核更新空间不足的问题。
1. 硬件与分区概况
Linksys MX4300 拥有双系统分区布局。通过 cat /proc/mtd 可见其分区表，其中最重要的闲置资源为：

* mtd30 (app2_data): 约 353MB (0x16180000)
* 当前运行分区: mtd22 (rootfs) (通过 cat /proc/cmdline 确认)

2. 准备 UBI 存储环境
由于 NAND 闪存特性，需要使用 UBI 管理工具：

# 安装工具
opkg update
opkg install kmod-ubi ubi-utils
# 格式化并关联 mtd30
ubiformat /dev/mtd30
ubiattach -p /dev/mtd30
# 创建名为 "clash_data" 的逻辑卷# -m 表示使用该 UBI 设备的所有剩余空间
ubimkvol /dev/ubi1 -N clash_data -m

3. 挂载与数据迁移
将新创建的卷挂载到系统，并建立软链接重定向 OpenClash 数据。
挂载分区

mkdir -p /mnt/clash_storage
mount -t ubifs ubi1_0 /mnt/clash_storage

迁移 OpenClash (核心步骤)
通过软链接，让 OpenClash 无感使用大容量分区：

# 停止服务
/etc/init.d/openclash stop
# 备份并重定向路径
cp -a /etc/openclash/* /mnt/clash_storage/
rm -rf /etc/openclash
ln -s /mnt/clash_storage /etc/openclash
# 补全必要目录结构
mkdir -p /etc/openclash/core
mkdir -p /etc/openclash/config
chmod -R 777 /etc/openclash

4. 持久化配置 (防止重启丢失)
为了确保重启路由器后分区能自动挂载，编辑 /etc/rc.local：

vi /etc/rc.local
# 在 exit 0 之前添加以下行：
ubiattach -p /dev/mtd30
mount -t ubifs ubi1_0 /mnt/clash_storage

5. 验证状态
执行以下命令确认空间已成功“借调”：

* 查看挂载: df -h /etc/openclash (应显示约 322MiB 可用)
* 测试写入: touch /etc/openclash/core/test_write
* 查看链接: ls -dl /etc/openclash (应显示 -> /mnt/clash_storage)

常见问题处理

* Resource busy: 说明分区已被系统自动关联，直接执行 mount 即可。
* Not found: 如果启动脚本报错，请检查 /etc/init.d/openclash 是否存在，并确保软链接路径正确。
* 权限问题: 下载内核失败请执行 chmod -R 777 /mnt/clash_storage。

------------------------------
完成以上操作后，您现在可以前往 OpenClash 面板无忧下载 Meta 内核及大型 GeoIP 数据库。
需要我为您补充如何利用剩余的 mtd31 分区（约 146MB）做其他用途，或者设置自动清理脚本吗？

