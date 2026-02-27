#!/bin/sh

REVISION="2"
REVISION_FILE="/data/utils/fw_manager.revision"

#
# @file    g2hpro_update.sh
# @brief   This script is used to manage program operations,
#          including, but not limited to,
#          1. update firmware.
#
# @author  Niceboy (niceboygithub@github.com)
# @author  Michael (huiwang.zhu@aqara.com)
#
# Copyright (c) 2020~2021 ShenZhen Lumiunited Technology Co., Ltd.
# All rights reserved.
#

#
# Script options.
# -h: helper.
# -u: update.
#
OPTIONS="-h;-u;"

#
# Platforms.
# -a: AIOT.
# -m: MIOT.
#
PLATFORMS="-a;-m"

#
# Updater operations.
# -s: check sign.
# -n: ignore sign.
# -o: original firmware.
#
UPDATER="-s;-n;-o"

#
# Default platform.
# Must in aiot;miot.
#
DEFAULT_PLATFORM="aiot"

#
# Tag files.
#
MODEL_FILE="/data/utils/fw_manager.model"

# store scene file
SCENE_FILE="/res/scene_dat"
IRCTRL_BIN_BK_="/data/IRController.bin"
#
# Product model, support list: AC_P3, AH_M1S, AH_M2.
#
# AC_P3 : Air Condition P3.
# AH_M1S: Aqara Hub M1S.
# AH_M2 : Aqara Hub M2.
#
# note: default is unknow.
#
model=""

#
# Version and md5sum
#
FIRMWARE_URL="https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main"
VERSION="4.5.30_0002.0013"
BOOT_MD5SUM=""
COOR_MD5SUM="344c0c4c51f169996c5f9ea9ac6df00c"
KERNEL_MD5SUM="d8ded1c02d9f1244bc06c7c695a4cc8c"
ROOTFS_MD5SUM="b1bb44e206f68c1ceb5929f8af552618"
MODIFIED_ROOTFS_MD5SUM="22853d9966231e70763bc52e197910ca"

kernel_bin_="$ota_dir_/linux.bin"
rootfs_bin_="$ota_dir_/rootfs.bin"
zbcoor_bin_="$ota_dir_/ControlBridge.bin"
irctrl_bin_="$ota_dir_/IRController.bin"
boot_bin_="$ota_dir_/uboot.bin"
zbcoor_bin_bk_="/data/ControlBridge.bin"

FW_TYPE=1
ROOTFS_PARTITION=''
KERNEL_PARTITION=''
NANDWRITE=/bin/nandwrite
NANDDUMP=/bin/nanddump
#
# Enable debug, 0/1.
#
debug=1

#
sub_ota_dir_="/usr/ota_dir"
# Show green content, in the same way to use as echo.
#
green_echo()
{
    if [ $debug -eq 0 ]; then return; fi

    GREEN="\033[0;32m"; BLACK="\033[0m"
    if [ "$1" = "-n" ]; then echo -en $GREEN$2$BLACK; else echo -e $GREEN$1$BLACK; fi
}

#
# Show red content, in the same way to use as echo.
#
red_echo()
{
	RED="\033[0;31m"; BLACK="\033[0m"
	if [ "$1" = "-n" ]; then echo -en $RED$2$BLACK; else echo -e $RED$1$BLACK; fi
}

#
# Match sub-string.
#
# param $1: string.
# Param $2: sub-string.
#
# return: 1 - matched.
# return: 0 - unmatch.
#
match_substring()
{
	string="$1"; substr="$2"

	case $string in
        *$substr*) return 1 ;;
        *)         return 0 ;;
	esac
}

