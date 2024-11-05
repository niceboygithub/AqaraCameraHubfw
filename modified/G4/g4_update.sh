#!/bin/sh

REVISION="2"
REVISION_FILE="/data/utils/fw_manager.revision"

#
# @file    g4_update.sh
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
# Enable debug, 0/1.
#
DEBUG=1

#
# Updater variables
#
FIRMWARE_URL="https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main"
VERSION="4.0.6_0044.0090"
BOOT_MD5SUM=""
KERNEL_MD5SUM=""
ROOTFS_MD5SUM="8ac2be827400151bb66db597057931be"
AI_IMAGE_MD5SUM=""
MUSIC_IMAGE_MD5SUM=""
MODIFIED_ROOTFS_MD5SUM="1128bbeff6cafec9413b0bc3ed39d0bf"
DOORBELL_DFU_IMAGE_MD5SUM="c220bce22b67278902acac42eca3c18d"
DOORBELL_DFU_IMAGE="doorbell_firmware_4.0.6_0090_a3c18d.bin"

UPGRADE_PACKAGE_NAME=
UPGRADE_IMAGES_DIR="/data/ota_images"
UPGRADE_UNPACK_DIR="/tmp/ota_unpack"
UPGRADE_FIRMWARE_NAME="$UPGRADE_UNPACK_DIR/firmware.tar"

DOORBELL_DFU_DIR="/data/dfu"
DOORBELL_DFU_IMAGE_NAME="doorbell_firmware.bin"
DOORBELL_DFU_IMAGE_FULL_NAME="${DOORBELL_DFU_DIR}/doorbell_firmware.bin"
DOORBELL_DFU_TIMEOUT=300 ## 5Min

DFU_POST_CMD="/bin/dfu_post.sh"
DFU_PREPARE_CMD="/bin/dfu_pre.sh"

# Doorbell image backup info
DOORBELL_DFU_BACK_IMAGE_FULL_NAME="${DOORBELL_DFU_DIR}/doorbell_firmware.bin.bk"
DOORBELL_DFU_BACK_PROP_FULL_NAME="${DOORBELL_DFU_DIR}/doorbell_dfu.prop"

# Image names
UBOOT_IMAGE_NAME="$UPGRADE_IMAGES_DIR/boot.bin"
KERNEL_IMAGE_NAME="$UPGRADE_IMAGES_DIR/kernel"
ROOTFS_IMAGE_NAME="$UPGRADE_IMAGES_DIR/rootfs.sqfs"
AI_IMAGE_NAME="$UPGRADE_IMAGES_DIR/face_quality.bin"
MUSIC_IMAGE_NAME="$UPGRADE_IMAGES_DIR/musics.tar.gz"

#
# Show green content, in the same way to use as echo.
#
green_echo()
{
    if [ $DEBUG -eq 0 ]; then return; fi

    local green="\033[0;32m"; black="\033[0m"
    local format="$1"
    local time="$(date '+%Y-%m-%d %H:%M:%S')"
    printf "${green}[$0] [$time] %s${black}\n" "${format}"
}

#
# Show red content, in the same way to use as echo.
#
red_echo()
{
    local red="\033[0;31m";
    local black="\033[0m";
    local format="$1"
    local time="$(date '+%Y-%m-%d %H:%M:%S')"
    printf "${red}[$0] [$time] %s${black}\n" "${format}"
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
    local string="$1"
    local substr="$2"

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
}

