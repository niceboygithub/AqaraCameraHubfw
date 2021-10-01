#!/bin/sh

if [ "$(agetprop ro.sys.model)" != "lumi.gateway.aqcn02" ]; then
    echo "This is not supported E1 and exit!"
    exit 1
fi

cd /tmp

echo "Updating Coor"
/tmp/curl -s -k -L -o /tmp/coor.bin https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/original/E1/3.1.5_0020/Network-Co-Processor.ota
[ "$(md5sum /tmp/coor.bin)" = "59b527769c2ecb2b840967f97b88eaa3  /tmp/coor.bin" ] && zigbee_msnger zgb_ota /tmp/coor.bin

echo "Updating linux kernel"
/tmp/curl -s -k -L -o /tmp/kernel https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/original/E1/3.1.5_0020/kernel_3.1.5_0020
[ "$(md5sum /tmp/kernel)" = "d9b0e0c505bc675543a3400ee2e99103  /tmp/kernel" ] && fw_update.sh /tmp/kernel
echo 3 >/proc/sys/vm/drop_caches; sleep 1; sync

echo "Update root file system"
/tmp/curl -s -k -L -o /tmp/rootfs.sqfs https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/E1/3.1.5_0020/rootfs_3.1.5_0020_modified.sqfs
[ "$(md5sum /tmp/rootfs.sqfs)" = "4f81ef88f1cb70e4fa63decb31e96dd9  /tmp/rootfs.sqfs" ] && fw_update.sh /tmp/rootfs.sqfs
sync; sync
