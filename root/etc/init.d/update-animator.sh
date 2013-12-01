#!/bin/sh

MNG_FILE="/mnt/onboard/.images/update.mng"
source /opt/cfw/scripts/common.sh

PRODUCT=`/bin/kobo_config.sh`;
[ $PRODUCT != trilogy ] && PREFIX=$PRODUCT-

if [ -f /mnt/onboard/.images/update.png ]; then
	/opt/cfw/bin/png2raw-12 -K -ta /mnt/onboard/.images/update.png
fi

if [ -f ${MNG_FILE} ]; then
	trap_term_handler() {
		usleep 1
		trap '' TERM
		killall fbmngplay
		exit 1
	}

	trap trap_term_handler TERM

	if [ -f ${ThemeConfig} ]; then
		source $ThemeConfig

		FBMNGOption=$KoboUpdateMngOption
	else
		FBMNGOption="-d 100 -w"
	fi

	/opt/cfw/bin/fbmngplay $FBMNGOption $MNG_FILE & wait

else
	i=0;
	while true; do
        i=$((((i + 1)) % 6));
        zcat /etc/images/$PREFIX\update-spinner-$i.raw.gz | /usr/local/Kobo/pickel showpic 1;
        usleep 500000;
	done 
fi

