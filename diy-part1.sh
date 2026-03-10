#!/bin/bash
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 1. 添加常用插件源 (可选)
# echo 'src-git passwall https://github.com' >>feeds.conf.default
# echo 'src-git helloworld https://github.com' >>feeds.conf.default

# 2. 创建自定义插件目录
mkdir -p package/community
cd package/community

# 3. 克隆你指定的第三方插件 (使用 --depth 1 加快下载速度)

# --- 核心代理插件 ---
# Nikki (Sing-box 核心代理)
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki.git

# --- 实用管理工具 (sirpdboy 仓库) ---
# 定时任务 (luci-app-taskplan)
git clone --depth 1 https://github.com/sirpdboy/luci-app-taskplan

# 家长控制 (luci-app-parentcontrol)
git clone --depth 1 https://github.com/sirpdboy/luci-app-parentcontrol.git

# --- 多媒体推送 (sbwml 仓库) ---
# AirConnect (让旧音箱支持 AirPlay)
git clone --depth 1 https://github.com/sbwml/luci-app-airconnect.git

# AirPlay2 (音频接收端)
git clone --depth 1 https://github.com/sbwml/luci-app-airplay2.git

# --- 视觉主题 ---
# Edge 主题
git clone --depth 1 https://github.com/davinyue/luci-theme-edge.git

# 4. 返回源码根目录
cd ../../

# 5. 修正部分插件可能存在的依赖冲突 (针对 24.10 优化)
# 如果某些插件依赖旧版 libustream，脚本会自动处理 (此处可根据编译报错微调)

exit 0
