#!/bin/bash
#
# uninstall.sh

BINDIR="/usr/bin"
DATADIR="/usr/share/shadowbound"
LIBEXECDIR="/usr/libexec/shadowbound"
INITSCRIPT=

if [ -f "/etc/rc.d/init.d/shadowbound" ]; then
	INITSCRIPT="/etc/rc.d/init.d/shadowbound"

	if [ -f "/etc/rc.d/init.d/functions" ]; then
		chkconfig shadowbound off
	fi
elif [ -f "/etc/init.d/shadowbound" ]; then
	INITSCRIPT="/etc/init.d/shadowbound"

	if [ -f "/lib/lsb/init-functions" ]; then
		update-rc.d -f shadowbound remove
	elif [ -f "/sbin/runscript" ]; then
		rc-update del shadowbound default
	fi
elif [ -f "/etc/systemd/system/shadowbound.service" ]; then
	INITSCRIPT="/etc/systemd/system/shadowbound.service"
	systemctl disable shadowbound.service
fi

if [ -n "$INITSCRIPT" ]; then
	for f in "${INITSCRIPT}" \
		"${BINDIR}/shadowbound" \
		"${LIBEXECDIR}/shadowbound.init" \
		"${LIBEXECDIR}/shadowbound-uninstall.sh"
	do
		if [ -f "$f" ]; then
			rm "$f"
		fi
	done
fi
