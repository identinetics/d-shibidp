#!/usr/bin/env bash

echo
lsof -i -P -sTCP:LISTEN
echo
ps -eaf | head -1
ps -eaf | grep 'java ' | grep -v ' grep ' | cut -c -165
echo