wait_property_svr_ok()
{
    for i in $(seq 10); do
        local prop_valid=$(agetprop ro.sys.prop_valid)
        if [ "$prop_valid" = "true" ];then break; fi
        sleep 0.1
        echo "Wait for property_service"
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
    local v=0; local w=0
    local l=0
    local c=0
    local re=0
    local i=0
    local u=0
    local o=0

    match_substring "$1" "d"; d=$?
    match_substring "$1" "m"; m=$?
    match_substring "$1" "b"; b=$?
    match_substring "$1" "a"; a=$?
    match_substring "$1" "p"; p=$?
    match_substring "$1" "z"; z=$?

    match_substring "$1" "v"
    v=$?
    match_substring "$1" "c"
    c=$?
    match_substring "$1" "re"
    re=$?
    match_substring "$1" "i"
    i=$?
    match_substring "$1" "u"
    i=$?
    match_substring "$1" "o"
    o=$?
    match_substring "$1" "w"
    w=$?
    green_echo "d:$d, m:$m, b:$b, a:$a, p:$p, z:$z, v:$v, re:$re, c:$c, i:$1, u:$1, o:$o, w:$w"

    # Stop monitor.
    killall -9 app_monitor.sh

    sleep 1.5

    #
    # Send a signal to programs.
    #
    if [ $d -eq 0 ]; then killall ha_driven        ;fi
    if [ $m -eq 0 ]; then killall ha_master        ;fi
    if [ $b -eq 0 ]; then killall ha_basis         ;fi
    if [ $a -eq 0 ]; then killall ha_agent         ;fi
    if [ $p -eq 0 ]; then killall property_service ;fi
    if [ $c -eq 0 ]; then killall ppcs; fi
    if [ $w -eq 0 ]; then killall webrtc ;fi
    if [ $re -eq 0 ]; then killall recorder; fi
    if [ $i -eq 0 ]; then killall ai; fi
    if [ $v -eq 0 ]; then killall vidicond; fi
    if [ $p -eq 0 ]; then killall property_service; fi
    if [ $o -eq 0 ]; then killall logd; fi

    sleep 1

    #
    # Force to kill programs.
    #
    if [ $d -eq 0 ]; then killall -9 ha_driven        ;fi
    if [ $m -eq 0 ]; then killall -9 ha_master        ;fi
    if [ $b -eq 0 ]; then killall -9 ha_basis         ;fi
    if [ $a -eq 0 ]; then killall -9 ha_agent         ;fi
    if [ $p -eq 0 ]; then killall -9 property_service ;fi
    if [ $c -eq 0 ]; then killall -9 ppcs; fi
    if [ $w -eq 0 ]; then killall -9 webrtc ;fi
    if [ $re -eq 0 ]; then killall -9 recorder; fi
    if [ $i -eq 0 ]; then killall -9 ai; fi
    if [ $v -eq 0 ]; then killall -9 vidicond; fi
    if [ $p -eq 0 ]; then killall -9 property_service; fi
    if [ $o -eq 0 ]; then killall -9 logd; fi

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

    sleep 1.5


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

    # P3 programs.
    if [ "$model" = "AC_P3" ]; then killall -9 mha_ir ;fi
}

force_stop_unlimited()
{
    killall -9 app_monitor.sh
    killall -9 property_service

    # AIOT
    killall -9 ha_master
    killall -9 ha_driven
    killall -9 ha_basis
    killall -9 ha_agent
    killall -9 ppcs
    killall -9 webrtc
    killall -9 logd
    killall -9 recorder
    killall -9 ai
    killall -9 vidicond
    sleep 2

    # MIOT
    killall -9 miio_client
    killall -9 miio_agent
    killall -9 miio_client_helper_nomqtt.sh
    killall -9 mha_master
    killall -9 mha_basis
    killall -9 mzigbee_agent
    killall -9 homekitserver
}

