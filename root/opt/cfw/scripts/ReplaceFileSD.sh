#!/bin/sh

source /opt/cfw/scripts/common.sh

if [ ! -f ${CONFIG_FILE} ]; then
	exit 0 
fi

source $CONFIG_FILE
mount -r -o remount,rw /mnt/sd


if [ "$AutoConvertZip2CBZ" == "ON" ]; then
	/opt/cfw/scripts/convert_extension.sh zip cbz /mnt/sd
	/opt/cfw/scripts/convert_extension.sh rar cbr /mnt/sd
fi

if [ "$AutoConvertText2HTML" == "ON" ]; then
	/opt/cfw/scripts/convert_txt2html.sh txt html /mnt/sd
fi
mount -r -o remount,ro /mnt/sd