#
# Convert rom string to number.
# Param: value string.
#
convert_str2int()
{
    local str=$1
    local length=${#str}
    local sum=0; local index=0

    while [ ${index} -lt ${length} ]; do
        let sum=10*sum+${str:${index}:1}
        let index+=1
    done

    echo ${sum}
}

usage_updater()
{
    green_echo "Update firmware."
    green_echo "Usage: fw_manager.sh -u [$UPDATER] [path]."
    green_echo " -s : check sign."
    green_echo " -n : don't check sign."
    green_echo " -m : modified firmware."
    green_echo " -o : original firmware."
}

wait_exit(){
 local flag_exit=0
 local process=$1

    for i in `seq 40`;do
        if [  x"`ps |grep -w $process|grep -v grep`" != x ]; then
            echo "$i wait $process exit!!!"
        else
            echo "exit $process ok"
            flag_exit=1
            break
        fi
        sleep 0.1
    done
    if [ $flag_exit == 0 ]; then
        echo "exit $process error"
    fi

    return $flag_exit
}

wait_property_svr_ok()
{
    for i in `seq 20`;
    do
        sys_name=`agetprop ro.sys.name`
        if [ x"$sys_name" != x ];then
            echo "psvr ok,wait=$i"
            break
        fi
        sleep 0.1
        echo "wait pro svr"
    done
}

#
# Stop AIOT programs.
# Note: We can specifing some programs to keep alive
#       by use of format string: "x;x;x...".
#
# Flag: ha_driven        : d
#       ha_master        : m
#       ha_basis         : b
#       ha_agent         : a
#       property_service : p
#       zigbee_agent     : z
#
# For example: keep ha_basis and ha_master alive: stop_aiot "b;m"
#
stop_aiot()
{
    local d=0; local m=0; local b=0
    local a=0; local p=0; local z=0
    local v=0; local l=0; local c=0
    local re=0; local i=0; local u=0
    local w=0; local rt=0; local h=0

    match_substring "$1" "d"; d=$?
    match_substring "$1" "m"; m=$?
    match_substring "$1" "b"; b=$?
    match_substring "$1" "a"; a=$?
    match_substring "$1" "p"; p=$?
    match_substring "$1" "z"; z=$?
    match_substring "$1" "v"; v=$?
    match_substring "$1" "c"; c=$?
    match_substring "$1" "re"; re=$?
    match_substring "$1" "rt"; rt=$?
    match_substring "$1" "i"; i=$?
    match_substring "$1" "u"; u=$?
    match_substring "$1" "w"; w=$?
    match_substring "$1" "h"; h=$?
    green_echo "d:$d, m:$m, b:$b, a:$a, p:$p, z:$z, v:$v, re:$re, c:$c, i:$i, u:$u, w:$w, h:$h"

    # Stop monitor.
    killall -9 app_monitor.sh

    #
    # Send a signal to programs.
    #
    if [ $d -eq 0 ]; then killall ha_driven        ;fi
    if [ $m -eq 0 ]; then killall ha_master        ;fi
    if [ $h -eq 0 ]; then killall ha_lanbox        ;fi
    if [ $b -eq 0 ]; then killall ha_basis         ;fi
    if [ $a -eq 0 ]; then killall ha_agent         ;fi
    if [ $z -eq 0 ]; then killall zigbee_agent     ;fi
    if [ $l -eq 0 ]; then killall Z3GatewayHost_MQTT ;fi
    if [ $c -eq 0 ]; then killall ppcs ;fi
    if [ $w -eq 0 ]; then killall webrtc ;fi
    if [ $re -eq 0 ]; then killall recorder ;fi
    if [ $rt -eq 0 ]; then killall rtsp ;fi
    # if [ $i -eq 0 ]; then killall ai ;fi
    # if [ $u -eq 0 ]; then killall uvc ;fi
    if [ $v -eq 0 ]; then killall vidicond         ;fi
    if [ $p -eq 0 ]; then killall property_service ;fi

    sleep 1

    #
    # Force to kill programs.
    #
    if [ $d -eq 0 ]; then killall -9 ha_driven        ;fi
    if [ $m -eq 0 ]; then killall -9 ha_master        ;fi
    if [ $h -eq 0 ]; then killall -9 ha_lanbox        ;fi
    if [ $b -eq 0 ]; then killall -9 ha_basis         ;fi
    if [ $a -eq 0 ]; then killall -9 ha_agent         ;fi
    if [ $z -eq 0 ]; then killall -9 zigbee_agent     ;fi
    if [ $l -eq 0 ]; then killall -9 Z3GatewayHost_MQTT ;fi
    if [ $c -eq 0 ]; then killall -9 ppcs ;fi
    if [ $w -eq 0 ]; then killall -9 webrtc ;fi
    if [ $re -eq 0 ]; then killall -9 recorder ;fi
    if [ $rt -eq 0 ]; then killall -9 rtsp ;fi
    # if [ $i -eq 0 ]; then killall -9 ai ;fi
    # if [ $u -eq 0 ]; then killall -9 uvc ;fi
    if [ $v -eq 0 ]; then killall -9 vidicond         ;fi
    if [ $p -eq 0 ]; then killall -9 property_service ;fi
    sleep 4
}

#
# Stop MIOT programs.
# Note: We can specifing some programs to keep alive
#       by use of format string: "x;x;x...".
#
# Flag: mha_basis        : b
#       mha_master       : m
#       homekitserver    : h
#       miio_agent       : g
#       miio_client      : c
#       mzigbee_agent    : z
#       mijia_automation : a
#       property_service : p
#
# For example: keep mha_basis and mha_master alive: stop_miot "b;m"
#
stop_miot()
{
    local b=0; local m=0; local h=0; local g=0
    local c=0; local z=0; local a=0; local p=0

    match_substring "$1" "b"; b=$?
    match_substring "$1" "m"; m=$?
    match_substring "$1" "h"; h=$?
    match_substring "$1" "g"; g=$?
    match_substring "$1" "c"; c=$?
    match_substring "$1" "z"; z=$?
    match_substring "$1" "a"; a=$?
    match_substring "$1" "p"; p=$?

    # Stop monitor.
    killall -9 app_monitor.sh

    #
    # Send a signal to programs.
    #
    killall -9 miio_client_helper_nomqtt.sh
    if [ $a -eq 0 ]; then killall mijia_automation ;fi
    if [ $h -eq 0 ]; then killall homekitserver    ;fi
    if [ $m -eq 0 ]; then killall mha_master       ;fi
    if [ $c -eq 0 ]; then killall miio_client      ;fi
    if [ $b -eq 0 ]; then killall mha_basis        ;fi
    if [ $p -eq 0 ]; then killall property_service ;fi
    if [ $g -eq 0 ]; then killall miio_agent       ;fi
    if [ $z -eq 0 ]; then killall mzigbee_agent    ;fi

    sleep 1

    #
    # Force to kill programs.
    #
    if [ $a -eq 0 ]; then killall -9 mijia_automation ;fi
    if [ $h -eq 0 ]; then killall -9 homekitserver    ;fi
    if [ $m -eq 0 ]; then killall -9 mha_master       ;fi
    if [ $c -eq 0 ]; then killall -9 miio_client      ;fi
    if [ $b -eq 0 ]; then killall -9 mha_basis        ;fi
    if [ $p -eq 0 ]; then killall -9 property_service ;fi
    if [ $g -eq 0 ]; then killall -9 miio_agent       ;fi
    if [ $z -eq 0 ]; then killall -9 mzigbee_agent    ;fi

}

force_stop_unlimited()
{
    killall -9 app_monitor.sh

    # AIOT
    killall -9 ha_master
    killall -9 zigbee_agent
    killall -9 ha_driven
    killall -9 ha_basis
    killall -9 ha_agent
    killall -9 Z3GatewayHost_MQTT
    killall -9 ppcs
    killall -9 webrtc
    killall -9 recorder
    killall -9 rtsp
    # killall -9 ai
    # killall -9 uvc
    killall -9 vidicond
    sleep 2
    # MIOT
    killall -9 miio_client
    killall -9 miio_agent
    killall -9 miio_client_helper_nomqtt.sh
    killall -9 mha_master
    killall -9 mha_basis
    killall -9 mzigbee_agent
    killall -9 mijia_automation
    killall -9 homekitserver
    killall -9 property_service
}

#
# Prepare for update.
# Return value 1 : failed.
# Return value 0 : ok.
#
update_prepare()
{
    ota_dir_="/data/ota_dir/"
    coor_dir_="/data/ota-files/"
    flash_ok_="/data/flash_ok"
    # Clean old firmware directory.
    if [ -d $ota_dir_ ]; then rm $ota_dir_ -rf; fi
    if [ -d $coor_dir_ ]; then rm $coor_dir_ -rf; fi

    # Clean log files.
    rm /tmp/bmlog.txt* -f
    rm /tmp/zblog.txt* -f
    rm /tmp/aulog.txt* -f

    killall -9 app_monitor.sh
    killall -9 ppcs
    killall -9 webrtc
    # killall -9 ai
    killall -9 recorder
    killall -9 rtsp
    # killall -9 uvc
    sleep 2
    killall -9 vidicond
    sleep 3
    if [ `pgrep vidicond` ] ;then
        killall -9 vidicond
        sleep 3
    fi
    echo 3 >/proc/sys/vm/drop_caches; sleep 1

    dfu_pkg_="$1"

    firmwares_="$ota_dir_/lumi_fw.tar"

    boot_bin_="$ota_dir_/boot.bin"
    kernel_bin_="$ota_dir_/kernel"
    rootfs_bin_="$ota_dir_/rootfs.sqfs"
    zbcoor_bin_="$ota_dir_/Network-Co-Processor.ota"
    irctrl_bin_="$ota_dir_/IRController.bin"
    ble_bl_bin_="$ota_dir_/bootloader.gbl"
    ble_app_bin_="$ota_dir_/full.gbl"

    zbcoor_bin_bk_="/data/ControlBridge.bin"
    ble_bl_bin_bk_="/data/bootloader.gbl"
    ble_app_bin_bk_="/data/full.gbl"

    echo "dfu size start"
    local dfusize=28201064
    local memfree=`cat /proc/meminfo | grep MemFree | tr -cd "[0-9]"`
    local romfree=`df | grep ubi0_1 | awk '{print $4}'`

    dfusize_=`convert_str2int "$dfusize"`;
    memfree_=`convert_str2int "$memfree"`; memfree_=$((memfree_*1024))
    romfree_=`convert_str2int "$romfree"`; romfree_=$((romfree_*1024))

    green_echo "Original OTA package : $dfu_pkg_"
    green_echo "Unpack path          : $ota_dir_"
    green_echo "OTA packages size(b) : $dfusize_"
    green_echo "Available ROM size(b): $romfree_"
    green_echo "Available RAM size(b): $memfree_"

    # Check memory space.
    # Failed to get var if romfree_/memfree_ equal zero.
    if [ $romfree_ -gt 0 ] && [ $memfree_ -gt 0 ] &&
       [ $romfree_ -lt $dfusize_ ] && [ $memfree_ -lt $dfusize_ ]; then
        red_echo "Not enough storage available!"
	return 1
    fi

    mkdir $ota_dir_ $coor_dir_

    return 0
}

update_get_packages()
{
    local platform="$1"

    local path="$2"
    local sign="$3"
    local simple_model="G2HPro"
    local current_version=""

    echo "Update to ${VERSION}"
    echo "Get packages, please wait..."

    if [ "x${COOR_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/coor.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/Network-Co-Processor.ota
        [ "$(md5sum /tmp/coor.bin)" != "${COOR_MD5SUM}  /tmp/coor.bin" ] && return 1
    fi

    if [ "x${KERNEL_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/linux.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/kernel_${VERSION}
        [ "$(md5sum /tmp/linux.bin)" != "${KERNEL_MD5SUM}  /tmp/linux.bin" ] && return 1
    fi

    if [ "$FW_TYPE" == "0" ]; then
        if [ "x${ROOTFS_MD5SUM}" != "x" ]; then
            /tmp/curl -s -k -L -o /tmp/rootfs.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/rootfs_${VERSION}.sqfs
            [ "$(md5sum /tmp/rootfs.bin)" != "${ROOTFS_MD5SUM}  /tmp/rootfs.bin" ] && return 1
        fi
    else
        if [ "x${MODIFIED_ROOTFS_MD5SUM}" != "x" ]; then
            /tmp/curl -s -k -L -o /tmp/rootfs.bin ${FIRMWARE_URL}/modified/${simple_model}/${VERSION}/rootfs_${VERSION}_modified.sqfs
            [ "$(md5sum /tmp/rootfs.bin)" != "${MODIFIED_ROOTFS_MD5SUM}  /tmp/rootfs.bin" ] && return 1
        fi
    fi

    echo "Got package done"
    return 0
}

update_clean()
{
    rm -rf "$dfu_pkg_" "$fws_dir_" "$ota_dir_"
    sync;sync;sync; sleep 1
}

#
# Check update status was block or not.
# return value 1: true.
# return value 0: false.
#
update_block()
{
    local result=`agetprop sys.dfu_progress`
    if [ "$result" = "-1" ]; then return 1; fi

    return 0
}

confirm_coor()
{
    zigbee_msnger get_zgb_ver
    sleep 0.1
    local index2=`agetprop sys.coor_update`
    if [ "$index2" != "true" ]
    then
        return 1
    fi
    return 0;
}

update_before_start()
{
    local platform="$1"

    if [ -f "/tmp/coor.bin" ]; then
        mv /tmp/coor.bin $zbcoor_bin_
    fi
    if [ -f "/tmp/linux.bin" ]; then
        hexdump -n 8 -e '16/1 "%02x" "\n"' /tmp/linux.bin > /tmp/kernel_head
        kernel_head=$(cat /tmp/kernel_head | cut -d " " -f 1)
        if [ "x$kernel_head" == "x667773736c6d6c78" ]; then
            dd if=/tmp/linux.bin of=$kernel_bin_ skip=16 bs=1 > /dev/null 2>&1
        else
            mv /tmp/linux.bin $kernel_bin_
        fi
    fi
    if [ -f "/tmp/rootfs.bin" ]; then
        hexdump -n 8 -e '16/1 "%02x" "\n"' /tmp/rootfs.bin > /tmp/rootfs_head
        rootfs_head=$(cat /tmp/rootfs_head | cut -d " " -f 1)
        if [ "x$rootfs_head" == "x667773736c6d7274" ]; then
            dd if=/tmp/rootfs.bin of=$rootfs_bin_ skip=16 bs=1 > /dev/null 2>&1
        else
            mv /tmp/rootfs.bin $rootfs_bin_
        fi
    fi
}

get_kernel_partitions(){

    /etc/fw_printenv | grep bootcmd | awk '{print $4}'
}

get_rootfs_partitions(){

    /etc/fw_printenv | grep bootargs | awk '{print $2}'
}

set_kernel_partitions(){
     if [ "$1" = "KERNEL" ];then
        /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL_BAK 0x500000; dcache on; bootlogo 0 0 0 0; bootm 0x22000000;nand read.e 0x22000000 KERNEL 0x500000; dcache on; bootm 0x22000000"
    else
        /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL 0x500000; dcache on; bootlogo 0 0 0 0; bootm 0x22000000;nand read.e 0x22000000 KERNEL_BAK 0x500000; dcache on; bootm 0x22000000"
    fi

}

set_rootfs_partitions(){
    if [ "$1" = "root=/dev/mtdblock8" ];then
         /etc/fw_setenv bootargs "ubi.mtd=UBI,2048 root=/dev/mtdblock9 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2800000 mtdparts=nand0:768k@1280k(IPL0),384k(IPL_CUST0),384k(IPL_CUST1),384k(UBOOT0),384k(UBOOT1),256k(ENV0),0x500000(KERNEL),0x500000(KERNEL_BAK),0x1000000(rootfs),0x1000000(rootfs_bak),0x100000(factory),0x1000000(res),-(UBI)"
    else
        /etc/fw_setenv bootargs "ubi.mtd=UBI,2048 root=/dev/mtdblock8 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2800000 mtdparts=nand0:768k@1280k(IPL0),384k(IPL_CUST0),384k(IPL_CUST1),384k(UBOOT0),384k(UBOOT1),256k(ENV0),0x500000(KERNEL),0x500000(KERNEL_BAK),0x1000000(rootfs),0x1000000(rootfs_bak),0x100000(factory),0x1000000(res),-(UBI)"
    fi
}

update_start()
{
    local platform="$1"

    local zbcoor_bin_="$ota_dir_/Network-Co-Processor.ota"
    local coor_bin_="$coor_dir_/Network-Co-Processor.ota"

    asetprop sys.dfu_progress 75

    # Update IR-Controller firmware.
    echo "===Update IR-Controller firmware==="
    if [ -f "$irctrl_bin_" ]; then
        if [ "$platform" = "miot" ]; then
            asetprop sys.app_monitor_delay 60
            killall mha_ir
            sleep 2
        fi
        cp $irctrl_bin_ $IRCTRL_BIN_BK_
        ir_ota ttyS3 115200 "$irctrl_bin_"
        # Check result
        update_block; if [ $? -eq 1 ]; then return 1; fi
        rm $IRCTRL_BIN_BK_
    fi

    # Update zigbee-coordinator firmware.
    echo "===Update zigbee-coordinator firmware==="
    local DFU_VER=`agetprop persist.app.dfu_ver`
    local CLOUD_VER=`echo $DFU_VER | cut -d '_' -f 2`
    local LOCAL_VER=`agetprop persist.sys.zb_ver`
    echo "<<<DFU_VER:$DFU_VER, CLOUD_VER:$CLOUD_VER, LOCAL_VER:$LOCAL_VER"
    if [ "$CLOUD_VER" != "$LOCAL_VER" ]; then
        if [ -f "$zbcoor_bin_" ]; then
            mv $zbcoor_bin_ $coor_bin_; sync
            for retry in `seq 3`
            do
                zigbee_msnger zgb_ota "$coor_bin_"
                sleep 4
                # Check result
                confirm_coor
                var=$?
                if [ $var -eq 0 ]; then break; fi
            done
            if [ $var -eq 1 ]; then return 1; fi
            rm -f "$coor_bin_"
        fi
    fi

    # Update uboot.
    echo "===Update uboot==="
    for cnt in `seq 3`
    do
    if [ -f "$boot_bin_" ];then
        flash_erase /dev/mtd0 0 0
        /bin/nandwrite -p /dev/mtd0 $boot_bin_; sync; sleep 0.4
        /bin/nanddump -s 0x0 -l 0x1 -f /tmp/boot_head -p /dev/mtd0
        cat /tmp/boot_head | awk -F ':' '{print $2}' >> /tmp/boot_head0

        hexdump -n 2048 -e '16/1 "%02x" "\n"' $boot_bin_ >> /tmp/boot_head1
        result=`diff -w /tmp/boot_head0 /tmp/boot_head1`
        rm -f /tmp/boot_head0; rm -f /tmp/boot_head1; rm -f /tmp/boot_head
        if [ "$result" = "" ];then break; fi
   fi
   done
   #if [ $cnt -eq 3 ];then return 1; fi
   asetprop sys.dfu_progress 92

    # Update kernel.
    echo "===Update kernel==="
    KERNEL_PARTITION=$(get_kernel_partitions)
    for cnt in `seq 4`
    do
    if [ -f "$kernel_bin_" ];then
        if [ "$KERNEL_PARTITION" = "KERNEL" ];then
	    flash_erase /dev/mtd7 0 0
	    #/bin/nandwrite -p /dev/mtd7 $kernel_bin_; sync; sleep 0.4
            dd if=$kernel_bin_ of=/dev/mtdblock7 bs=5M; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd7
	    cat /tmp/kernel_head | awk -F ':' '{print $2}' >> /tmp/kernel_head0
        else
	    flash_erase /dev/mtd6 0 0
	    #/bin/nandwrite -p /dev/mtd6 $kernel_bin_; sync; sleep 0.4
            dd if=$kernel_bin_ of=/dev/mtdblock6 bs=5M; sync; sleep 0.4
	    /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd6
	    cat /tmp/kernel_head | awk -F ':' '{print $2}' >> /tmp/kernel_head0
        fi

        hexdump -n 2048 -e '16/1 "%02x" "\n"' $kernel_bin_ >> /tmp/kernel_head1
        result=`diff -w /tmp/kernel_head0 /tmp/kernel_head1`
        rm -f /tmp/kernel_head0; rm -f /tmp/kernel_head1; rm -f /tmp/kernel_head
        if [ "$result" = "" ];then break; fi

   fi
   done
   if [ $cnt -eq 4 ];then return 1; fi

    # Update rootfs.
    echo "===Update rootfs==="
    ROOTFS_PARTITION=$(get_rootfs_partitions)
    for cnt in `seq 4`
    do
    if [ -f "$rootfs_bin_" ];then
        if [ "$ROOTFS_PARTITION" = "root=/dev/mtdblock8" ];then
	    flash_erase /dev/mtd9 0 0
	    #/bin/nandwrite -p /dev/mtd9 $rootfs_bin_; sync; sleep 0.4
            dd if=$rootfs_bin_ of=/dev/mtdblock9 bs=16M; sync; sleep 0.4
	    /bin/nanddump -s 0x0 -l 0x1 -f /tmp/rootfs_head -p /dev/mtd9
	    cat /tmp/rootfs_head | awk  -F ':' '{print $2}' >> /tmp/rootfs_head0
	else
            flash_erase /dev/mtd8 0 0
            #/bin/nandwrite -p /dev/mtd8 $rootfs_bin_; sync; sleep 0.4
            dd if=$rootfs_bin_ of=/dev/mtdblock8 bs=16M; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 -f /tmp/rootfs_head -p /dev/mtd8
	    cat /tmp/rootfs_head | awk  -F ':' '{print $2}' >> /tmp/rootfs_head0
	fi
        hexdump -n 2048 -e '16/1 "%02x" "\n"' $rootfs_bin_  >> /tmp/rootfs_head1
        result=`diff -w /tmp/rootfs_head0 /tmp/rootfs_head1`
        rm -f /tmp/rootfs_head0; rm -f /tmp/rootfs_head1; rm -f /tmp/rootfs_head
        if [ "$result" = "" ];then break; fi
    fi
    done

    echo "===Updated all Success==="
    if [ $cnt -eq 4 ];then return 1; fi

    return 0
}

update_failed()
{
    local platform="$1"
    local errmsg="$2"
    local clean="$3"

    green_echo "Update failed, reason: $errmsg"

    if [ "$clean" = "true" ]; then update_clean; fi

}

update_done()
{
    set_kernel_partitions "$KERNEL_PARTITION"
    set_rootfs_partitions "$ROOTFS_PARTITION"
    update_clean
    sleep 7
#    reboot
    green_echo ""
    green_echo "Update Done, Please manually reboot!"
}

usage_helper()
{
    green_echo "Helper to show how to use this script."
    green_echo "Usage: g3_update.sh -h [$OPTIONS]."
    green_echo "  option: $OPTIONS"
    green_echo "  params: params list."
}

#
# Document helper.
#
helper()
{
    local cmd="$1"

    case $cmd in
        -u) usage_updater  ;;

         *) usage_helper   ;;
    esac

    return 0
}

#
# Update firmware.
#
updater()
{
    local sign="0"
    local path="/tmp/fw.tar.gz"

    # Check file existed or not.
    if [ ! -e "/tmp/curl" ]; then update_failed "$platform" "/tmp/curl not found!"; return 1; fi

    # Need check sign?
    if [ "$1" = "-s" ]; then sign="1"; fi

    # original or modified firmware?
    if [ "$1" = "-o" ]; then FW_TYPE="0"; fi
    if [ "$1" = "-m" ]; then FW_TYPE="1"; fi

    local platform=`agetprop persist.sys.cloud`
    if [ "$platform" = "" ]; then platform=$DEFAULT_PLATFORM; fi

    green_echo "platform: $platform, path: $path, sign: $sign, type: $FW_TYPE"

    # Prepare...
    update_prepare "$path"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "Not enough storage available!";
        return 1
    fi

    # Get DFU package and check it.
    update_get_packages "$platform" "$path" "$sign"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "get packages failed!" "true"
        return 1
    fi

    update_before_start "$platform"

    update_start "$platform"
    if [ $? -eq 0 ]; then update_done;
    else update_failed "$platform" "OTA failed!" "true"; fi

    return 0
}

#
# Initial params.
#
initial()
{
    local exit_flag=1

    wait_property_svr_ok

    # Is another script running?
    for i in 2 3 1 0; do
        local info=`ps`
        local this_num=`echo "$info" | grep "$1" | wc -l`

        if [ $this_num -le 1 ]; then exit_flag=0; break; fi

        sleep $i # Waitting...
    done

    if [ $exit_flag -ne 0 ]; then exit 1; fi

    green_echo "$1 revision: $REVISION"

    # Compatible by revision.
    # compatible

    # Set ipv4 local reserved ports.
    echo "1883,54322" > /proc/sys/net/ipv4/ip_local_reserved_ports
    product=`agetprop persist.sys.model`

    # Aqara Camer Hub G2HPro.
    if   [ "$product" = "lumi.camera.acn003" ]; then
        model="AH_G2HPro"
    fi

    green_echo "type: $product, model: $model"

    if [ "$product" != "lumi.camera.acn003" ]; then
        echo "This is not supported G2H PRO and exit!"
        exit 1
    fi
}

#
# Main function.
#
main()
{
    initial ${0##*/}

    local option="$1"

    case $option in
        -h) local cmd="$2"; helper   $cmd ;;

        -u|*) updater $* ;;

    esac

    return $?
}

#
# Run script.
#
main $*; exit $?