#
# Prepare for update.
# Return value 1 : failed.
# Return value 0 : ok.
#
update_prepare()
{
    # Clean old firmware directory.
    if [ -d $UPGRADE_UNPACK_DIR ]; then rm $UPGRADE_UNPACK_DIR -rf; fi
    if [ -d $UPGRADE_IMAGES_DIR ]; then rm $UPGRADE_IMAGES_DIR -rf; fi

    # Clean log files.
    rm /tmp/bmlog.txt* -f
    rm /tmp/aulog.txt* -f
    rm /tmp/*log.txt* -f

    # Before upgrade, kill some process to free memory
    ${DFU_PREPARE_CMD}

    echo 3 >/proc/sys/vm/drop_caches; sleep 1

    UPGRADE_PACKAGE_NAME="$1"

    local dfusize=26384
    local memfree=`cat /proc/meminfo | grep MemFree | tr -cd "[0-9]"`
    local romfree=`df | grep data  | awk '{print $4}'`

    local dfusize_int=`convert_str2int "$dfusize"`
    local memfree_int=`convert_str2int "$memfree"`
    local romfree_int=`convert_str2int "$romfree"`

    green_echo "Updating            : $VERSION"
    green_echo "Unpack path          : $UPGRADE_UNPACK_DIR"
    green_echo "Firmware path        : $UPGRADE_IMAGES_DIR"
    green_echo "OTA packages size(kb) : $dfusize_int"
    green_echo "Available ROM size(kb): $romfree_int"
    green_echo "Available RAM size(kb): $memfree_int"

    # Check memory space.
    # Failed to get var if romfree_/memfree_ equal zero.
    if [[ $romfree_int -lt $(($dfusize / 2)) ]]; then
        red_echo "Not enough storage available!"
        return 1
    fi

    mkdir -p $UPGRADE_UNPACK_DIR $UPGRADE_IMAGES_DIR $DOORBELL_DFU_DIR
    return 0
}

update_get_packages()
{
    local platform="$1"

    local path="$2"
    local sign="$3"
    local simple_model="G4"

    echo "Get packages, please wait..."
    if [ "x${BOOT_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/boot.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/boot.bin
        [ "$(md5sum /tmp/boot.bin)" != "${BOOT_MD5SUM}  /tmp/boot.bin" ] && return 1
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

    if [ "x${AI_IMAGE_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/face_quality.bin ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/face_quality.bin
        [ "$(md5sum /tmp/face_quality.bin)" != "${AI_IMAGE_MD5SUM}  /tmp/face_quality.bin" ] && return 1
    fi

    if [ "x${MUSIC_IMAGE_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/musics.tar.gz ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/musics.tar.gz
        [ "$(md5sum /tmp/musics.tar.gz)" != "${MUSIC_IMAGE_MD5SUM}  /tmp/musics.tar.gz" ] && return 1
    fi

    if [ "x${DOORBELL_DFU_IMAGE_MD5SUM}" != "x" ]; then
        /tmp/curl -s -k -L -o /tmp/${DOORBELL_DFU_IMAGE} ${FIRMWARE_URL}/original/${simple_model}/${VERSION}/${DOORBELL_DFU_IMAGE}
        [ "$(md5sum /tmp/${DOORBELL_DFU_IMAGE})" != "${DOORBELL_DFU_IMAGE_MD5SUM}  /tmp/${DOORBELL_DFU_IMAGE}" ] && return 1
    fi

    echo "Got package done"
    return 0
}

update_clean()
{
    rm -rf "$UPGRADE_PACKAGE_NAME" "$UPGRADE_UNPACK_DIR" "$UPGRADE_IMAGES_DIR"
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

update_before_start()
{
    local platform="$1"

    if [ -f "/tmp/boot.bin" ]; then
        mv /tmp/boot.bin $UBOOT_IMAGE_NAME
    fi
    if [ -f "/tmp/kernel" ]; then
        mv /tmp/kernel $KERNEL_IMAGE_NAME
    fi
    if [ -f "/tmp/rootfs.sqfs" ]; then
        mv /tmp/rootfs.sqfs $ROOTFS_IMAGE_NAME
    fi
    if [ -f "/tmp/face_quality.bin" ]; then
        mv /tmp/face_quality.bin $AI_IMAGE_NAME
    fi
    if [ -f "/tmp/musics.tar.gz" ]; then
        mv /tmp/musics.tar.gz $MUSIC_IMAGE_NAME
    fi
    if [ -f "/tmp/${DOORBELL_DFU_IMAGE}" ]; then
        mv /tmp/${DOORBELL_DFU_IMAGE} $UPGRADE_IMAGES_DIR
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
        /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL_BAK 0x500000; dcache on; bootlogo 0 0 0 0; bootm 0x22000000;nand read.e 0x22000000 KERNEL 0x500000; dcache on; bootm 0x22000000"
    else
        /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL 0x500000; dcache on; bootlogo 0 0 0 0; bootm 0x22000000;nand read.e 0x22000000 KERNEL_BAK 0x500000; dcache on; bootm 0x22000000"
    fi
}

set_rootfs_partitions()
{
    if [ x"$1" != x ];then
        /etc/fw_setenv bootargs "root=/dev/mtdblock8 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x200000 cma=2M mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x3300000,max_end_off=0x3600000 mtdparts=nand0:1664k@0x140000(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),1m(factory),20m(RES),-(UBI)"
    else
        /etc/fw_setenv bootargs "root=/dev/mtdblock7 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x7FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x200000 cma=2M mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x3300000,max_end_off=0x3600000 mtdparts=nand0:1664k@0x140000(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),1m(factory),20m(RES),-(UBI)"
    fi
}

flash_kernel()
{
    # Update kernel.
    green_echo "===Update kernel==="
    KERNEL_PARTITION=$(get_kernel_partitions)
    for cnt in `seq 4`
    do
        if [ -f "$KERNEL_IMAGE_NAME" ];then
            if [ "$KERNEL_PARTITION" = "KERNEL" ];then
                flash_erase /dev/mtd6 0 0
                /bin/nandwrite -p /dev/mtd6 $KERNEL_IMAGE_NAME; sync; sleep 0.4
                /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd6
                cat /tmp/kernel_head | awk -F ':' '{print $2}' >> /tmp/kernel_head0
            else
                flash_erase /dev/mtd5 0 0
                /bin/nandwrite -p /dev/mtd5 $KERNEL_IMAGE_NAME; sync; sleep 0.4
                /bin/nanddump -s 0x0 -l 0x1 -f /tmp/kernel_head -p /dev/mtd5
                cat /tmp/kernel_head | awk -F ':' '{print $2}' >> /tmp/kernel_head0
            fi

            hexdump -n 2048 -e '16/1 "%02x" "\n"' $KERNEL_IMAGE_NAME >> /tmp/kernel_head1
            result=`diff -w /tmp/kernel_head0 /tmp/kernel_head1`
            rm -f /tmp/kernel_head0; rm -f /tmp/kernel_head1; rm -f /tmp/kernel_head
            if [ "$result" = "" ];then break; fi
        else
            return 0
        fi
    done

    if [ $cnt -eq 4 ];then return 1; fi

    return 0
}

flash_rootfs()
{
    # Update rootfs.
    green_echo "===Update rootfs==="
    ROOTFS_PARTITION=$(get_rootfs_partitions)
    for cnt in `seq 4`; do
        if [ -f "$ROOTFS_IMAGE_NAME" ];then
            if [ x"$ROOTFS_PARTITION" != x ];then
                flash_erase /dev/mtd8 0 0
                /bin/nandwrite -p /dev/mtd8 $ROOTFS_IMAGE_NAME; sync; sleep 0.4
                /bin/nanddump -s 0x0 -l 0x1 -f /tmp/rootfs_head -p /dev/mtd8
                cat /tmp/rootfs_head | awk  -F ':' '{print $2}' >> /tmp/rootfs_head0
            else
                flash_erase /dev/mtd7 0 0
                /bin/nandwrite -p /dev/mtd7 $ROOTFS_IMAGE_NAME; sync; sleep 0.4
                /bin/nanddump -s 0x0 -l 0x1 -f /tmp/rootfs_head -p /dev/mtd7
                cat /tmp/rootfs_head | awk  -F ':' '{print $2}' >> /tmp/rootfs_head0
            fi
            hexdump -n 2048 -e '16/1 "%02x" "\n"' $ROOTFS_IMAGE_NAME >> /tmp/rootfs_head1
            result=`diff -w /tmp/rootfs_head0 /tmp/rootfs_head1`
            rm -f /tmp/rootfs_head0; rm -f /tmp/rootfs_head1; rm -f /tmp/rootfs_head
            if [ "$result" = "" ];then break; fi
        else
            return 0
        fi
    done

    if [ $cnt -eq 4 ];then return 1; fi

    return 0
}

flash_uboot()
{
    # Update uboot.
    green_echo "===Update uboot==="
    if [ ! -f "$UBOOT_IMAGE_NAME" ];then
        return 0
    fi

    for cnt in `seq 4`
    do
    if [ -f "$UBOOT_IMAGE_NAME" ];then
        flash_erase /dev/mtd0 0 0
        /bin/nandwrite -p /dev/mtd0 $UBOOT_IMAGE_NAME; sync; sleep 0.4
        /bin/nanddump -s 0x0 -l 0x1 -f /tmp/boot_head -p /dev/mtd0
        cat /tmp/boot_head | awk -F ':' '{print $2}' >> /tmp/boot_head0

        hexdump -n 2048 -e '16/1 "%02x" "\n"' $UBOOT_IMAGE_NAME >> /tmp/boot_head1
        result=`diff -w /tmp/boot_head0 /tmp/boot_head1`
        rm -f /tmp/boot_head0; rm -f /tmp/boot_head1; rm -f /tmp/boot_head
        if [ "$result" = "" ];then break; fi
   fi
   done

    if [ $cnt -eq 4 ];then return 1; fi

    return 0
}

flash_ai()
{
    # Update ai.
    green_echo "===Update ai==="

    if [ -f "$AI_IMAGE_NAME" ];then
        rm -fr /data/ai/face_quality.bin*
        rm -fr /data/ai/md5sum.txt*
        mv /res/encModels/face_quality.bin /data/ai/face_quality.bin-bak
        mv /res/encModels/md5sum.txt /data/ai/md5sum.txt-bak
        rm -f /res/encModels/*
        cp -f $AI_IMAGE_NAME /res/encModels/
        sync
        local md5="$(md5sum /res/encModels/face_quality.bin | awk '{a=substr($1,0,32); print a}')"
        if [ -f "/res/encModels/md5sum.txt" ];then
            rm -f /res/encModels/md5sum.txt
        fi
        echo $md5 > /res/encModels/md5sum.txt
        sync
    else
        return 1
    fi

    return 0
}

flash_musics()
{
    # Update musics.
    if [ -f "$MUSIC_IMAGE_NAME" ];then
        green_echo "===Update musics==="
        rm -fr /tmp/musics*
        tar -xvf  $MUSIC_IMAGE_NAME -C /tmp/
        mv /res/musics /tmp/musics-bak
        rm -rf /res/musics*
        mv /tmp/musics /res/
        sync
    else
        return 1
    fi

    return 0
}

doorbell_ota()
{
    asetprop sys.dfu_progress 90
    local doorbell_dfu_timeout=0
    local dfu_ready="$(agetprop persist.app.doorbell_dfu_ready)"
    while [ $doorbell_dfu_timeout -le  $DOORBELL_DFU_TIMEOUT ]; do
        [ $(($doorbell_dfu_timeout % 2)) -eq 0 ] && green_echo "waiting for doorbell ota...time remaining:$(($DOORBELL_DFU_TIMEOUT - $doorbell_dfu_timeout))"
        dfu_ready="$(agetprop persist.app.doorbell_dfu_ready)"
        if [ "$dfu_ready" = "false" ]; then
            return 0
        fi

        let doorbell_dfu_timeout++
        sleep 1
    done
    asetprop sys.dfu_progress 95
    return 1
}

make_backup_of_doorbell_dfu()
{
    local dfu_ready="$(agetprop persist.app.doorbell_dfu_ready)"
    if [ "$dfu_ready" != "true" ]; then
        green_echo "doorbell dfu is not ready, skip backup"
        return
    fi

    if [ -f $DOORBELL_DFU_IMAGE_FULL_NAME ]; then
        green_echo "make backup of doorbell_dfu image"
        mv $DOORBELL_DFU_IMAGE_FULL_NAME $DOORBELL_DFU_BACK_IMAGE_FULL_NAME
        local dfu_ver="$(agetprop persist.app.doorbell_dfu_ver)"
        local dfu_md5="$(agetprop persist.app.doorbell_dfu_md5)"
        local dfu_size="$(agetprop persist.app.doorbell_dfu_size)"
        if [ "x$dfu_ver" != "x" -a "x$dfu_md5" != "x" -a "x$dfu_size" != "x" ]; then
            echo "persist.app.doorbell_dfu_ver=$dfu_ver"   > $DOORBELL_DFU_BACK_PROP_FULL_NAME
            echo "persist.app.doorbell_dfu_md5=$dfu_md5"   >> $DOORBELL_DFU_BACK_PROP_FULL_NAME
            echo "persist.app.doorbell_dfu_size=$dfu_size" >> $DOORBELL_DFU_BACK_PROP_FULL_NAME
        else
            red_echo "read doorbell_dfu_xxx failed, property not exist!"
        fi
    else
        green_echo "the doorbell image : ${DOORBELL_DFU_IMAGE_FULL_NAME} dose not exist!"
    fi
}


#
# check doorbell image
# return -- 0 save succeed
#        -- 1 doorbell image not exist
#        -- 2 doorbell image is not valid
#
check_doorbell_image()
{
    green_echo "save doorbell image"

    local doorbell_img_path=$(find $UPGRADE_IMAGES_DIR -name doorbell_firmware_*.bin)
    if [ "x$doorbell_img_path" = "x" ]; then
        echo "doorbell image is not exist!!!"
        return 1
    fi

    [ ! -d $DOORBELL_DFU_DIR ] && mkdir -p $DOORBELL_DFU_DIR

    if [ -f $DOORBELL_DFU_IMAGE_FULL_NAME ]; then
        rm -f $DOORBELL_DFU_IMAGE_FULL_NAME
        asetprop persist.app.doorbell_dfu_ver
        asetprop persist.app.doorbell_dfu_size
        asetprop persist.app.doorbell_dfu_md5
        asetprop persist.app.doorbell_dfu_name
        asetprop persist.app.doorbell_dfu_ready "false"
    fi

    local ver="$(echo $doorbell_img_path)"
    ver=${ver##*/}
    ver=${ver:18:10}

    mv $doorbell_img_path $DOORBELL_DFU_IMAGE_FULL_NAME

    local md5="$(md5sum $DOORBELL_DFU_IMAGE_FULL_NAME)"
    local size="$(stat $DOORBELL_DFU_IMAGE_FULL_NAME | grep Size | awk '{print $2}')"
    local md5_tail="$(md5sum $DOORBELL_DFU_IMAGE_FULL_NAME | awk '{a=substr($1,27,6); print a}')"
    local expect_md5="$(echo $doorbell_img_path)"
    expect_md5=${expect_md5##*/}
    expect_md5=${expect_md5:29:6}

    green_echo "local doorbell image md5:$md5_tail, expect:$expect_md5"

    if [ "$md5_tail" != "$expect_md5" ]; then asetprop sys.dfu_progress -1; fi

    # Check result
    update_block
    if [ $? -eq 1 ]; then red_echo "doorbell image is not valid!"; return 2; fi

    green_echo "sync doorbell firmware..."

    sync;sync


    asetprop persist.app.doorbell_dfu_ver $ver
    asetprop persist.app.doorbell_dfu_size $size
    asetprop persist.app.doorbell_dfu_md5 $md5
    asetprop persist.app.doorbell_dfu_name "$DOORBELL_DFU_IMAGE_NAME"
    green_echo "sync doorbell firmware finished"

    return 0
}


