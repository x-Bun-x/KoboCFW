#!/bin/sh

PRODUCT=`/bin/kobo_config.sh`;
[ $PRODUCT != trilogy ] && PREFIX=$PRODUCT-

zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic

/opt/cfw/bin/fbmngplay /mnt/onboard/.images/test.mng &
sleep 20
killall fbmngplay

zcat /etc/images/$PREFIX\ghostbuster.raw.gz | /usr/local/Kobo/pickel showpic
