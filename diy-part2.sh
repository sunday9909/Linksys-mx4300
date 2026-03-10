#!/bin/bash
#
# https://github.com
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 1. 修改默認 IP (可根據需要修改，例如改為 192.168.10.1)
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# 2. 修改主機名 (改為 MX4300)
sed -i 's/ImmortalWrt/MX4300/g' package/base-files/files/bin/config_generate

# 3. 注入自動掛載與擴容腳本 (針對 mtd30 / app2_data 分區)
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-mx4300-storage-setup
#!/bin/sh

# 檢測並關聯 mtd30 (MX4300 閒置的 353MB 分區)
if [ ! -e /dev/ubi1 ]; then
    ubiattach -p /dev/mtd30 || { ubiformat /dev/mtd30 -y && ubiattach -p /dev/mtd30; }
fi

# 創建 UBI 邏輯卷 (如果不存在)
if [ -e /dev/ubi1 ] && [ ! -e /dev/ubi1_0 ]; then
    ubimkvol /dev/ubi1 -N opt_vol -m
fi

# 建立掛載點並掛載
mkdir -p /opt
mount -t ubifs ubi1_0 /opt

# --- 核心優化：將大容量插件數據路徑軟鏈接到 /opt ---
# 遍歷處理 Nikki 和 OpenClash
for app in nikki openclash; do
    mkdir -p /opt/$app
    if [ ! -L "/etc/$app" ]; then
        # 如果原目錄存在且不是鏈接，遷移數據並替換為鏈接
        [ -d "/etc/$app" ] && cp -af /etc/$app/* /opt/$app/ 2>/dev/null && rm -rf /etc/$app
        ln -s /opt/$app /etc/$app
    fi
done

# 修正權限，防止插件下載內核失敗
chmod -R 755 /opt/nikki /opt/openclash

# 寫入 fstab 配置實現開機自動掛載
uci -q batch <<EOM
    set fstab.opt_mount=mount
    set fstab.opt_mount.target='/opt'
    set fstab.opt_mount.device='ubi1_0'
    set fstab.opt_mount.fstype='ubifs'
    set fstab.opt_mount.enabled='1'
    commit fstab
EOM

exit 0
EOF

# 賦予腳本執行權限
chmod +x files/etc/uci-defaults/99-mx4300-storage-setup

# 4. 預設 opkg 軟體包安裝路徑到 /opt (可選)
mkdir -p files/etc
cat << 'EOF' > files/etc/opkg.conf
dest root /
dest ram /tmp
dest opt /opt
lists_dir ext /var/opkg-lists
option overlay_root /overlay
EOF

# 5. 移除自帶主題，強制使用 Edge 主題 (可選)
# sed -i 's/luci-theme-bootstrap/luci-theme-edge/g' feeds/luci/collections/luci/Makefile

exit 0
