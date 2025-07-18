#!/bin/sh

REVISION="2"
REVISION_FILE="/data/utils/fw_manager.revision"

#
# @file    m3_update.sh
# @brief   This script is used to manage program operations,
#          including, but not limited to,
#          1. update firmware.
#
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
IRCTRL_BIN_BK_="/data/IRController.bin"
_ble_ota_bak_file="/data/ble_ota_bak.bin"
zbcoor_bin_bk_="/data/Network-Co-Processor.ota"
_ota_bak_dir=/data/ota-bak

#
# Version and md5sum
#
FIRMWARE_URL="https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main"
VERSION="4.3.7_0036.0013"
COOR_FILENAME="Network-Co-Processor_115200_MG21_0013_20240705_6DF00C.ota"
OT_RCP_SPI_OTA_FILENAME="ot-rcp-spi-ota-v0010.gbl"
BOOT_MD5SUM=""
COOR_MD5SUM="344c0c4c51f169996c5f9ea9ac6df00c"
OT_RCP_MD5SUM="572fd5220412a822db18fc93825eea9c"
KERNEL_MD5SUM="92017f71e70a6214811daad2b2e503c6"
ROOTFS_MD5SUM="a64d0db2cc077e9ffcdd18030f2a9600"
MODIFIED_ROOTFS_MD5SUM="ffe233de82fb45d3cc5011f6b0983711"
BTBL_MD5SUM=""
BTAPP_MD5SUM=""
IRCTRL_MD5SUM=""

kernel_bin_="$ota_dir_/kernel"
rootfs_bin_="$ota_dir_/rootfs.sqfs"

irctrl_bin_="$ota_dir_/IRController.bin"
ble_bl_bin_="$ota_dir_/bootloader.gbl"
ble_app_bin_="$ota_dir_/full.gbl"

ble_bl_bin_bk_="/data/bootloader.gbl"
ble_app_bin_bk_="/data/full.gbl"

#
# note: default is unknow.
#
model=""
ble_support=""
UPDATE_BT=0

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
sub_ota_dir_="/usr/ota_dir"
coor_dir_="/data/ota-files"
fws_dir_="/data/ota_dir"

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

#
# Get tags from file.
# Param1: file.
#
get_tags() {
    if [ ! -f "$1" ]; then return "0"; fi

    local file="$1"
    local tags=$(cat "$file")

    return $tags
}

usage_helper() {
    green_echo "Helper to show how to use this script."
    green_echo "Usage: fw_manager.sh -h [$OPTIONS]."
}

usage_updater() {
    green_echo "Update firmware."
    green_echo "Usage: fw_manager.sh -u [$UPDATER] [path]."
    green_echo " -s : check sign."
    green_echo " -n : don't check sign."
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
    if [ $s -eq 0 ]; then killall ha_lanstore; fi
    if [ $x -eq 0 ]; then killall ha_lanbox; fi
    if [ $o -eq 0 ]; then killall otbr-agent;fi

    killall ha_central

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
    if [ $s -eq 0 ]; then killall -9 ha_lanstore; fi
    if [ $x -eq 0 ]; then killall -9 ha_lanbox; fi
    if [ $o -eq 0 ]; then killall -9 otbr-agent;fi

    killall -9 ha_central

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
    # ota_dir_="/data/ota_unpack"
    # coor_dir_="/data/ota-files"
    # fws_dir_="/data/ota_dir"

    # Clean old firmware directory.
    if [ -d $fws_dir_ ]; then rm $fws_dir_ -rf; fi
    if [ -d $coor_dir_ ]; then rm $coor_dir_ -rf; fi
    if [ -d $ota_dir_ ]; then rm $ota_dir_ -rf; fi

    # Clean log files.
    rm /tmp/bmlog.txt* -f
    rm /tmp/zblog.txt* -f
    rm /tmp/aulog.txt* -f

    killall -9 app_monitor.sh
    kill_otbr

    echo 3 >/proc/sys/vm/drop_caches
    sleep 1

    dfu_pkg_="$1"

    firmwares_="$fws_dir_/lumi_fw.tar"

    kernel_bin_="$ota_dir_/kernel"
    rootfs_bin_="$ota_dir_/rootfs.sqfs"

    irctrl_bin_="$ota_dir_/IRController.bin"
    ble_bl_bin_="$ota_dir_/bootloader.gbl"
    ble_app_bin_="$ota_dir_/full.gbl"

    ble_bl_bin_bk_="/data/bootloader.gbl"
    ble_app_bin_bk_="/data/full.gbl"

    local dfusize=30000
    local memfree=$(cat /proc/meminfo | grep MemFree | tr -cd "[0-9]")
    local romfree=$(df | grep data | awk '{print $4}')

    dfusize_=$(convert_str2int "$dfusize")
    memfree_=$(convert_str2int "$memfree")
    romfree_=$(convert_str2int "$romfree")

    green_echo "Original OTA package : $dfu_pkg_"
    green_echo "Unpack path          : $ota_dir_"
    green_echo "Firmware path        : $fws_dir_"
    green_echo "OTA packages size(kb) : $dfusize_"
    green_echo "Available ROM size(kb): $romfree_"
    green_echo "Available RAM size(kb): $memfree_"

    # Check memory space.
    # Failed to get var if romfree_/memfree_ equal zero.
    if [[ $romfree_ -lt $dfusize_ ]]; then
        red_echo "Not enough storage available!"
        return 1
    fi

    mkdir -p $fws_dir_ $coor_dir_ $ota_dir_

    return 0
}

