# Aqara Doorbell G4 Firmware

Note that flashing firmware is USING AT YOUR OWN RISK.
## Flash Doorbell G4 Custom firmware method

```shell
cd /tmp && wget -O /tmp/curl "http://master.dl.sourceforge.net/project/aqarahub/binutils/curl?viasf=1" && chmod a+x /tmp/curl
/tmp/curl -s -k -L -o /tmp/g4_update.sh https://raw.githubusercontent.com/niceboygithub/AqaraCameraHubfw/main/modified/G4/g4_update.sh
chmod a+x /tmp/g4_update.sh && /tmp/g4_update.sh
```
