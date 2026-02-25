#!/bin/sh

REVISION="2"
REVISION_FILE="/data/utils/fw_manager.revision"

#
# @file    m100_update.sh
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
# Product model, support list: AH_M100
#
# AH_M100 : Aqara Hub M100.
#
# note: default is unknow.
#
model=""


#
# Version and md5sum
#
FIRMWARE_URL="https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main"
VERSION="4.5.30_0013.0017"
RCP_SPI_OTA_FILENAME="rcp-spi-802154-512-v0017.gbl"
BOOT_MD5SUM=""
COOR_MD5SUM=""
RCP_SPI_MD5SUM="dd483215970fd81661575231fa0241af"
KERNEL_MD5SUM="dffeb6627b9fcfc5bc0b4552db9077fc"
ROOTFS_MD5SUM="c5600fe4d63023147d2f744c8909af03"
MODIFIED_ROOTFS_MD5SUM="c079b657455a1f8ed0d45deca5985f99"

FW_TYPE=1
#
# Enable debug, 0/1.
#
debug=1

#
# zigbee ic type(MG21/Ti2652/NXP5189).
#
ZIGBEE_IC="Ti2652"
# ZIGBEE_IC="MG21"
# TI zigbee ic type
CC2652P1="0015"
CC1352P7="0026"
CC2652P7="0028"

ota_dir_="/data/ota_unpack"
coor_dir_="/data/ota-files"
fws_dir_="/data/ota_dir"
_ota_bak_dir=/data/ota-bak

#
# Show green content, in the same way to use as echo.
#
green_echo() {
    if [ $debug -eq 0 ]; then return; fi

    GREEN="\033[0;32m"
    BLACK="\033[0m"
    if [ "$1" = "-n" ]; then echo -en $GREEN$2$BLACK; else echo -e $GREEN$1$BLACK; fi
}

#
# Show red content, in the same way to use as echo.
#
red_echo() {
    RED="\033[0;31m"
    BLACK="\033[0m"
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
match_substring() {
    string="$1"
    substr="$2"

    case $string in
    *$substr*) return 1 ;;
    *) return 0 ;;
    esac
}