update_get_packages() {
    local simple_model="M3"
    local platform="$1"

    local path="$2"
    local sign="$3"

    echo "Update to ${VERSION}"
    echo "Get packages, please wait..."
    if [ "x${IRCTRL_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/IRController.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/IRController.bin
        [ "$(md5sum /tmp/IRController.bin)" != "${IRCTRL_MD5SUM}  /tmp/IRController.bin" ] && return 1
    fi

    if [ "x${UPDATE_BT}" == "x1" ]; then
        if [ "x${BTBL_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/bootloader.gbl ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/bootloader.gbl
        [ "$(md5sum /tmp/bootloader.gbl)" != "${BTBL_MD5SUM}  /tmp/bootloader.gbl" ] && return 1
        fi

        if [ "x${BTAPP_MD5SUM}" != "x" ]; then
            /tmp/curl -s -k -L -o /tmp/full.gbl ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/full.gbl
            [ "$(md5sum /tmp/full.gbl)" != "${BTAPP_MD5SUM}  /tmp/full.gbl" ] && return 1
        fi
    fi

    if [ "x${BOOT_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/boot.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/boot.bin
        [ "$(md5sum /tmp/boot.bin)" != "${BOOT_MD5SUM}  /tmp/boot.bin" ] && return 1
    fi

    if [ "x${COOR_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/coor.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/${COOR_FILENAME}
        [ "$(md5sum /tmp/coor.bin)" != "${COOR_MD5SUM}  /tmp/coor.bin" ] && return 1
    fi

    if [ "x${OT_RCP_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/ot-rcp-spi-ota.gbl ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/${OT_RCP_SPI_OTA_FILENAME}
        [ "$(md5sum /tmp/ot-rcp-spi-ota.gbl)" != "${OT_RCP_MD5SUM}  /tmp/ot-rcp-spi-ota.gbl" ] && return 1
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

update_clean() {
    rm -rf "$dfu_pkg_" "$fws_dir_" "$ota_dir_"
    sync
    sync
    sync
    sleep 1
}

#
# Check update status was block or not.
# return value 1: true.
# return value 0: false.
#
update_block() {
    local result=$(agetprop sys.dfu_progress)
    if [ "$result" = "-1" ]; then return 1; fi

    return 0
}

update_before_start() {
    local platform="$1"

    if [ -f "/tmp/boot.bin" ]; then
        mv /tmp/boot.bin "$ota_dir_"
    fi
    if [ -f "/tmp/coor.bin" ]; then
        mv /tmp/coor.bin "$ota_dir_"/$COOR_FILENAME
    fi
    if [ -f "/tmp/ot-rcp-spi-ota.gbl" ]; then
        mv /tmp/ot-rcp-spi-ota.gbl "$ota_dir_"/$OT_RCP_SPI_OTA_FILENAME
    fi

    if [ -f "/tmp/kernel" ]; then
        mv /tmp/kernel "$ota_dir_"
    fi
    if [ -f "/tmp/rootfs.sqfs" ]; then
        mv /tmp/rootfs.sqfs "$ota_dir_"
    fi
}

get_kernel_partitions() {
    # /etc/fw_printenv | grep bootcmd | awk '{print $4}'
    /etc/fw_printenv | grep ker_part= | awk -F= '{print $2}'
}

get_rootfs_partitions() {
    cat /proc/cmdline | grep mmcblk0p4
}

set_kernel_partitions() {
    if [ "$1" = "kernela" ]; then
        /etc/fw_setenv ker_path "kernelb"
        /etc/fw_setenv ker_bak_path "kernela"
    else
        /etc/fw_setenv ker_path "kernela"
        /etc/fw_setenv ker_bak_path "kernelb"
    fi
}

set_rootfs_partitions() {
    if [ x"$1" != x ]; then
        /etc/fw_setenv root_path "/dev/mmcblk0p5"
    else
        /etc/fw_setenv root_path "/dev/mmcblk0p4"
    fi

}

set_def_env() {
    echo "set default env"
    /etc/fw_setenv mtdparts 'mtdparts=nor0:0x5E000(BOOT0),0x1000(ENV),0x1000(ENV1)'
    # /etc/fw_setenv bootargs "console=ttyS0,115200 root=/dev/mmcblk0p4 rootwait rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2B0000 cma=2M highres=on mtdparts=nor0:0x5E000(BOOT0),0x1000(ENV),0x1000(ENV1)"
    # /etc/fw_setenv bootcmd "emmc read.p 0x21000000 kernela 0xA00000 ; dcache on;bootm 0x21000000;emmc read.p 0x21000000 kernelb 0xA00000 ;bootm 0x21000000"

    /etc/fw_setenv ker_path "kernela"
    /etc/fw_setenv ker_bak_path "kernelb"
    /etc/fw_setenv root_path "/dev/mmcblk0p4"
    /etc/fw_setenv update_boot 'setenv update_boot1 emmc read.p 0x21000000 ${ker_path} 0xA00000'
    /etc/fw_setenv update_bootbak 'setenv update_boot1 emmc read.p 0x21000000 ${ker_bak_path} 0xA00000'
    /etc/fw_setenv update_bootargs 'setenv bootargs console=ttyS0,115200 root=${root_path} rootwait rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2B0000 cma=2M highres=on ${mtdparts}'
    /etc/fw_setenv bootcmd 'run update_bootargs; run update_boot; run update_boot1; bootm 0x21000000; run update_bootbak; run update_boot1; bootm 0x21000000'
    /etc/fw_setenv bootargs 'console=ttyS0,115200 root=${root_path} rootwait rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x2B0000 cma=2M highres=on ${mtdparts}'
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
    # Update zigbee-coordinator firmware.
    echo "===Update zigbee-coordinator==="
    local path=$1

    if [ ! -n "$path" ] || [ ! -f "$path" ]; then
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
    local force_ota=false

    echo "cloud ver:$CLOUD_VER,local :$LOCAL_VER"
    zigbee_msnger get_zgb_ver
    if [ $? -ne 0 ]; then
        red_echo "get zgb ver fail"
        force_ota=true
        asetprop persist.sys.zb_ver
    fi

    if [ "$CLOUD_VER" != "$LOCAL_VER" ] || [ $force_ota = "true" ]; then
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
    echo "===Update thread==="

    if [ ! -n "$path" ] || [ ! -f $path ]; then
        return 0
    fi
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
        cpcd -c /etc/mg21_thread_ota.conf -f $path > /dev/null 2>&1
        riu_w 103e 00 0x55
        echo 10 >/sys/class/gpio/unexport
        sleep 0.1
        # for get version
        otbr_manager.sh -r "eth0"
        sleep 0.5
        local ver_new=$(ot-ctl rcp version | grep VERSION | cut -d / -f 1 | cut -d : -f 2)
        if [ "$ver_new" != "$ver_file" ]; then
            red_echo "diff ver $ver_file:$ver_new,retry ota thread"
        else
            result=0
            break
        fi
    done
    if [ $result -ne 0 ];then
        kill_otbr
        red_echo "ota thread failed"
        return
    fi

    kill_otbr

    rm $bakfile
    sync
    green_echo "ota thread success"
    asetprop persist.sys.thread_ver $ver_file
    return 0
}

check_thread_ota() {
    if [ ! -d $_ota_bak_dir ]; then
        return
    fi
    local path=$(ls $_ota_bak_dir | grep ot-rcp-spi-ota)

    if [ ! -n "$path" ]; then
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
        if [ -f "$kernel_bin_" ]; then
            local partition=/dev/mmcblk0p1
            if [ "$KERNEL_PARTITION" = "kernela" ]; then
                partition=/dev/mmcblk0p2
                echo "to p2"
            else
                echo "to p1"
            fi

            cat $kernel_bin_ >$partition
            sync
            sleep 0.1
            sync

            check_file $kernel_bin_ $partition
            if [ $? -eq  0 ];then return 0;fi
            red_echo "update kernel failed"
        fi
    done
    if [ $cnt -eq 2 ]; then return 1; fi
    return 0
}
ota_rootfs() {
    # Update rootfs.
    echo "===Update rootfs==="
    ROOTFS_PARTITION=$(get_rootfs_partitions)
    for cnt in $(seq 2); do
        if [ -f "$rootfs_bin_" ]; then
            local partition=/dev/mmcblk0p4
            if [ x"$ROOTFS_PARTITION" != x ]; then
                echo "to p5"
                # tar -xOf rootfs.bin rootfs.ext4 >/dev/mmcblk0p5
                partition=/dev/mmcblk0p5
            else
                echo "to p4"
            fi

            cat $rootfs_bin_ >$partition
            sync
            sleep 0.1
            sync
            check_file $rootfs_bin_ $partition
            if [ $? -eq  0 ];then return 0;fi
            red_echo "update rootfs failed"

            if [ "$result" = "" ]; then break; fi
        fi
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
    local thread_bin=$(ls $ota_dir_/*.gbl)
    local zbcoor_bin=$(ls $ota_dir_/Network-Co-Processor*)

    check_env

    #ota_ir

    coordinator_ota $zbcoor_bin
    if [ $? -eq 1 ]; then
        red_echo "coordinator ota fail"
        return 1
    fi

    thread_ota $thread_bin
    if [ $? -eq 1 ]; then
        red_echo "thread ota fail"
        return 1
    fi

    ota_kernel
    if [ $? -eq 1 ]; then
        red_echo "kernel ota fail"
        return 1
    fi

    ota_rootfs
    if [ $? -eq 1 ]; then
        red_echo "rootfs ota fail"
        return 1
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

    restore_otbr
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


run_ir_ota() {
    local path=$1
    local ver=$2
    if [ ! -f $path ]; then
        return 1
    fi

    ir_ota ttyS3 115200 "$path"

    if [ $? -eq 0 ]; then
        green_echo "ir ota succeed"
        asetprop persist.sys.ir_ver `printf %04d $ver`
        return 0
    else
        red_echo "ir ota failed"
        return 1
    fi
}

get_ir_path() {
    local is_cm_ir_ic=$1
    if [ "$is_cm_ir_ic" = "CM" ]; then
        ir_ota_file=$(find $sub_ota_dir_ -name "ir_cm*.bin")
    elif [ "$is_cm_ir_ic" = "TI" ]; then
        ir_ota_file=$(find $sub_ota_dir_ -name "ir_ti*.bin")
    else
        ir_ota_file=$(find $sub_ota_dir_ -name "ir_hd*.bin")
    fi
    echo $ir_ota_file
}

get_ir_ver() {
    echo $1 | xargs basename | cut -d '_' -f3
}

ota_ir_force() {
    local ok=0
    local tab="TI CM HD TI CM HD"
    for i in $tab; do
        local tmp=$i
        local path=$(get_ir_path $tmp)

        if [ -z "$path" ]; then
            red_echo "no found ota file $tmp"
            continue
        fi
        local ver=$(get_ir_ver $path)

        run_ir_ota $path $ver

        if [ $? -eq 0 ]; then
            asetprop persist.sys.ir_chip $tmp
            ok=1
            break
        fi
    done
    echo "ok=$ok"

    return $ok
}

run_check_ir() {

    check_ir 3
    local ir_err=$?
    if [ $ir_err -ne 0 ]; then
        ota_ir_force
        if [ $? -eq 1 ]; then
            green_echo "ir ota ok"
        else
            red_echo "ir ota fail"
        fi
        return
    fi
}

run_submodule_ota() {

    # local usermode=$(agetprop persist.sys.factory_result)
    # if [ "$usermode" != "true" ]; then
    #     return
    # fi

    local ble_ota_file=$(find $sub_ota_dir_ -name "ble*.bin")
    local ble_ota_ver=$(echo $ble_ota_file | xargs basename | cut -d '_' -f4)
    local ble_ver=$(agetprop persist.sys.ble_ver)


    if [ -f $ble_ota_file ] && [ "$ble_ota_ver" != "$ble_ver" ]; then
        ota_ble $ble_ota_file $ble_ota_ver
        if [ $? -eq 0 ]; then
            green_echo "ble ota succeed"
            reboot
        fi
    fi

    run_check_ir


    local is_cm_ir_ic=$(agetprop persist.sys.ir_chip)
    local ir_ota_file="irota.bin"
    local ir_ver=$(agetprop persist.sys.ir_ver)
    if [ ! -z $ir_ver ];then
        ir_ver=`expr $ir_ver + 0`
    else
        ir_ver=-1
    fi
    if [ "$is_cm_ir_ic" = "TI" ]; then
        ir_ota_file=$(find $sub_ota_dir_ -name "ir_ti*.bin")
    elif [ "$is_cm_ir_ic" = "CM" ]; then
        ir_ota_file=$(find $sub_ota_dir_ -name "ir_cm*.bin")
    else
        ir_ota_file=$(find $sub_ota_dir_ -name "ir_hd*.bin")
    fi

    local ir_ota_ver=$(echo $ir_ota_file | xargs basename | cut -d '_' -f3)
    if [ ! -z $ir_ota_ver ];then
        ir_ota_ver=`expr $ir_ota_ver + 0`
    fi
    echo "ir ota:$ir_ota_ver,local:$ir_ver"

    if [ ! -z $ir_ota_file ] && [ -f $ir_ota_file ] && [ "$ir_ota_ver" -ne "$ir_ver" ]; then
        ir_ota ttyS3 115200 "$ir_ota_file" $ir_ota_ver
        if [ $? -eq 0 ]; then
            green_echo "ir ota succeed"
            asetprop persist.sys.ir_ver `printf %04d $ir_ota_ver`

        else
            red_echo "ir ota failed"
            run_check_ir
        fi
    fi
}

#
# Document helper.
#
helper() {
    local cmd="$1"

    case $cmd in
    -u) usage_updater ;;

    *) usage_helper ;;
    esac

    return 0
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


#
# Sometimes, we need to compatible from old version to newer one.
#
compatible() {
    get_tags "$REVISION_FILE"
    local pre_revision="$?"

    green_echo "pre-revision: $pre_revision"

    case $pre_revision in
    0)
        green_echo "remove /data/lumi_fw"
        rm -rf /data/lumi_fw
        ;;
    1)
        green_echo "remove /data/lumi_fw"
        rm -rf /data/lumi_fw
        ;;

    *) green_echo "" ;;
    esac

    # Save newest revision into file.
    set_tags "$REVISION_FILE" "$REVISION"
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
    wait_property_svr_ok
    check_zigbee_ic

    local exit_flag=1

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

    green_echo "$1 revision: $REVISION"

    # Compatible by revision.
    # compatible

    product=$(agetprop ro.sys.model)
    model="AH_M3"

    if [ "$product" != "lumi.gateway.acn012" ]; then
        red_echo "This is not supported M3 and exit!"
        exit 1
    fi
    sync

    green_echo "type: $product, model: $model"
}

#
# Main function.
#
main() {

    initial ${0##*/}

    local option="$1"

    case $option in
    -h)
        local cmd="$2"
        helper $cmd
        ;;

    -u|*) updater $* ;;

    esac

    return $?
}

#
# Run script.
#
main $*
exit $?