#
# return 0 - succeed
#        1 - backup is not valid
#
restore_doorbell_dfu_backup()
{

    local doorbell_image_md5="$(md5sum $DOORBELL_DFU_BACK_IMAGE_FULL_NAME | cut -d' ' -f 1)"
    local md5="$(cat $DOORBELL_DFU_BACK_PROP_FULL_NAME | grep persist.app.doorbell_dfu_md5 | cut -d'=' -f 2)"

    if [ "$doorbell_image_md5" != "$md5" ]; then
        red_echo "doorbell dfu backup image is not valid, remove it!"
        rm $DOORBELL_DFU_BACK_IMAGE_FULL_NAME
        rm $DOORBELL_DFU_BACK_PROP_FULL_NAME
        return 1
    fi

    mv $DOORBELL_DFU_BACK_IMAGE_FULL_NAME $DOORBELL_DFU_IMAGE_FULL_NAME
    local ver="$(cat $DOORBELL_DFU_BACK_PROP_FULL_NAME | grep persist.app.doorbell_dfu_ver | cut -d'=' -f 2)"
    local size="$(cat $DOORBELL_DFU_BACK_PROP_FULL_NAME | grep persist.app.doorbell_dfu_size | cut -d'=' -f 2)"
    asetprop persist.app.doorbell_dfu_ver "$ver"
    asetprop persist.app.doorbell_dfu_md5 "$md5"
    asetprop persist.app.doorbell_dfu_size "$size"
    asetprop persist.app.doorbell_dfu_name "$DOORBELL_DFU_IMAGE_NAME"

    rm $DOORBELL_DFU_BACK_PROP_FULL_NAME
    green_echo "restore doorbell dfu image from backup succeed"
    return 0
}



