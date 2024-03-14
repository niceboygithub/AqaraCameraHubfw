#!/bin/sh

REVISION="2"
REVISION_FILE="/data/utils/fw_manager.revision"

#
# @file    e1_update.sh
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
# Product model, support list: AH_E1
#
# AH_E1 : Aqara Hub E1.
#
# note: default is unknow.
#
model=""


#
# Version and md5sum
#
FIRMWARE_URL="https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main"
VERSION="4.0.4_0006_4.1.0_0003"
BOOT_MD5SUM=""
COOR_MD5SUM="27235ff94cbfa6e63a8d426bb7fa2882"
KERNEL_MD5SUM="d3e39d43b306188cbd1e6f18d7b71a18"
ROOTFS_MD5SUM="da608d1d6ca7ad083176eea010578af7"
MODIFIED_ROOTFS_MD5SUM="09af57cda70e636cc13f39b5a64c9ff1"

FW_TYPE=1
#
# Enable debug, 0/1.
#
debug=1

#
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

wait_property_svr_ok()
{
    for i in `seq 20`;
    do
        sys_name=`agetprop ro.sys.name`
        if [ x"$sys_name" != x ];then
            echo "psvr ok,wait=$i"
            break;
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
    local l=0; #host
    local h=0; #ha_lanbox
    local t=0;

    match_substring "$1" "d"; d=$?
    match_substring "$1" "m"; m=$?
    match_substring "$1" "b"; b=$?
    match_substring "$1" "a"; a=$?
    match_substring "$1" "p"; p=$?
    match_substring "$1" "z"; z=$?
    match_substring "$1" "l"; l=$?
    match_substring "$1" "h"; h=$?
    match_substring "$1" "t"; t=$?

    green_echo "d:$d, m:$m, b:$b, a:$a, p:$p, z:$z, l:$l, h:$h, t:$t"

    # Stop monitor.
    killall -9 app_monitor.sh

    sleep 1.5

    #
    # Send a signal to programs.
    #
    if [ $t -eq 0 ]; then killall ha_matter        ;fi
    if [ $d -eq 0 ]; then killall ha_driven        ;fi
    if [ $m -eq 0 ]; then killall ha_master        ;fi
    if [ $b -eq 0 ]; then killall ha_basis         ;fi
    if [ $a -eq 0 ]; then killall ha_agent         ;fi
    if [ $p -eq 0 ]; then killall property_service ;fi
    if [ $z -eq 0 ]; then killall zigbee_agent     ;fi
    if [ $l -eq 0 ]; then killall Z3GatewayHost_MQTT ;fi
    if [ $h -eq 0 ]; then killall ha_lanbox        ;fi

    sleep 1

    #
    # Force to kill programs.
    #
    if [ $t -eq 0 ]; then killall -9 ha_matter        ;fi
    if [ $d -eq 0 ]; then killall -9 ha_driven        ;fi
    if [ $m -eq 0 ]; then killall -9 ha_master        ;fi
    if [ $b -eq 0 ]; then killall -9 ha_basis         ;fi
    if [ $a -eq 0 ]; then killall -9 ha_agent         ;fi
    if [ $p -eq 0 ]; then killall -9 property_service ;fi
    if [ $z -eq 0 ]; then killall -9 zigbee_agent     ;fi
    if [ $l -eq 0 ]; then killall -9 Z3GatewayHost_MQTT ;fi
    if [ $h -eq 0 ]; then killall -9 ha_lanbox        ;fi
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
    local l=0;

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

    sleep 0.2

    # Stop syslogd
    killall syslogd

    #
    # Send a signal to programs.
    #
    killall -q aiot_switcher
    killall -9 miio_client_helper_nomqtt.sh
    if [ $a -eq 0 ]; then killall mijia_automation ;fi
    if [ $h -eq 0 ]; then killall homekitserver    ;fi
    if [ $m -eq 0 ]; then killall mha_master       ;fi
    if [ $c -eq 0 ]; then killall miio_client      ;fi
    if [ $b -eq 0 ]; then killall mha_basis        ;fi
    if [ $p -eq 0 ]; then killall property_service ;fi
    if [ $g -eq 0 ]; then killall miio_agent       ;fi
    if [ $z -eq 0 ]; then killall mzigbee_agent    ;fi
    if [ $l -eq 0 ]; then killall mZ3GatewayHost_MQTT ;fi

    # P3 programs.
    if [ "$model" = "AC_P3" ]; then killall mha_ir ;fi

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
    if [ $l -eq 0 ]; then killall -9 mZ3GatewayHost_MQTT ;fi

}

