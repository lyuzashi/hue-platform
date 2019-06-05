#!/usr/bin/env bash
docker run -i -t -u openwrt -w /home/openwrt/sdk -v $PWD:/work yhnw/openwrt-sdk:15.05.1-ar71xx /work/sdk_compile.sh

scp -i ~/.ssh/id_rsa_hue helloworld_1_ar71xx.ipk root@Philips-hue.local:/root
ssh -i ~/.ssh/id_rsa_hue -t root@Philips-hue.local opkg remove helloworld
ssh -i ~/.ssh/id_rsa_hue -t root@Philips-hue.local opkg install --force-reinstall  /root/helloworld_1_ar71xx.ipk 