check_backup_of_doorbell_dfu_and_restore()
{
    # Check doorbell image backup info
    local dfu_pending=$(agetprop persist.app.dfu_pending)
    if [ x"$dfu_pending" = x"true" -a -f $DOORBELL_DFU_BACK_IMAGE_FULL_NAME -a -f $DOORBELL_DFU_BACK_PROP_FULL_NAME ]; then
        green_echo "restore doorbell dfu backup info"
        restore_doorbell_dfu_backup
    fi
}

set_def_env()
{
    /etc/fw_setenv mtdparts 'mtdparts=nand0:1664k@0x140000(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),1m(factory),20m(RES),-(UBI)'
    /etc/fw_setenv bootargs "root=/dev/mtdblock7 rootfstype=squashfs ro init=/linuxrc LX_MEM=0x3FE0000 mma_heap=mma_heap_name0,miu=0,sz=0x200000 cma=2M mtdparts=nand0:1664k@0x140000(BOOT0),1664k(BOOT1),256k(ENV),256k(ENV1),128k(KEY_CUST),5m(KERNEL),5m(KERNEL_BAK),16m(rootfs),16m(rootfs_bak),1m(factory),20m(RES),-(UBI)"
    /etc/fw_setenv bootcmd "nand read.e 0x22000000 KERNEL 0x500000; dcache on; bootlogo 0 0 0 0; bootm 0x22000000;nand read.e 0x22000000 KERNEL_BAK 0x500000; dcache on; bootm 0x22000000"

}

