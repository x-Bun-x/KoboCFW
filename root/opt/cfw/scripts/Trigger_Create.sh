#!/bin/sh

source /opt/cfw/scripts/common.sh

if [ ! -f ${CONFIG_FILE} ]; then
	exit 0 
fi

source $CONFIG_FILE

SQLCOMFILE=`mktemp -t`

echo "CREATE TRIGGER [TRIGGER_RecentlyReadingBookshelf] AFTER " > $SQLCOMFILE
echo "UPDATE OF [DateLastRead] ON [content] FOR EACH ROW " >> $SQLCOMFILE
echo "BEGIN" >> $SQLCOMFILE
echo "    DELETE FROM ShelfContent WHERE ShelfName = ' 最近読んでいる本棚';" >> $SQLCOMFILE
echo "    INSERT INTO ShelfContent " >>$SQLCOMFILE
echo "	    SELECT " >>$SQLCOMFILE
echo "		' 最近読んでいる本棚',ShelfContent.ContentID, " >>$SQLCOMFILE
echo "		    STRFTIME('%Y-%m-%dT%H:%M:%f','now'),'false','false' " >>$SQLCOMFILE
echo "	    FROM " >>$SQLCOMFILE
echo "		    ShelfContent " >>$SQLCOMFILE
echo "	    INNER JOIN content ON " >>$SQLCOMFILE
echo "		    ShelfContent.ContentID = content.ContentID AND " >>$SQLCOMFILE
echo "	        content.ContentType = 6 AND content.Accessibility <= 1 AND  " >>$SQLCOMFILE
echo "		    content.___ExpirationStatus <> 3 AND  " >>$SQLCOMFILE
echo "	        IFNULL(content.___FileSize,0) > 0  " >>$SQLCOMFILE
if [ "$RecentlyReadingTarget" == "NOREAD" ]; then
	#NoRead Data Only
	echo "    AND content.ReadStatus = 0 " >>$SQLCOMFILE
elif [ "$RecentlyReadingTarget" == "READING" ]; then
	#NoRead And Reading Book
	echo "    AND content.ReadStatus <= 1 " >>$SQLCOMFILE
fi
echo "	    WHERE " >>$SQLCOMFILE
echo "		    ShelfContent.ShelfName IN " >>$SQLCOMFILE
echo "		(    SELECT ShelfContent.ShelfName FROM ShelfContent " >>$SQLCOMFILE
echo "		    INNER JOIN " >>$SQLCOMFILE
echo "		(    SELECT content.ContentID FROM content " >>$SQLCOMFILE
echo "		    WHERE  " >>$SQLCOMFILE
echo "		        content.ContentType = 6 AND content.Accessibility <= 1 AND  " >>$SQLCOMFILE
echo "			    content.___ExpirationStatus <> 3 AND  " >>$SQLCOMFILE
echo "		        IFNULL(content.___FileSize,0) > 0 " >>$SQLCOMFILE
echo "		    ORDER BY " >>$SQLCOMFILE
echo "			    content.DateLastRead DESC " >>$SQLCOMFILE
echo "		    LIMIT 1) AS SUB1 ON " >>$SQLCOMFILE
echo "		    ShelfContent.ContentID = SUB1.ContentID); " >>$SQLCOMFILE
echo "END;" >> $SQLCOMFILE

cat $SQLCOMFILE | $DBEXE $DBFILE

#if [ "$DebugMode" == "ON" ]; then
#	cp $SQLCOMFILE /mnt/onboard/trigger.tmp
#fi

rm -rf $SQLCOMFILE
