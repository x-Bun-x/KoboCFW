#!/bin/sh

source /opt/cfw/scripts/common.sh

if [ ! -f ${CONFIG_FILE} ]; then
	exit 0 
fi

source $CONFIG_FILE

if [ "$FontSettingReset" == "ON" ]; then
	$DBEXE $DBFILE "DELETE FROM content_settings WHERE content_settings.ContentID NOT LIKE '%$FontSettingTemplate%';"
fi

/opt/cfw/scripts/contentupdate.sh

if [ "$StoreBookInsertShelf" != "OFF" -o "$UserBookInsertShelf" != "OFF" -o "$BookShelfReCreate" != "OFF" ]; then
	/opt/cfw/scripts/createbookshelf.sh
fi

/opt/cfw/scripts/recentlyreading.sh
