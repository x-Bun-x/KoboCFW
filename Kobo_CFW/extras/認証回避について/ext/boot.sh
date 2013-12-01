#!/bin/sh

source /opt/cfw/scripts/common.sh

cat /mnt/onboard/ext/authenticationbypass.sql | $DBEXE $DBFILE
