#!/usr/bin/env bash

echo
lsof -i -P -sTCP:LISTEN
echo
ps -ef | head -1
ps -ef | grep 'java ' | grep -v ' grep ' | cut -c -165
echo
