#!/bin/sh

MNG_FILE="/mnt/onboard/.images/dbrebuild.mng"
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

if [ -f /mnt/onboard/.images/dbrebuild.png ]; then
	/opt/cfw/bin/png2raw-12 -K -ta /mnt/onboard/.images/dbrebuild.png
fi

if [ -f ${ThemeConfig} ]; then
	source $ThemeConfig
	FBMNGOption=$dbRebuildOption
else
	FBMNGOption="-d 100 -w"
fi

if [ -f ${MNG_FILE} ]; then
	/opt/cfw/bin/fbmngplay $FBMNGOption $MNG_FILE & wait
else
	/opt/cfw/bin/fbmngplay $FBMNGOption /etc/images/$PREFIX\rebuilddb.mng & wait
fi
