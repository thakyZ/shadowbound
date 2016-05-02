#!/bin/bash

configfile="$1"
newopts=( sbbackupdir sbautorestartfile install_bindir install_libexecdir install_datadir )
newopt_steamcmd_appinfocache="${PREFIX}/Steam/appcache/appinfo.vdf"
newopt_arkbackupdir="${PREFIX}/Starbound-Backups"
newopt_arkautorestartfile=".autorestart"
newopt_install_bindir="${BINDIR}"
newopt_install_libexecdir="${LIBEXECDIR}"
newopt_install_datadir="${DATADIR}"

if grep '^\(servermail\|sbstVersion\)=' "${configfile}" >/dev/null 2>&1; then
  sed -i '/^\(servermail\|sbstVersion\)=/d' "${configfile}"
fi

for optname in "${newopts[@]}"; do
  if ! grep "^${optname}=" "${configfile}" >/dev/null 2>&1; then
    noptname="newopt_${optname}"
    echo "${optname}='${!noptname}'" >>"${configfile}"
  fi
done

