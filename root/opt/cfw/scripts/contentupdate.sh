#!/bin/sh

source /opt/cfw/scripts/common.sh

if [ ! -f ${CONFIG_FILE} ]; then
	exit 0 
fi

source $CONFIG_FILE

TMPFILE=`mktemp -t`
SQLCOMFILE=`mktemp -t`
SQLCOMFILE2=`mktemp -t`
saveifs=$IFS

IFS="*"

echo "OFF" > $ResultFile

# Update Attribution
echo ".separator '$IFS'" >$SQLCOMFILE
echo "SELECT RowID,Title FROM content " >>$SQLCOMFILE
echo "WHERE " >>$SQLCOMFILE
echo "ContentType = 6 AND Accessibility <= 1 AND " >>$SQLCOMFILE
echo "(Attribution='著者不明' OR Attribution='' OR IFNULL(Attribution,'') = '') AND " >>$SQLCOMFILE
echo "(MimeType='application/x-cbz' OR MimeType='application/x-cbr' OR MimeType='application/pdf');" >>$SQLCOMFILE

cat $SQLCOMFILE | $DBEXE $DBFILE | sed -e "s/$IFS\[\(.\+\)\] \?\(.\+\)/$IFS\2$IFS\1/g" -e "t" -e "s/\$/$IFS-/g" >$TMPFILE

echo "BEGIN TRANSACTION;" >$SQLCOMFILE

cat $TMPFILE | while read rowid title attr; 
do
	if [ "$attr" != "-" ]; then
		title=`echo $title | sed -e "s/'/''/g" -`
		attr=`echo $attr | sed -e "s/'/''/g" -`

		echo "UPDATE content SET Title='$title',Attribution='$attr' WHERE RowId=$rowid;" >>$SQLCOMFILE

		echo "ON" > $ResultFile
	fi
done

#Page Direction Update
if [ "$UpdatePDFPageDirection" == "ON" ]; then
	echo ".separator '$IFS'" >$SQLCOMFILE2
	echo "SELECT RowID FROM content " >>$SQLCOMFILE2
	echo "WHERE PageProgressDirection='default' AND " >>$SQLCOMFILE2
	echo "ContentType = 6 AND Accessibility <= 1 AND ___ExpirationStatus <> 3 AND " >>$SQLCOMFILE2
	echo "content .___UserID <>'' AND SUBSTR(ContentID,1,18) <> 'file:///usr/local/' AND" >>$SQLCOMFILE2
	echo "IFNULL(content.___FileSize,0) > 0 AND " >>$SQLCOMFILE2
	echo "(MimeType='application/x-cbz' OR MimeType='application/pdf' OR MimeType='application/x-cbr');" >>$SQLCOMFILE2

	cat $SQLCOMFILE2 | $DBEXE $DBFILE >$TMPFILE

	cat $TMPFILE | while read rowid; 
	do
		echo "UPDATE content SET PageProgressDirection='rtl', EpubType=13 WHERE RowId=$rowid; " >>$SQLCOMFILE

		echo "ON" > $ResultFile
	done
fi