#
# Prepare for update.
# Return value 1 : failed.
# Return value 0 : ok.
#
update_prepare()
{
    ota_dir_="/tmp/ota_dir"
    coor_dir_="/data/ota-files"
    fws_dir_="/data/ota_dir"

    # Clean old firmware directory.
    if [ -d $fws_dir_ ]; then rm $fws_dir_ -rf; fi
    if [ -d $coor_dir_ ]; then rm $coor_dir_ -rf; fi
    if [ -d $ota_dir_ ]; then rm $ota_dir_ -rf; fi

    # Clean log files.
    rm /tmp/bmlog.txt* -f
    rm /tmp/zblog.txt* -f
    rm /tmp/aulog.txt* -f

    killall -9 app_monitor.sh
    echo 3 >/proc/sys/vm/drop_caches; sleep 1

    firmwares_="$fws_dir_/lumi_fw.tar"

    boot_bin_="$ota_dir_/boot.bin"
    kernel_bin_="$ota_dir_/kernel"
    rootfs_bin_="$ota_dir_/rootfs.sqfs"

    irctrl_bin_="$ota_dir_/IRController.bin"
    ble_bl_bin_="$ota_dir_/bootloader.gbl"
    ble_app_bin_="$ota_dir_/full.gbl"


    ble_bl_bin_bk_="/data/bootloader.gbl"
    ble_app_bin_bk_="/data/full.gbl"

    local dfusize=16384
    local memfree=`cat /proc/meminfo | grep MemFree | tr -cd "[0-9]"`
    local romfree=`df | grep ubi0:data  | awk '{print $4}'`

    dfusize_=`convert_str2int "$dfusize"`
    memfree_=`convert_str2int "$memfree"`
    romfree_=`convert_str2int "$romfree"`

    green_echo "Unpack path          : $ota_dir_"
    green_echo "Firmware path        : $fws_dir_"
    green_echo "Available ROM size(kb): $romfree_"
    green_echo "Available RAM size(kb): $memfree_"

    # Check memory space.
    # Failed to get var if romfree_/memfree_ equal zero.
    if [[ $romfree_ -lt $dfusize_ ]] || [[ $memfree_ -lt $dfusize_ ]]; then
        red_echo "Not enough storage available!"
        return 1
    fi

    mkdir -p $fws_dir_ $coor_dir_ $ota_dir_

    return 0
}

