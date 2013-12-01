#!/bin/sh

source /opt/cfw/scripts/common.sh

if [ ! -f ${CONFIG_FILE} ]; then
	exit 0 
fi

SQLCOMFILE=`mktemp -t`

/opt/cfw/scripts/ChangeJournalMode.sh OFF

echo "REINDEX; " >$SQLCOMFILE
echo "ANALYZE; " >>$SQLCOMFILE
echo "VACUUM; " >>$SQLCOMFILE

cat $SQLCOMFILE | $DBEXE $DBFILE

rm -rf $SQLCOMFILE

/opt/cfw/scripts/ChangeJournalMode.sh ON

