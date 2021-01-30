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
    while true; do
        sleep 1
        if [ -e $1 ]; then
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
    h264grabber -r LOW -f &
    wait_for_h264_fifo_ready /tmp/h264_low_fifo
    RRTSP_RES=1 rRTSPServer &
else
    h264grabber -f &
    wait_for_h264_fifo_ready /tmp/h264_high_fifo
    rRTSPServer &
fi