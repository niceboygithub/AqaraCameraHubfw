#!/bin/sh

wait_for_h264_ready() {
    while true; do
        sleep 1
        if [ -e "/proc/mstar/OMX/VMFE0/ENCODER_INFO/OBUF_pBuffer" ]; then
            break
        fi
    done
}

wait_for_h264_fifo_ready() {
    tmp=$1
    cmd=$2
    while true; do
        $cmd &
        sleep 1
        if [ -e $tmp ]; then
            break
        fi
    done
}

wait_for_h264_ready

model=$(cat /etc/miio/device.conf  | grep "model=" | cut -d "=" -f 2)

if [ -p "/tmp/h264_low_fifo" ]; then
    rm -rf /tmp/h264_low_fifo
fi

if [ -p "/tmp/h264_high_fifo" ]; then
    rm -rf /tmp/h264_high_fifo
fi

if [ "x$model" == "xlumi.camera.gwagl01" ]; then
    wait_for_h264_fifo_ready /tmp/h264_low_fifo "h264grabber -r LOW -f"
    RRTSP_RES=1 rRTSPServer &
else
    wait_for_h264_fifo_ready /tmp/h264_high_fifo "h264grabber -f"
    rRTSPServer &
fi