check_env()
{
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

    check_env


    # Check if doorbell image already exists, make a backup
    make_backup_of_doorbell_dfu

    asetprop persist.app.doorbell_dfu_ready "false"

    asetprop sys.dfu_progress 75

    check_doorbell_image
    local doorbell_image_result=$?
    if [ $doorbell_image_result -eq 2 ];then
        red_echo "doorbell image check failed"
        return 1
    fi

    asetprop sys.dfu_progress 80
    flash_kernel
    local flash_kernel_result=$?
    if [ $flash_kernel_result -ne 0 ]; then
        red_echo "flash kernel failed!"
    fi

    asetprop sys.dfu_progress 85
    flash_rootfs
    local flash_rootfs_result=$?
    if [ $flash_rootfs_result -ne 0 ]; then
        red_echo "flash rootfs failed!"
    fi

    asetprop sys.dfu_progress 90
    flash_uboot
    local flash_uboot_result=$?
    if [ $flash_uboot_result -ne 0 ]; then
        red_echo "flash uboot failed!"
    fi

    if [ $flash_kernel_result -ne 0 -o $flash_rootfs_result -ne 0  ];then
        # restore doorbell dfu image from backup
        if [ -f $DOORBELL_DFU_BACK_IMAGE_FULL_NAME ]; then
            restore_doorbell_dfu_backup
        fi

        return 1
    fi

    asetprop sys.dfu_progress 95
    flash_ai
    local flash_ai_result=$?
    if [ $flash_ai_result -eq 1 ]; then
        green_echo "no need flash ai lib!"
    fi

    asetprop sys.dfu_progress 98
    flash_musics

    # after kernel and rootfs flash succeed, remove doorbell backup info
    [ -f $DOORBELL_DFU_BACK_IMAGE_FULL_NAME ] && rm $DOORBELL_DFU_BACK_IMAGE_FULL_NAME
    [ -f $DOORBELL_DFU_BACK_PROP_FULL_NAME  ] && rm $DOORBELL_DFU_BACK_PROP_FULL_NAME

    if [ $doorbell_image_result -eq 1 ]; then
        asetprop sys.dfu_progress 100
        green_echo "update all success, skip doorbell ota because of empty doorbell image"
        return 0
    fi

    green_echo "remove backup because of rootfs/kernel flash succeed"

    local doorbell_linked="$(agetprop sys.doorbell_linked)"
    local doorbell_alive="$(agetprop sys.doorbell_alive)"

    asetprop persist.app.doorbell_dfu_ready "true"
    green_echo "set property doorbell ready succeed if exists"

    if [ "$doorbell_linked" = "true" -o "$doorbell_alive" = "true" ]; then
        doorbell_ota
        if [ $? -ne 0 ];then
            red_echo "doorbell ota timeout, set property: persist.app.doorbell_dfu_status = 0"
            asetprop persist.app.doorbell_dfu_status 0
        fi
    else
        green_echo "doorbell is not alive or online, set property: persist.app.doorbell_dfu_status = 0"
        asetprop persist.app.doorbell_dfu_status 0
    fi

    asetprop sys.dfu_progress 100

    green_echo "===Update ALL Success==="

    return 0
}

