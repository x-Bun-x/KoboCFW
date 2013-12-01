#!/bin/sh

source /opt/cfw/scripts/common.sh

if [ ! -f ${CONFIG_FILE} ]; then
	exit 0 
fi

source $CONFIG_FILE

TMPFILE=`mktemp -t`
SQLCOMFILE=`mktemp -t`
saveifs=$IFS

IFS="*"

#Delete Shelf And ShelfContent
if [ "$BookShelfReCreate" == "ON" ]; then
	echo "BEGIN TRANSACTION;" >$SQLCOMFILE
	echo "DELETE FROM Shelf WHERE IFNULL(Type,'') <> 'Custom'; " >>$SQLCOMFILE
	echo "UPDATE Shelf SET _IsDeleted = 'true' WHERE Type = 'Custom'; " >>$SQLCOMFILE
	echo "DELETE FROM ShelfContent; " >>$SQLCOMFILE
	echo "COMMIT TRANSACTION;" >>$SQLCOMFILE

	#Execute Delete Query
	cat $SQLCOMFILE | $DBEXE $DBFILE
fi

if [ "$StoreBookInsertShelf" != "OFF" -o "$UserBookInsertShelf" != "OFF" -o "$BookShelfReCreate" == "ON" ]; then
	#Select Target Books
	echo ".separator '$IFS'" >$SQLCOMFILE
	echo "SELECT DISTINCT " >>$SQLCOMFILE
	echo "REPLACE(ContentID,'file://','') AS pathname,ContentID,IFNULL(Series,'') AS Series," >>$SQLCOMFILE

	if [ "$UnKnownAttributionShelfName" != "" ]; then
		echo "(CASE " >>$SQLCOMFILE
		echo "    WHEN IFNULL(content.Attribution,'') ='' OR content.Attribution = '著者不明' OR content.Attribution = '' THEN '$UnKnownAttributionShelfName' " >>$SQLCOMFILE
		echo "    ELSE content.Attribution " >>$SQLCOMFILE
		echo "END), " >>$SQLCOMFILE
	else
		echo "content.Attribution, " >>$SQLCOMFILE
	fi

	echo "(CASE " >>$SQLCOMFILE
	echo "    WHEN IFNULL(user.UserID,'') = '' THEN 'USERDATA' " >>$SQLCOMFILE
	echo "    ELSE 'STOREDATA' " >>$SQLCOMFILE
	echo "END) AS BookType,IFNULL(Publisher,'') AS Publisher" >>$SQLCOMFILE
	echo "FROM content " >>$SQLCOMFILE
	echo "LEFT JOIN user ON content .___UserID = user.UserID " >>$SQLCOMFILE

	echo "WHERE " >>$SQLCOMFILE
	echo "ContentType = 6 AND Accessibility <= 1 AND ___ExpirationStatus <> 3 AND " >>$SQLCOMFILE
	echo "content .___UserID <>'' AND SUBSTR(ContentID,1,18) <> 'file:///usr/local/' AND" >>$SQLCOMFILE

	#Target Device Select
	if [ "$CreateShelfDevice" == "1" ]; then
		# Only InternalStrage
		echo "SUBSTR(ContentID,1,15) <> 'file:///mnt/sd/' AND " >>$SQLCOMFILE
	elif [ "$CreateShelfDevice" == "2" ]; then
		# Only SD Card
		echo "SUBSTR(ContentID,1,15) = 'file:///mnt/sd/' AND " >>$SQLCOMFILE
	else
		# AllData
		echo "1 = 1 AND " >>$SQLCOMFILE
	fi

	#TargetBookType Select
	if [ "$StoreBookInsertShelf" == "OFF" -a "$UserBookInsertShelf" != "OFF" ]; then
		#UserCreate Data Only
		echo "IFNULL(user.UserID,'') = '' AND " >>$SQLCOMFILE
	elif [ "$StoreBookInsertShelf" != "OFF" -a "$UserBookInsertShelf" == "OFF" ]; then
		#Store Books Only
		echo "IFNULL(user.UserID,'') <> '' AND " >>$SQLCOMFILE
	elif [ "$StoreBookInsertShelf" == "OFF" -a "$UserBookInsertShelf" == "OFF" ]; then
		#Not Create
		echo "IFNULL(user.UserID,'') = 'DUMMY' AND " >>$SQLCOMFILE
	else
		#All Books
		echo "1 = 1 AND " >>$SQLCOMFILE
	fi

	echo "IFNULL(content.___FileSize,0) > 0 " >>$SQLCOMFILE
	echo "AND content.ContentID NOT LIKE '%$FontSettingTemplate%' " >>$SQLCOMFILE
	echo "AND content.ContentID NOT IN (SELECT ContentID FROM ShelfContent); " >>$SQLCOMFILE

	cat $SQLCOMFILE | $DBEXE $DBFILE  >$TMPFILE

	echo "BEGIN TRANSACTION;" >$SQLCOMFILE

	#Read TargetData
	cat $TMPFILE | while read pathname contentID series attribution bookType publisher; 
	do
		SHELFNAME=""

		if [ $bookType == "USERDATA" -a "$UserBookInsertShelf" != "OFF" ]; then
			FPATH=`dirname $pathname`
			LASTDIR=`basename $FPATH`

			if [ $LASTDIR == "onboard" -o $LASTDIR == "$InternalStrageBookFolder" -o $LASTDIR == "sd" ]; then
				LASTDIR=""
	        fi

			if [ $LASTDIR == "." ]; then
				LASTDIR=""
	        fi

			if [ "$UserBookInsertShelf" == "ATTR" ]; then
				SHELFNAME=$attribution
			elif [ "$UserBookInsertShelf" == "FOLDER" ]; then
				if [ $LASTDIR != "" ]; then
					SHELFNAME=$LASTDIR
				else
					SHELFNAME=$UnknownFolderShelfName
				fi
			elif [ "$UserBookInsertShelf" == "FIXED" ]; then
				if [ "$FixedShelfNameForUser" == "" ]; then
					FixedShelfNameForUser="ユーザー作成本"
				fi

				SHELFNAME=$FixedShelfNameForUser
			elif [ "$UserBookInsertShelf" == "MIXED1" ]; then
				if [ $LASTDIR != "" ]; then
					if [ $LASTDIR != $attribution ]; then
						SHELFNAME="$attribution - $LASTDIR -"
					else
						SHELFNAME="$attribution - $UnKnownFolderShelfName -"
					fi
				else
					SHELFNAME="$attribution - $UnKnownFolderShelfName -"
				fi
			elif [ "$UserBookInsertShelf" == "MIXED2" ]; then
				if [ $LASTDIR != "" ]; then
					if [ $LASTDIR != $attribution ]; then
						SHELFNAME="$LASTDIR - $attribution -"
					else
						SHELFNAME="$UnKnownFolderShelfName - $attribution -"
					fi
				else
					SHELFNAME="$UnKnownFolderShelfName - $attribution -"
				fi
			else
				SHELFNAME=""
			fi

			if [ $SHELFNAME == "" ]; then
				SHELFNAME=$OtherShelfName
			fi
		elif [ $bookType == "STOREDATA" -a "$StoreBookInsertShelf" != "OFF" ]; then
			if [ "$StoreBookInsertShelf" == "ATTR" ]; then
				SHELFNAME=$attribution
