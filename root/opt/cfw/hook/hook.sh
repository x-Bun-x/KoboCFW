#!/bin/sh

event=$1
if [ -z "$event" ]; then
    exit 0;
fi

run-parts /opt/cfw/hook/$event
