#!/bin/sh

MNG_FILE="/mnt/onboard/.images/dbupdate.mng"
source /opt/cfw/scripts/common.sh

PRODUCT=`/bin/kobo_config.sh`;
[ $PRODUCT != trilogy ] && PREFIX=$PRODUCT-

trap_term_handler() {
	usleep 1
	trap '' TERM
	killall fbmngplay
	exit 1
}

trap trap_term_handler TERM

if [ -f /mnt/onboard/.images/dbupdate.png ]; then
	/opt/cfw/bin/png2raw -K -ta /mnt/onboard/.images/dbupdate.png
fi

if [ -f ${ThemeConfig} ]; then
	source $ThemeConfig
	FBMNGOption=$dbUpdateMngOption
else
	FBMNGOption="-d 100 -w"
fi

if [ -f ${MNG_FILE} ]; then
	/opt/cfw/bin/fbmngplay $FBMNGOption $MNG_FILE & wait
else
	/opt/cfw/bin/fbmngplay $FBMNGOption /etc/images/$PREFIX\update-data.mng & wait
fi