update_failed()
{
    local platform="$1"
    local errmsg="$2"
    local clean="$3"

    green_echo "Update failed, reason: $errmsg"

    if [ "$clean" = "true" ]; then update_clean; fi

    if [ "$platform" = "miot" ]; then asetprop sys.dfu_progress -33005;
    else asetprop sys.dfu_progress -1; fi
}

update_done()
{
    set_kernel_partitions "$KERNEL_PARTITION"
    set_rootfs_partitions "$ROOTFS_PARTITION"
    update_clean
    asetprop sys.dfu_progress 100
    sleep 7
#    reboot
    green_echo ""
    green_echo "Update Done, Please manually reboot!"
}

#
# Document helper.
#
helper()
{
    local cmd="$1"

    case $cmd in
        -u) usage_updater  ;;

        -h) usage_helper   ;;
    esac

    return 0
}

# Restart the process that was killed before upgrade
dfu_post()
{
    ${DFU_POST_CMD}
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
    green_echo "Updating $VERSION"

    # Prepare...
    update_prepare "$path"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "Not enough storage available!";
        dfu_post
        return 1
    fi

    # Get DFU package and check it.
    update_get_packages "$platform" "$path" "$sign"
    if [ $? -ne 0 ]; then
        update_failed "$platform" "unpack failed!" "true"
        dfu_post
        return 1
    fi

    update_before_start "$platform"

    update_start "$platform"
    if [ $? -eq 0 ]; then
        update_done;
    else
        update_failed "$platform" "OTA failed!" "true";
        dfu_post
    fi
    return 0
}

#
# Initial params.
#
initial()
{
    # In order to avoid the data space being full due to the last failed ota operation,
    # we should clear the residual files of the last failed ota
    if [ -d $UPGRADE_UNPACK_DIR ]; then rm -rf $UPGRADE_UNPACK_DIR; fi
    if [ -d $UPGRADE_IMAGES_DIR ]; then rm -rf $UPGRADE_IMAGES_DIR; fi

    # Wait for the property service to be ready
    wait_property_svr_ok

    local exit_flag=1

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
    product=`agetprop ro.sys.model`

    model="AH_G4"

    green_echo "type: $product, model: $model"

    if [ "$product" != "lumi.camera.acn005" ]; then
        echo "This is not supported G4 and exit!"
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
