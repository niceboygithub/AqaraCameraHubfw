# Aqara Hub E1 (ZHWG16LM) Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash E1 Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/e1_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/E1/e1_update.sh
chmod a+x /tmp/e1_update.sh && /tmp/e1_update.sh
```
<img src="https://raw.githubusercontent.com/niceboygithub/AqaraGateway/master/E1_flash_done.png">
