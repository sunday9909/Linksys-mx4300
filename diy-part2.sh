#!/bin/bash

# 1. 修改默认 IP
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 2. 修改系统参数 (主机名、时区、日志)
sed -i "s/hostname='.*'/hostname='LINKSYS-MX4300'/g" package/base-files/files/bin/config_generate
sed -i "s/timezone='.*'/timezone='CST-8'/g" package/base-files/files/bin/config_generate
sed -i "s/ttylogin='.*'/ttylogin='0'/g" package/base-files/files/bin/config_generate
sed -i "s/log_size='.*'/log_size='128'/g" package/base-files/files/bin/config_generate
sed -i "s/urandom_seed='.*'/urandom_seed='0'/g" package/base-files/files/bin/config_generate

# 3. 定制 NTP 服务器
sed -i '/set system.ntp.server/d' package/base-files/files/bin/config_generate
sed -i '/add_list system.ntp.server/d' package/base-files/files/bin/config_generate
sed -i "/set system.ntp.enable_server='0'/a \ \ \ \ \ \ \ \ add_list system.ntp.server='ntp1.aliyun.com'\n\t\tadd_list system.ntp.server='time1.google.com'\n\t\tadd_list system.ntp.server='time.cloudflare.com'\n\t\tadd_list system.ntp.server='pool.ntp.org'" package/base-files/files/bin/config_generate

# 4. 修改 DTS：删除 app2_data 分区的只读属性
find target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8174-mx4300.dts -name "ipq8174-mx4300.dts" | xargs sed -i '/label = "app2_data";/,/read-only;/ { /read-only;/d }'