update_get_packages()
{
    local simple_model="E1"
    local platform="$1"

    local path="$2"
    local sign="$3"

    echo "Update to ${VERSION}"
    echo "Get packages, please wait..."
    if [ "x${BOOT_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/boot.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/boot.bin
        [ "$(md5sum /tmp/boot.bin)" != "${BOOT_MD5SUM}  /tmp/boot.bin" ] && return 1
    fi

    if [ "x${COOR_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/coor.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/Network-Co-Processor.ota
        [ "$(md5sum /tmp/coor.bin)" != "${COOR_MD5SUM}  /tmp/coor.bin" ] && return 1
    fi

    if [ "x${KERNEL_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/kernel ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/kernel_${VERSION}
        [ "$(md5sum /tmp/kernel)" != "${KERNEL_MD5SUM}  /tmp/kernel" ] && return 1
    fi

    if [ "$FW_TYPE" == "0" ]; then
        if [ "x${ROOTFS_MD5SUM}" != "x" ]; then
            /tmp/curl -s -k -L -o /tmp/rootfs.sqfs ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/rootfs_${VERSION}.sqfs
            [ "$(md5sum /tmp/rootfs.sqfs)" != "${ROOTFS_MD5SUM}  /tmp/rootfs.sqfs" ] && return 1
        fi
    else
        if [ "x${MODIFIED_ROOTFS_MD5SUM}" != "x" ]; then
            /tmp/curl -s -k -L -o /tmp/rootfs.sqfs ${FIRMWARE_URL}/modified/${simple_model}/${VERSION}/rootfs_${VERSION}_modified.sqfs
            [ "$(md5sum /tmp/rootfs.sqfs)" != "${MODIFIED_ROOTFS_MD5SUM}  /tmp/rootfs.sqfs" ] && return 1
        fi
    fi

    echo "Got package done"
    return 0
}

update_clean()
{
    rm -rf "$fws_dir_" "$ota_dir_"
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

    if [ -f "/tmp/boot.bin" ]; then
        mv /tmp/boot.bin "$ota_dir_"
    fi
    if [ -f "/tmp/coor.bin" ]; then
        mv /tmp/coor.bin "$ota_dir_"
    fi
    if [ -f "/tmp/kernel" ]; then
        mv /tmp/kernel "$ota_dir_"
    fi
    if [ -f "/tmp/rootfs.sqfs" ]; then
        mv /tmp/rootfs.sqfs "$ota_dir_"
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
        /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL 0x500000; dcache on ; bootlogo 0 0 0 0; bootm 0x22000000;nand read.e 0x22000000 KERNEL_BAK 0x500000; dcache on ; bootm 0x22000000"
    fi
}

set_rootfs_partitions(){
    if [ "$1" = "root=/dev/mtdblock6" ];then
        if [ -c /dev/mtd9 ];then
            /etc/fw_setenv bootargs "ubi.mtd=UBI,2048 root=/dev/mtdblock7 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x3FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x0000000 cma=2M mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x3300000,max_end_off=0x3600000 mtdparts=nand0:1536k@1280k(BOOT0),1536k(BOOT1),384k(ENV),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),2m(RES),-(UBI)"
        else
            /etc/fw_setenv bootargs "ubi.mtd=UBI,2048 root=/dev/mtdblock7 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x3FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x0000000 cma=2M mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x3300000,max_end_off=0x3600000 mtdparts=nand0:1536k@1280k(BOOT0),1536k(BOOT1),384k(ENV),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),-(UBI)"
        fi
    else
        if [ -c /dev/mtd9 ];then
            /etc/fw_setenv bootargs "ubi.mtd=UBI,2048 root=/dev/mtdblock6 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x3FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x0000000 cma=2M mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x3300000,max_end_off=0x3600000 mtdparts=nand0:1536k@1280k(BOOT0),1536k(BOOT1),384k(ENV),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),2m(RES),-(UBI)"
        else
            /etc/fw_setenv bootargs "ubi.mtd=UBI,2048 root=/dev/mtdblock6 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x3FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x0000000 cma=2M mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x3300000,max_end_off=0x3600000 mtdparts=nand0:1536k@1280k(BOOT0),1536k(BOOT1),384k(ENV),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),-(UBI)"
        fi
    fi
}

set_def_env(){
    /etc/fw_setenv mtdparts 'mtdparts=nand0:1536k@1280k(BOOT0),1536k(BOOT1),384k(ENV),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),2m(RES),-(UBI)'
    /etc/fw_setenv bootargs "ubi.mtd=UBI,2048 root=/dev/mtdblock6 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x3FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x0000000 cma=2M mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x3300000,max_end_off=0x3600000 mtdparts=nand0:1536k@1280k(BOOT0),1536k(BOOT1),384k(ENV),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),2m(RES),-(UBI)"
    /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL 0x500000; dcache on ; bootlogo 0 0 0 0; bootm 0x22000000;nand read.e 0x22000000 KERNEL_BAK 0x500000; dcache on ; bootm 0x22000000"
}

check_env(){
    local err_crc=`/etc/fw_printenv 2>&1 | grep "Bad CRC"`
    if [ x"$err_crc" != x ];then
        red_echo "last env error,set default env"
        set_def_env
    else
        echo "env right"
    fi
}

update_start()
{
    local platform="$1"
    local coor_bin_name=`echo /tmp/ota_dir/*.ota | cut -d '/' -f 4`
    local zbcoor_bin_=/tmp/ota_dir/$coor_bin_name
    local coor_bin_=/data/ota-files/$coor_bin_name

    # Update IR-Controller firmware.
    echo "===Update IR-Controller==="
    if [ -f "$irctrl_bin_" ]; then
        if [ "$platform" = "miot" ]; then
            asetprop sys.app_monitor_delay 60
            killall mha_ir
            sleep 2
        fi

        ir_ota ttyS2 115200 "$irctrl_bin_"
        # Check result
        update_block; if [ $? -eq 1 ]; then return 1; fi
    fi

    # Update zigbee-coordinator firmware.
    echo "===Update zigbee-coordinator==="
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

    # Update uboot.
    echo "===Update uboot==="
    for cnt in `seq 4`
    do
    if [ -f "$boot_bin_" ];then
        flash_erase /dev/mtd0 0 0
        /bin/nandwrite -p /dev/mtd0 $boot_bin_; sync; sleep 0.4
        /bin/nanddump -s 0x0 -l 0x1 --bb=dumpbad -f /tmp/boot_head -p /dev/mtd0
        cat /tmp/boot_head | awk -F ':' '{print $2}' >> /tmp/boot_head0

        hexdump -n 2048 -e '16/1 "%02x" "\n"' $boot_bin_ >> /tmp/boot_head1
        result=`diff -w /tmp/boot_head0 /tmp/boot_head1`
        rm -f /tmp/boot_head0; rm -f /tmp/boot_head1; rm -f /tmp/boot_head
        if [ "$result" = "" ];then break; fi
   fi
   done
   #if [ $cnt -eq 4 ];then return 1; fi

    # Update kernel.
    echo "===Update kernel==="
    KERNEL_PARTITION=$(get_kernel_partitions)
    for cnt in `seq 4`
    do
    if [ -f "$kernel_bin_" ];then
        if [ "$KERNEL_PARTITION" = "KERNEL" ];then
            flash_erase /dev/mtd5 0 0
            /bin/nandwrite -p /dev/mtd5 $kernel_bin_; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd5
            cat /tmp/kernel_head | awk -F ':' '{print $2}' >> /tmp/kernel_head0
        else
            flash_erase /dev/mtd4 0 0
            /bin/nandwrite -p /dev/mtd4 $kernel_bin_; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd4
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
        if [ "$ROOTFS_PARTITION" = "root=/dev/mtdblock6" ];then
            flash_erase /dev/mtd7 0 0
            /bin/nandwrite -p /dev/mtd7 $rootfs_bin_; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 --bb=dumpbad -f /tmp/rootfs_head -p /dev/mtd7
            cat /tmp/rootfs_head | awk  -F ':' '{print $2}' >> /tmp/rootfs_head0
        else
            flash_erase /dev/mtd6 0 0
            /bin/nandwrite -p /dev/mtd6 $rootfs_bin_; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 --bb=dumpbad -f /tmp/rootfs_head -p /dev/mtd6
            cat /tmp/rootfs_head | awk  -F ':' '{print $2}' >> /tmp/rootfs_head0
        fi
        hexdump -n 2048 -e '16/1 "%02x" "\n"' $rootfs_bin_  >> /tmp/rootfs_head1
        result=`diff -w /tmp/rootfs_head0 /tmp/rootfs_head1`
        rm -f /tmp/rootfs_head0; rm -f /tmp/rootfs_head1; rm -f /tmp/rootfs_head
        if [ "$result" = "" ];then break; fi
    fi
    done

    if [ $cnt -eq 4 ];then return 1; fi
    echo "===Update ALL Success==="

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
    green_echo "Usage: e1_update.sh -h [$OPTIONS]."
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

#ota state to normal state
ota_recor_nor()
{
    app_monitor.sh &
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

    green_echo "platform: $platform, path: $path, sign: $sign"

    # Prepare...
    update_prepare "$path"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "Not enough storage available!";
        ota_recor_nor
        return 1
    fi

    # Get DFU package and check it.
    update_get_packages "$platform" "$path" "$sign"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "getpack failed!" "true"
        ota_recor_nor
        return 1
    fi

    update_before_start "$platform"

    update_start "$platform"
    if [ $? -eq 0 ]; then
        update_done
    else update_failed "$platform" "OTA failed!" "true"
        ota_recor_nor
    fi

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

    product=`agetprop ro.sys.model`
    model="AH_E1"

    sync

    green_echo "type: $product, model: $model"

    if [ "$product" != "lumi.gateway.aqcn02" ]; then
        red_echo "This is not supported E1 and exit!"
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