#
# Convert rom string to number.
# Param: value string.
#
convert_str2int() {
    local str=$1
    local length=${#str}
    local sum=0
    local index=0

    while [ ${index} -lt ${length} ]; do
        let sum=10*sum+${str:${index}:1}
        let index+=1
    done

    echo ${sum}
}

wait_property_svr_ok() {
    for i in $(seq 10); do
        sys_name=$(agetprop ro.sys.name)
        if [ x"$sys_name" != x ]; then
            echo "kvdb ok,wait=$i"
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
stop_aiot() {
    local d=0
    local m=0
    local b=0
    local a=0
    local p=0
    local z=0
    local l=0
    local s=0
    local x=0
    local t=0
    local o=0
    local r=0

    local ble_supported=$(agetprop persist.sys.ble_supported)

    match_substring "$1" "d"
    d=$?
    match_substring "$1" "m"
    m=$?
    match_substring "$1" "b"
    b=$?
    match_substring "$1" "a"
    a=$?
    match_substring "$1" "p"
    p=$?
    match_substring "$1" "z"
    z=$?
    match_substring "$1" "s"
    s=$?
    match_substring "$1" "x"
    x=$?
    match_substring "$1" "t";
    t=$?
    match_substring "$1" "o";
    o=$?
    match_substring "$1" "r";
    r=$?

    green_echo "d:$d, m:$m, b:$b, a:$a, p:$p, z:$z"

    # Stop monitor.
    killall -9 app_monitor.sh

    sleep 1.5

    #for TI coordinator end
    # /bin/ti_linux_host/end.sh

    #
    # Send a signal to programs.
    #
    if [ $r -eq 0 ]; then killall matter_broker; fi
    if [ $t -eq 0 ]; then killall ha_matter; fi
    if [ $d -eq 0 ]; then killall ha_driven; fi
    if [ $m -eq 0 ]; then killall ha_master; fi
    if [ $b -eq 0 ]; then killall ha_basis; fi
    if [ $a -eq 0 ]; then killall ha_agent; fi
    if [ $p -eq 0 ]; then killall property_service; fi
    if [ $z -eq 0 ]; then killall zigbee_agent; fi
    if [ $l -eq 0 ]; then killall Z3GatewayHost_MQTT; fi
    # if [ $s -eq 0 ]; then killall ha_lanstore; fi
    if [ $x -eq 0 ]; then killall ha_lanbox; fi
    if [ $o -eq 0 ]; then killall otbr-agent;fi

    killall Z3Gateway
    killall zigbeed
    killall socat
    killall cpcd


    # killall ha_central

    if [ "true" = "$ble_supported" ];then
        ps | grep "ble_agent\|bluetoothd" | grep -v grep | awk '{print $1}' | xargs -r kill
    fi
    sleep 1

    #
    # Force to kill programs.
    #
    if [ $r -eq 0 ]; then killall -9 matter_broker; fi
    if [ $t -eq 0 ]; then killall -9 ha_matter; fi
    if [ $d -eq 0 ]; then killall -9 ha_driven; fi
    if [ $m -eq 0 ]; then killall -9 ha_master; fi
    if [ $b -eq 0 ]; then killall -9 ha_basis; fi
    if [ $a -eq 0 ]; then killall -9 ha_agent; fi
    if [ $p -eq 0 ]; then killall -9 property_service; fi
    if [ $z -eq 0 ]; then killall -9 zigbee_agent; fi
    if [ $l -eq 0 ]; then killall -9 Z3GatewayHost_MQTT; fi
    # if [ $s -eq 0 ]; then killall -9 ha_lanstore; fi
    if [ $x -eq 0 ]; then killall -9 ha_lanbox; fi
    if [ $o -eq 0 ]; then killall -9 otbr-agent;fi
    killall -9 Z3Gateway
    killall -9 zigbeed
    killall -9 socat
    killall -9 cpcd

    # killall -9 ha_central

    if [ "true" = "$ble_supported" ];then
        ps | grep "ble_agent\|bluetoothd" | grep -v grep | awk '{print $1}' | xargs -r kill -9
    fi
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
stop_miot() {
    local b=0
    local m=0
    local h=0
    local g=0
    local c=0
    local z=0
    local a=0
    local p=0
    local l=0

    match_substring "$1" "b"
    b=$?
    match_substring "$1" "m"
    m=$?
    match_substring "$1" "h"
    h=$?
    match_substring "$1" "g"
    g=$?
    match_substring "$1" "c"
    c=$?
    match_substring "$1" "z"
    z=$?
    match_substring "$1" "a"
    a=$?
    match_substring "$1" "p"
    p=$?

    # Stop monitor.
    killall -9 app_monitor.sh

    sleep 1.5

    #for TI coordinator end
    # /bin/ti_linux_host/end.sh

    #
    # Send a signal to programs.
    #
    killall -9 miio_client_helper_nomqtt.sh
    if [ $a -eq 0 ]; then killall mijia_automation; fi
    if [ $h -eq 0 ]; then killall homekitserver; fi
    if [ $m -eq 0 ]; then killall mha_master; fi
    if [ $c -eq 0 ]; then killall miio_client; fi
    if [ $b -eq 0 ]; then killall mha_basis; fi
    if [ $p -eq 0 ]; then killall property_service; fi
    if [ $g -eq 0 ]; then killall miio_agent; fi
    if [ $z -eq 0 ]; then killall mzigbee_agent; fi
    if [ $l -eq 0 ]; then killall mZ3GatewayHost_MQTT; fi

    # P3 programs.
    if [ "$model" = "AC_P3" ]; then killall mha_ir; fi

    sleep 1

    #
    # Force to kill programs.
    #
    if [ $a -eq 0 ]; then killall -9 mijia_automation; fi
    if [ $h -eq 0 ]; then killall -9 homekitserver; fi
    if [ $m -eq 0 ]; then killall -9 mha_master; fi
    if [ $c -eq 0 ]; then killall -9 miio_client; fi
    if [ $b -eq 0 ]; then killall -9 mha_basis; fi
    if [ $p -eq 0 ]; then killall -9 property_service; fi
    if [ $g -eq 0 ]; then killall -9 miio_agent; fi
    if [ $z -eq 0 ]; then killall -9 mzigbee_agent; fi
    if [ $l -eq 0 ]; then killall -9 mZ3GatewayHost_MQTT; fi

    # P3 programs.
    if [ "$model" = "AC_P3" ]; then killall -9 mha_ir; fi
}


#
# Prepare for update.
# Return value 1 : failed.
# Return value 0 : ok.
#
update_prepare() {
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
    rm /tmp/malog.txt* -f
    rm /tmp/mblog.txt* -f

    killall -9 app_monitor.sh
    kill_otbr

    echo 3 >/proc/sys/vm/drop_caches
    sleep 1

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
    local memfree=$(cat /proc/meminfo | grep MemFree | tr -cd "[0-9]")
    local romfree=$(df | grep data | awk '{print $4}')

    dfusize_=$(convert_str2int "$dfusize")
    memfree_=$(convert_str2int "$memfree")
    romfree_=$(convert_str2int "$romfree")

    green_echo "Unpack path          : $ota_dir_"
    green_echo "Firmware path        : $fws_dir_"
    green_echo "OTA packages size(kb) : $dfusize_"
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
    local simple_model="M100"
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

    if [ "x${RCP_SPI_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/rcp-spi-802154-512.gbl ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/${RCP_SPI_OTA_FILENAME}
        [ "$(md5sum /tmp/rcp-spi-802154-512.gbl)" != "${RCP_SPI_MD5SUM}  /tmp/rcp-spi-802154-512.gbl" ] && return 1
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
    if [ -f "/tmp/rcp-spi-802154-512.gbl" ]; then
        mv /tmp/rcp-spi-802154-512.gbl "$ota_dir_"
    fi
    if [ -f "/tmp/kernel" ]; then
        mv /tmp/kernel "$ota_dir_"
    fi
    if [ -f "/tmp/rootfs.sqfs" ]; then
        mv /tmp/rootfs.sqfs "$ota_dir_"
    fi
}


get_kernel_partitions()
{
    /etc/fw_printenv | grep bootcmd | awk '{print $4}'
}

get_rootfs_partitions()
{

    cat /proc/cmdline | grep mtdblock7
}

set_kernel_partitions()
{
    if [ "$1" = "KERNEL" ];then
        /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL_BAK 0x400000; dcache on;bootm 0x22000000;nand read.e 0x22000000 KERNEL 0x400000; dcache on; bootm 0x22000000"
    else
        /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL 0x400000; dcache on;  bootm 0x22000000;nand read.e 0x22000000 KERNEL_BAK 0x400000; dcache on; bootm 0x22000000"
    fi
}

set_rootfs_partitions(){

    if [ x"$1" != x ];then
        /etc/fw_setenv bootargs "root=/dev/mtdblock8 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2B0000 cma=2M highres=on mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x7C00000,max_end_off=0x7F00000 mtdparts=nand0:1664k@1280k(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),4m(KERNEL),4m(KERNEL_BAK),18m(rootfs),18m(rootfs_bak),1m(factory),18m(RES),-(UBI)"
    else
        /etc/fw_setenv bootargs "root=/dev/mtdblock7 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2B0000 cma=2M highres=on mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x7C00000,max_end_off=0x7F00000 mtdparts=nand0:1664k@1280k(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),4m(KERNEL),4m(KERNEL_BAK),18m(rootfs),18m(rootfs_bak),1m(factory),18m(RES),-(UBI)"
    fi
}

set_def_env(){
    /etc/fw_setenv mtdparts 'mtdparts=nand0:1664k@1280k(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),4m(KERNEL),4m(KERNEL_BAK),18m(rootfs),18m(rootfs_bak),1m(factory),18m(RES),-(UBI)'
    /etc/fw_setenv bootargs "root=/dev/mtdblock7 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2B0000 cma=2M highres=on mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x7C00000,max_end_off=0x7F00000 mtdparts=nand0:1664k@1280k(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),4m(KERNEL),4m(KERNEL_BAK),18m(rootfs),18m(rootfs_bak),1m(factory),18m(RES),-(UBI)"
    /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL 0x400000; dcache on;  bootm 0x22000000;nand read.e 0x22000000 KERNEL_BAK 0x400000; dcache on; bootm 0x22000000"
}



get_coor_file_ver() {
    ver=$(echo $1 | cut -d "_" -f 4)
    echo $ver
}


confirm_coor() {
    local ver_need=$1
    zigbee_msnger get_zgb_ver
    sleep 0.1
    local index2=$(agetprop sys.coor_update)
    if [ "$index2" != "true" ]; then
        return 1
    else
        # check ver
        local ver=$(agetprop persist.sys.zb_ver)
        if [ "$ver_need" = "$ver" ]; then
            echo "same ver"
            return 0
        else
            red_echo "diff ver"
            echo "need ver:$ver_need,curr ver:$ver"
        fi
    fi
    return 1
}

coordinator_ota() {
    return 0
    # Update zigbee-coordinator firmware.
    local zigbee_supported="true" #$(agetprop persist.sys.zigbee_supported)
    if [ "$zigbee_supported" != "true" ]; then
        echo "no support zigbee"
        return 0
    fi
    echo "===Update zigbee-coordinator==="
    local path=$1

    if [ -z "$path" ] || [ ! -f "$path" ]; then
        echo "no coordinator ota file:$path"
        return 0
    fi

    # local bakfile=$zbcoor_bin_bk_dir_/$(basename $1)

    # if [ "$path" != "$bakfile" ]; then
    #     mkdir -p /data/ota_bak
    #     cp $path $bakfile -fv
    #     echo "bakfile:$bakfile"
    #     sync
    # fi

    local CLOUD_VER=$(basename $path | cut -d '_' -f 4)
    local LOCAL_VER=$(agetprop persist.sys.zb_ver)
    local bak_file=$_ota_bak_dir/$(basename $path)

    echo "cloud ver:$CLOUD_VER,local :$LOCAL_VER"

    if [ "$CLOUD_VER" != "$LOCAL_VER" ]; then
        echo "zigbee_msnger zgb_ota $path"
        mkdir -p $_ota_bak_dir
        cp $path $bak_file -fv
        sync
        local var=1
        for i in `seq 4`;do
            if [ ! `pgrep Z3GatewayHost_MQTT` ];then
                red_echo "error !!! zb_host exit"
                Z3GatewayHost_MQTT -p /dev/ttyS1 -d /data/ -r c >> /tmp/zblog.txt &
                sleep 3
            fi
            zigbee_msnger zgb_ota "$path"

            for retry in $(seq 5); do
                sleep 1
                # Check result
                confirm_coor $CLOUD_VER
                var=$?
                if [ $var -eq 0 ]; then break; fi
            done
            if [ $var -eq 0 ]; then
                break;
            else
                red_echo "coordinator ota fail,retry"
            fi
        done

        if [ $var -ne 0 ]; then
            red_echo "coordinator ota fail"
            return 1
        fi

        rm $bak_file
        sync
    else
        echo "same coordinator ver"
    fi

    # rm $bakfile

    return 0
}

get_thread_ver() {
    local ver=$(echo $1 | cut -d '.' -f1 | cut -d "v" -f 2)
    echo $ver
}

wait_process_exit() {
    local i=1
    for i in $(seq 50); do
        if [ ! $(pgrep $1) ]; then
            break
        fi
        sleep 0.1
    done

    if [ $i -eq 50 ];then
        red_echo "exit $1 failed"
        killall -9 $1
        sleep 0.2
    fi
}
kill_otbr(){

    if [ "$_otbr_ctrl" != "0" ];then
        _otbr_run="1"
        if [ ! `pgrep otbr-agent` ];then
            _otbr_run="0"
            return
        fi
    fi

    _otbr_bind="eth0"
    if [ "`ifconfig | grep wlan0`" != "" ];then
        _otbr_bind="wlan0"
    fi

    otbr_manager.sh -s
    wait_process_exit otbr-agent
    _otbr_ctrl="0"
    echo "kill otbr"
}

restore_otbr(){
    if [ "$_otbr_run" != "1" ];then
        return
    fi

    otbr_manager.sh -r $_otbr_bind
    _otbr_ctrl="1"

    echo "restore otbr"

}

thread_ota() {
    local path=$1
    local thread_support="true" #$(agetprop persist.sys.thread_supported)

    if [ "$thread_support" != "true" ];then
        echo "no support thread"
        return 0
    fi
    if [ -z "$path" ] || [ ! -f $path ]; then
        return 0
    fi
    echo "===Update thread==="
    echo "path:$path"

    local bakfile=$_ota_bak_dir/$(basename $path)

    local ver=$(agetprop persist.sys.thread_ver)
    local ver_file=$(get_thread_ver $path)
    if [ "$ver" = "$ver_file" ]; then
        green_echo "same version, $ver"
        return 0
    fi

    if [ ! -f $bakfile ]; then
        mkdir -p $_ota_bak_dir
        cp $path $bakfile -fv
        sync
    fi

    local result=1
    for i in $(seq 4); do
        local dbus_pid=$(ps | grep "dbus-daemon" | grep -v grep | awk '{ print $1 }')
        if [ -z "$dbus_pid" ];then
            dbus-daemon --config-file=/etc/session.conf --fork
        fi

        kill_otbr
        sleep 0.5
        killall cpcd
        sleep 0.5
        cpcd -c /etc/mg21_thread_ota.conf -f $path 2>&1
        result=$?
        if [ $result -eq 0 ]; then
            break
        else
            red_echo "thread ota failed, retry"
            sleep 0.5
        fi
        # todo check version
        # riu_w 103e 00 0x55
        # echo 10 >/sys/class/gpio/unexport
        # sleep 0.1
        # # for get version
        # otbr_manager.sh -r "wlan0"
        # sleep 0.5
        # local ver_new=$(ot-ctl rcp version | grep VERSION | cut -d / -f 1 | cut -d : -f 2)
        # if [ "$ver_new" != "$ver_file" ]; then
        #     red_echo "diff ver $ver_file:$ver_new,retry ota thread"
        # else
        #     result=0
        #     break
        # fi
    done
    if [ $result -ne 0 ];then
        kill_otbr
        red_echo "ota thread failed"
        return 1
    fi

    kill_otbr

    rm $bakfile
    sync
    green_echo "ota thread success"
    asetprop persist.sys.thread_ver $ver_file
    asetprop persist.sys.zb_ver $ver_file
    return 0
}

check_thread_ota() {
    local thread_supported="true" #$(agetprop persist.sys.thread_supported)
    if [ "$thread_supported" != "true" ]; then
        return
    fi

    if [ ! -d $_ota_bak_dir ]; then
        return
    fi
    local path=$(ls $_ota_bak_dir | grep rcp-spi-802154-512)

    if [ -z "$path" ]; then
        return
    fi

    path=$_ota_bak_dir/$path
    red_echo "retry ota $path"
    if [ ! $(pgrep dbus-daemon) ]; then
         dbus-daemon --config-file=/etc/session.conf --fork
    fi

    thread_ota $path
    killall otbr-agent
    killall dbus-daemon

}


check_zigbee_ota() {
    return

    local zigbee_supported=$(agetprop persist.sys.zigbee_supported)
    if [ "$zigbee_supported" != "true" ]; then
        return
    fi

    local ok=n
    if [ ! -d $_ota_bak_dir ]; then
        return
    fi
    local path=$(ls $_ota_bak_dir | grep Network-Co-Processor | head -n 1)

    if [ ! -n "$path" ]; then
        return
    fi

    path=$_ota_bak_dir/$path
    red_echo "retry ota $path"

    Z3GatewayHost_MQTT -p /dev/ttyS1 -d /data/ -r c >/dev/null 2>&1 &
    # wait
    zigbee_agent -f /etc/zigbeeAgent.conf > /dev/null 2>&1 &
    sleep 0.1

    zigbee_msnger zgb_ota "$path"

    for i in `seq 30`;do
        zigbee_msnger get_zgb_ver
        if [ $? -eq 0 ];then
            ok=y
            break
        fi
        sleep 1
    done

    if [ $ok = "y" ];then
        green_echo "retry ota ok"
        rm $_ota_bak_dir/Network-Co-Processor*
        [ -f $path ] && rm $path
        sync
    else
        red_echo "retry ota failed"
    fi
    killall Z3GatewayHost_MQTT
    killall zigbee_agent
    sleep 0.1

}

check_file() {
    local input_file=$1
    local partition=$2
    local size=$(stat -c %s $input_file)
    local m1=$(md5sum $input_file | awk '{print $1}')
    local m2=$(head -c ${size} $partition | md5sum | awk '{print $1}')
    echo "size=$size"

    if [ "$m1" != "$m2" ]; then
        echo "write error : $path - $partition"
        return 1
    fi

    return 0
}


ota_kernel() {
    # Update kernel.
    echo "===Update kernel==="
    if [ ! -f $kernel_bin_ ];then
        return 0
    fi

    KERNEL_PARTITION=$(get_kernel_partitions)
    for cnt in $(seq 2); do
            if [ "$KERNEL_PARTITION" = "KERNEL" ]; then
                flash_erase /dev/mtd6 0 0
                /bin/nandwrite -p /dev/mtd6 $kernel_bin_; sync; sleep 0.4
                /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd6
                cat /tmp/kernel_head | awk -F ':' '{print $2}' >>/tmp/kernel_head0
            else
                flash_erase /dev/mtd5 0 0
                /bin/nandwrite -p /dev/mtd5 $kernel_bin_; sync; sleep 0.4
                /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd5
                cat /tmp/kernel_head | awk -F ':' '{print $2}' >>/tmp/kernel_head0
            fi

            hexdump -n 2048 -e '16/1 "%02x" "\n"' $kernel_bin_ >> /tmp/kernel_head1
            # Compare kernel.
            result=$(diff -w /tmp/kernel_head0 /tmp/kernel_head1)
            rm -f /tmp/kernel_head0
            rm -f /tmp/kernel_head1
            rm -f /tmp/kernel_head
            if [ "$result" = "" ]; then break; fi


    done
    if [ $cnt -eq 2 ]; then return 1; fi
    return 0
}

ota_rootfs() {
    # Update rootfs.
    echo "===Update rootfs==="

    if [ ! -f $rootfs_bin_ ];then
        return 0
    fi

    ROOTFS_PARTITION=$(get_rootfs_partitions)
    local index=7
    for cnt in $(seq 2); do
        if [ x"$ROOTFS_PARTITION" != x ]; then
            flash_erase /dev/mtd8 0 0
            /bin/nandwrite -p /dev/mtd8 $rootfs_bin_; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 --bb=dumpbad -f /tmp/rootfs_head -p /dev/mtd8
            cat /tmp/rootfs_head | awk -F ':' '{print $2}' >>/tmp/rootfs_head0
            index=8
        else
            flash_erase /dev/mtd7 0 0
            /bin/nandwrite -p /dev/mtd7 $rootfs_bin_; sync; sleep 0.4
            /bin/nanddump -s 0x0 -l 0x1 --bb=dumpbad -f /tmp/rootfs_head -p /dev/mtd7
            cat /tmp/rootfs_head | awk -F ':' '{print $2}' >>/tmp/rootfs_head0
            index=7
        fi

        hexdump -n 2048 -e '16/1 "%02x" "\n"' $rootfs_bin_ >> /tmp/rootfs_head1
        result=$(diff -w /tmp/rootfs_head0 /tmp/rootfs_head1)


        if [ "$result" != "" ];then
            echo "check again"
            /bin/nanddump -s 0x0 -l 0x1 -f /tmp/rootfs_head -p /dev/mtd$index
            cat /tmp/rootfs_head | awk  -F ':' '{print $2}' >> /tmp/rootfs_head0
            result=$(diff -w /tmp/rootfs_head0 /tmp/rootfs_head1)
        fi

        rm -f /tmp/rootfs_head0
        rm -f /tmp/rootfs_head1
        rm -f /tmp/rootfs_head
        if [ "$result" = "" ]; then break; fi

    done

    if [ $cnt -eq 2 ]; then return 1; fi

    return 0
}


ota_ir() {
    # Update IR-Controller firmware.
    echo "===Update IR-Controller==="
    if [ -f "$irctrl_bin_" ]; then
        if [ "$platform" = "miot" ]; then
            asetprop sys.app_monitor_delay 60
            killall mha_ir
            sleep 2
        fi

        cp $irctrl_bin_ $IRCTRL_BIN_BK_

        ir_ota ttyS3 115200 "$irctrl_bin_"
        # Check result
        update_block
        if [ $? -eq 1 ]; then
            echo "ota ir fail"
            return 1
        fi

        rm $IRCTRL_BIN_BK_
    fi

    return 0
}

ota_ble() {
    local ota_file=$1
    local version=$2

    local ble_support=$(agetprop persist.sys.ble_supported)
    if [ "$ble_support" != "true" ] || [ -z $ota_file ] || [ ! -f "$ota_file" ]; then
        green_echo "Bluetooth does not need to upgrade"
        return 2
    fi

    green_echo "upgrade ble version:$version"

    ble_ota -d /dev/ttyS2 -f $ota_file -v $version
    if [ $? -ne 0 ]; then
        return 1
    fi

    return 0
}

check_env() {
    local err_crc=$(/etc/fw_printenv 2>&1 | grep "Bad CRC")
    if [ x"$err_crc" != x ]; then
        red_echo "last env error,set default env"
        set_def_env
    else
        echo "env right"
    fi
}

update_start() {
    local platform="$1"
    local coor_bin_name=$(echo $ota_dir_/*.ota | cut -d '/' -f 4)

    #local ble_ota_bin=$(find $ota_dir_ -name ble_*)
    local thread_bin_=$(ls $ota_dir_/*.gbl)
    local zbcoor_bin_=$(ls $ota_dir_/Network-Co-Processor*)

    check_env

    local name_kernel=y
    local name_rootfs=y
    local name_boot=n
    local name_ac_switch=n
    local name_radar=n
    local name_thread=y

    echo rootfs:$name_rootfs
    echo kernel:$name_kernel
    echo $name_ac_switch
    echo $name_radar
    echo zigbee:$name_zigbee
    echo thread:$name_thread
    #ota_ir

    if [ "$name_zigbee" != n ];then
       coordinator_ota $zbcoor_bin_
       if [ $? -eq 1 ]; then
          red_echo "coordinator ota fail"
          return 1
        fi
    fi

    if [ "$name_thread" != n ];then
        thread_ota $thread_bin_
        if [ $? -eq 1 ]; then
            red_echo "thread ota fail"
            return 1
        fi
    fi

    if [ "$name_kernel" != n ];then
        ota_kernel $path $name_kernel $offset
        if [ $? -eq 1 ]; then
            echo "kernel ota fail"
            return 1
        fi
    fi

    if [ "$name_rootfs" != n ];then
        ota_rootfs $path $name_rootfs $offset
        if [ $? -eq 1 ]; then
            echo "rootfs ota fail"
            return 1
        fi
    fi


    echo "===Update ALL Success==="

    return 0
}

update_failed() {
    local platform="$1"
    local errmsg="$2"
    local clean="$3"

    green_echo "Update failed, reason: $errmsg"

    if [ "$clean" = "true" ]; then update_clean; fi

}

update_done() {
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
    green_echo "Usage: m100_update.sh -h [$OPTIONS]."
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
updater() {
    local sign="0"
    local path="/tmp/fw.tar.gz"

    # Check file existed or not.
    if [ ! -e "/tmp/curl" ]; then update_failed "$platform" "/tmp/curl not found!"; return 1; fi

    # Need check sign?
    if [ "$1" = "-s" ]; then sign="1"; fi

    # original or modified firmware?
    if [ "$1" = "-o" ]; then FW_TYPE="0"; fi
    if [ "$1" = "-m" ]; then FW_TYPE="1"; fi

    local platform=$(agetprop persist.sys.cloud)
    if [ "$platform" = "" ]; then platform=$DEFAULT_PLATFORM; fi

    green_echo "platform: $platform, path: $path, sign: $sign"

    # Prepare...
    update_prepare "$path"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "Not enough storage available!"
        return 1
    fi

    # Get DFU package and check it.
    update_get_packages "$platform" "$path" "$sign"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "getpack failed!" "true"
        return 1
    fi

    update_before_start "$platform"

    update_start "$platform"
    if [ $? -eq 0 ]; then
        update_done
    else
        update_failed "$platform" "OTA failed!" "true"
    fi

    return 0
}

check_zigbee_ic() {
    local zb_platform=$(agetprop persist.sys.zb_chip)
    if [ x"$zb_platform" = x ]; then

        local mg21=false
        get_zbic
        if [ $? -eq 28 ]; then
            echo "is p7"
            asetprop persist.sys.zb_chip "0028"
            ZIGBEE_IC="Ti2652"
        else
            echo "unknown ic,set to mg21"
            asetprop persist.sys.zb_chip "0021"
            ZIGBEE_IC="MG21"
        fi

    else

        if [ "$zb_platform" = "$CC2652P1" ] || [ "$zb_platform" = "$CC2652P7" ] || [ "$zb_platform" = "$CC1352P7" ]; then
            ZIGBEE_IC="Ti2652"
        else
            ZIGBEE_IC="MG21"
        fi
    fi

}

#
# Initial params.
#
initial() {
    local exit_flag=1

    wait_property_svr_ok
    check_zigbee_ic

    # Is another script running?
    for i in 2 3 1 0; do
        local info=$(ps)
        local this_num=$(echo "$info" | grep "$1" | wc -l)

        if [ $this_num -le 1 ]; then
            exit_flag=0
            break
        fi

        sleep $i # Waitting...
    done

    if [ $exit_flag -ne 0 ]; then exit 1; fi

    product=`agetprop ro.sys.model`
    model="AH_M100"

    sync

    green_echo "type: $product, model: $model"

    if [ "$product" != "lumi.gateway.agl010" ]; then
        red_echo "This is not supported M100 and exit!"
        exit 1
    fi
}

#
# Main function.
#
main() {

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
main $*
exit $?