#Font Setting Update
if [ "$FontSettingUpdate" != "OFF" -a "$FontSettingTemplate" != "" ]; then
	echo ".separator '$IFS'" >$SQLCOMFILE2
	echo "SELECT  " >>$SQLCOMFILE2
	echo "    SUB1.*,SUB2.* " >>$SQLCOMFILE2
	echo "FROM " >>$SQLCOMFILE2
	echo "    (SELECT " >>$SQLCOMFILE2
	echo "        STRFTIME('%Y-%m-%dT%H:%MZ','now'), " >>$SQLCOMFILE2
	echo "        content_settings.ReadingFontFamily,  " >>$SQLCOMFILE2
	echo "        content_settings.ReadingFontSize,  " >>$SQLCOMFILE2
	echo "        content_settings.ReadingAlignment,  " >>$SQLCOMFILE2
	echo "        content_settings.ReadingLineHeight,  " >>$SQLCOMFILE2
	echo "        content_settings.ReadingLeftMargin,  " >>$SQLCOMFILE2
	echo "        content_settings.ReadingRightMargin,  " >>$SQLCOMFILE2
	echo "        content_settings.ReadingPublisherMode,  " >>$SQLCOMFILE2
	echo "        content_settings.ActivityFacebookShare " >>$SQLCOMFILE2
	echo "    FROM " >>$SQLCOMFILE2
	echo "        content_settings " >>$SQLCOMFILE2
	echo "    INNER JOIN content ON " >>$SQLCOMFILE2
	echo "        content_settings.ContentID=content.ContentID AND  " >>$SQLCOMFILE2
	echo "        content_settings.ContentType=content.ContentType " >>$SQLCOMFILE2
	echo "    WHERE " >>$SQLCOMFILE2
	echo "        content.ContentID LIKE '%$FontSettingTemplate%' " >>$SQLCOMFILE2
	echo "    LIMIT 1) AS SUB2 " >>$SQLCOMFILE2
	echo "INNER JOIN " >>$SQLCOMFILE2
	echo "    (SELECT " >>$SQLCOMFILE2
	echo "        content.ContentID,content.ContentType " >>$SQLCOMFILE2
	echo "    FROM " >>$SQLCOMFILE2
	echo "        content " >>$SQLCOMFILE2
	echo "    WHERE " >>$SQLCOMFILE2
	echo "        ContentType = 6 AND Accessibility <= 1 AND ___ExpirationStatus <> 3 AND " >>$SQLCOMFILE2
	echo "        IFNULL(content.___FileSize,0) > 0 AND " >>$SQLCOMFILE2

	if [ "$FontSettingUpdate" == "NOREAD" ]; then
		echo "        ReadStatus = 0 AND  " >>$SQLCOMFILE2
	elif [ "$FontSettingUpdate" == "READING" ]; then
		echo "        ReadStatus <= 1 AND  " >>$SQLCOMFILE2
	else
		echo "        1 = 1 AND  " >>$SQLCOMFILE2
	fi

	echo "        MimeType='application/x-kobo-epub+zip' AND " >>$SQLCOMFILE2
	echo "        content.ContentID NOT IN(SELECT ContentID FROM content_settings) " >>$SQLCOMFILE2
	echo "        ) AS SUB1; " >>$SQLCOMFILE2

	cat $SQLCOMFILE2 | $DBEXE $DBFILE >$TMPFILE

	cat $TMPFILE | while read contentid contenttype nowdate ReadingFontFamily ReadingFontSize ReadingAlignment ReadingLineHeight ReadingLeftMargin ReadingRightMargin ReadingPublisherMode ActivityFacebookShare;
	do
		echo "INSERT INTO content_settings " >>$SQLCOMFILE
		echo "SELECT '$contentid','$contenttype','$nowdate','$ReadingFontFamily','$ReadingFontSize'," >>$SQLCOMFILE
		echo "    '$ReadingAlignment','$ReadingLineHeight','$ReadingLeftMargin','$ReadingRightMargin'," >>$SQLCOMFILE
		echo "    '$ReadingPublisherMode','$ActivityFacebookShare';" >>$SQLCOMFILE
	done
fi

echo "COMMIT TRANSACTION;" >>$SQLCOMFILE

#Execute Query
cat $SQLCOMFILE | $DBEXE $DBFILE

IFS=$saveifs

#if [ "$DebugMode" == "ON" ]; then
#	cp $SQLCOMFILE /mnt/onboard/content_sql.tmp
#	cp $SQLCOMFILE2 /mnt/onboard/content_sql2.tmp
#	cp $TMPFILE /mnt/onboard/content_sqlresult.tmp
#	cp $ResultFile /mnt/onboard/result.tmp
#fi

ResultStatus=`cat $ResultFile`

rm -rf $TMPFILE
rm -rf $SQLCOMFILE
rm -rf $SQLCOMFILE2
rm -rf $ResultFile


if [ "$ResultStatus" == "ON" ]; then
	exit 1
else
	exit 0
fi
