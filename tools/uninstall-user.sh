#!/bin/bash
#
# uninstall-user.sh

BINDIR="/home/steam/bin"
DATADIR="/home/steam/.local/share/shadowbound"

for f in "${BINDIR}/shadowbound" \
         "${DATADIR}/uninstall.sh" \
         "${DATADIR}/sbrconclient.py"
do
    if [ -f "$f" ]; then
        rm "$f"
    fi
done