#			elif [ "$StoreBookInsertShelf" == "SERIES" ]; then
#				if [ $series != "" -a $series != "." ]; then
#					SHELFNAME=$series
#				else
#					SHELFNAME=""
#				fi
			elif [ "$StoreBookInsertShelf" == "FIXED" ]; then
				if [ "$FixedShelfNameForStore" == "" ]; then
					FixedShelfNameForStore="ストア購入本"
				fi

				SHELFNAME=$FixedShelfNameForStore
			elif [ "$StoreBookInsertShelf" == "PUBLISHER" ]; then
				if [ $publisher == "" ]; then
					SHELFNAME=""
				else
					SHELFNAME=$publisher
				fi
			else
				SHELFNAME=""
			fi

			if [ $SHELFNAME == "" ]; then
				SHELFNAME=$OtherShelfName
			fi
		fi

		if [ $SHELFNAME != "" ]; then
			SHELFNAME=`echo $SHELFNAME | sed -e "s/'/''/g" -`
			contentID=`echo $contentID | sed -e "s/'/''/g" -`
		    echo "INSERT INTO ShelfContent SELECT '$SHELFNAME','$contentID',STRFTIME('%Y-%m-%dT%H:%M:%f','now'),'false','false';" >>$SQLCOMFILE
		fi
	done

	#Create New Shelf
	echo "INSERT INTO Shelf " >>$SQLCOMFILE
	echo "SELECT  " >>$SQLCOMFILE
	echo "    STRFTIME('%Y-%m-%dT%H:%M:%f','now'), " >>$SQLCOMFILE
	echo "    Sub1.ShelfName,Sub1.ShelfName, " >>$SQLCOMFILE
	echo "    STRFTIME('%Y-%m-%dT%H:%M:%f','now'), " >>$SQLCOMFILE
	echo "    Sub1.ShelfName,NULL,'false','true','false' " >>$SQLCOMFILE
	echo "FROM " >>$SQLCOMFILE
	echo "	(SELECT DISTINCT " >>$SQLCOMFILE
	echo "	    ShelfContent.ShelfName " >>$SQLCOMFILE
	echo "	FROM " >>$SQLCOMFILE
	echo "	    ShelfContent " >>$SQLCOMFILE
	echo "	WHERE " >>$SQLCOMFILE
	echo "	    ShelfContent.ShelfName NOT IN(SELECT Name FROM Shelf WHERE _IsDeleted='false')) AS Sub1; " >>$SQLCOMFILE
	echo "COMMIT TRANSACTION;" >>$SQLCOMFILE

	#Execute ShelfCreate Query
	cat $SQLCOMFILE | $DBEXE $DBFILE
fi


IFS=$saveifs

#if [ "$DebugMode" == "ON" ]; then
#	cp $SQLCOMFILE /mnt/onboard/sql2.tmp
#	cp $TMPFILE /mnt/onboard/sqlresult2.tmp
#fi

rm -rf $TMPFILE
rm -rf $SQLCOMFILE
