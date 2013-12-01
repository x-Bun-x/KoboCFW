#!/bin/sh

source /opt/cfw/scripts/common.sh

$DBEXE $DBFILE "UPDATE content SET ___UserID='kepub_user' WHERE ___UserID='' AND ContentType=6 AND Accessibility <= 1 AND MimeType='application/x-kobo-epub+zip';"
