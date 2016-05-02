#!/bin/bash

userinstall=no
steamcmd_user=
showusage=no

while [ -n "$1" ]; do
  case "$1" in
    --me)
      userinstall=yes
      steamcmd_user="--me"
    ;;
    -h|--help)
      showusage=yes
      break
    ;;
    --prefix=*)
      PREFIX="${1#--prefix=}"
    ;;
    --prefix)
      PREFIX="$2"
      shift
    ;;
    --exec-prefix=*)
      EXECPREFIX="${1#--exec-prefix=}"
    ;;
    --exec-prefix)
      EXECPREFIX="$2"
      shift
    ;;
    --data-prefix=*)
      DATAPREFIX="${1#--data-prefix=}"
    ;;
    --data-prefix)
      DATAPREFIX="$2"
      shift
    ;;
    --install-root=*)
      INSTALL_ROOT="${1#--install-root=}"
    ;;
    --install-root)
      INSTALL_ROOT="$2"
      shift
    ;;
    --bindir=*)
      BINDIR="${1#--bindir=}"
    ;;
    --bindir)
      BINDIR="$2"
    shift
    ;;
    --libexecdir=*)
      LIBEXECDIR="${1#--libexecdir=}"
    ;;
    --libexecdir)
      LIBEXECDIR="$2"
      shift
    ;;
    --datadir=*)
      DATADIR="${1#--datadir=}"
    ;;
    --datadir)
      DATADIR="$2"
      shift
    ;;
    -*)
      echo "Invalid option '$1'"
      showusage=yes
      break;
    ;;
    *)
      if [ -n "$steamcmd_user" ]; then
        echo "Multiple users specified"
        showusage=yes
        break;
      elif getent passwd "$1" >/dev/null 2>&1; then
        steamcmd_user="$1"
      else
        echo "Invalid user '$1'"
        showusage=yes
        break;
      fi
    ;;
  esac
  shift
done

if [ "$userinstall" == "yes" -a "$UID" -eq 0 ]; then
  echo "Refusing to perform user-install as root"
  showusage=yes
fi

if [ "$showusage" == "no" -a -z "$steamcmd_user" ]; then
  echo "No user specified"
  showusage=yes
fi

if [ "$userinstall" == "yes" ]; then
  PREFIX="${PREFIX:-${HOME}}"
  EXECPREFIX="${EXECPREFIX:-${PREFIX}}"
  DATAPREFIX="${DATAPREFIX:-${PREFIX}/.local/share}"
  CONFIGFILE="${PREFIX}/.shadowbound.cfg"
else
  PREFIX="${PREFIX:-/usr/local}"
  EXECPREFIX="${EXECPREFIX:-${PREFIX}}"
  DATAPREFIX="${DATAPREFIX:-${PREFIX}/share}"
  CONFIGFILE="/etc/shadowbound/shadowbound.cfg"
fi

BINDIR="${BINDIR:-${EXECPREFIX}/bin}"
LIBEXECDIR="${LIBEXECDIR:-${EXECPREFIX}/libexec/shadowbound}"
DATADIR="${DATADIR:-${DATAPREFIX}/shadowbound}"

if [ "$showusage" == "yes" ]; then
    echo "Usage: ./install.sh {<user>|--me} [OPTIONS]"
    echo "You must specify your system steam user who own steamcmd directory to install Shadowbound."
    echo "Specify the special used '--me' to perform a user-install."
    echo
    echo "<user>          The user shadowbound should be run as"
    echo
    echo "Option          Description"
    echo "--help, -h      Show this help text"
    echo "--me            Perform a user-install"
    echo "--prefix        Specify the prefix under which to install shadowbound"
    echo "                [PREFIX=${PREFIX}]"
    echo "--exec-prefix   Specify the prefix under which to install executables"
    echo "                [EXECPREFIX=${EXECPREFIX}]"
    echo "--data-prefix   Specify the prefix under which to install suppor files"
    echo "                [DATAPREFIX=${DATAPREFIX}]"
    echo "--install-root  Specify the staging directory in which to perform the install"
    echo "                [INSTALL_ROOT=${INSTALL_ROOT}]"
    echo "--bindir        Specify the directory under which to install executables"
    echo "                [BINDIR=${BINDIR}]"
    echo "--libexecdir    Specify the directory under which to install executable support files"
    echo "                [LIBEXECDIR=${LIBEXECDIR}]"
    echo "--datadir       Specify the directory under which to install support files"
    echo "                [DATADIR=${DATADIR}]"
    exit 1
fi

if [ "$userinstall" == "yes" ]; then
    # Copy shadowbound to ~/bin
    mkdir -p "${INSTALL_ROOT}${BINDIR}"
    cp shadowbound "${INSTALL_ROOT}${BINDIR}/shadowbound"
    chmod +x "${INSTALL_ROOT}${BINDIR}/shadowbound"

    # Create a folder in ~/.local/share to store shadowbound support files
    mkdir -p "${INSTALL_ROOT}${DATADIR}"
  
    # Copy the rcon client script to ~/.local/share/shadowbound
    cp sbrconclient.py "${INSTALL_ROOT}${DATADIR}/sbrconclient.py"
    chmod +x "${INSTALL_ROOT}${DATADIR}/sbrconclient.py"

    # Copy the uninstall script to ~/.local/share/shadowbound
    cp uninstall-user.sh "${INSTALL_ROOT}${DATADIR}/shadowbound-uninstall.sh"
    chmod +x "${INSTALL_ROOT}${DATADIR}/shadowbound-uninstall.sh"
    sed -i -e "s|^BINDIR=.*|BINDIR=\"${BINDIR}\"|" \
           -e "s|^DATADIR=.*|DATADIR=\"${DATADIR}\"|" \
           "${INSTALL_ROOT}${DATADIR}/shadowbound-uninstall.sh"

    # Create a folder in ~/logs to let Shadowbound write its own log files
    mkdir -p "${INSTALL_ROOT}${PREFIX}/logs/shadowbound"

    # Copy shadowbound.cfg to ~/.shadowbound.cfg.NEW
    cp shadowbound.cfg "${INSTALL_ROOT}${PREFIX}/.shadowbound.cfg.NEW"
    # Change the defaults in the new config file
    sed -i -e "s|^steamcmd_user=\"steam\"|steamcmd_user=\"--me\"|" \
           -e "s|\"/home/steam|\"${PREFIX}|" \
           -e "s|/var/log/shadowbound|${PREFIX}/logs/shadowbound|" \
           -e "s|^install_bindir=.*|install_bindir=\"${BINDIR}\"|" \
           -e "s|^install_libexecdir=.*|install_libexecdir=\"${LIBEXECDIR}\"|" \
           -e "s|^install_datadir=.*|install_datadir=\"${DATADIR}\"|" \
           "${INSTALL_ROOT}${PREFIX}/.shadowbound.cfg.NEW"

    # Copy shadowbound.cfg to ~/.shadowbound.cfg if it doesn't already exist
    if [ -f "${INSTALL_ROOT}${CONFIGFILE}" ]; then
      bash ./migrate-config.sh "${INSTALL_ROOT}${CONFIGFILE}"

      echo "A previous version of Shadowbound was detected in your system, your old configuration was not overwritten. You may need to manually update it."
    echo "A copy of the new configuration file was included in '${CONFIGFILE}.NEW'. Make sure to review any changes and update your config accordingly!"
    exit 2
  else
    mv -n "${INSTALL_ROOT}${CONFIGFILE}.NEW" "${INSTALL_ROOT}${CONFIGFILE}"
    cp -n "${INSTALL_ROOT}/${INSTANCEDIR}/instance.cfg.example" "${INSTALL_ROOT}/${INSTANCEDIR}/main.cfg"
  fi
else
    # Copy shadowbound to /usr/bin and set permissions
    cp shadowbound "${INSTALL_ROOT}${BINDIR}/shadowbound"
    chmod +x "${INSTALL_ROOT}${BINDIR}/shadowbound"

    mkdir -p "${INSTALL_ROOT}${LIBEXECDIR}"
  
    # Copy the rcon client script to ~/.local/share/shadowbound
    cp sbrconclient.py "${INSTALL_ROOT}${LIBEXECDIR}/sbrconclient.py"
    chmod +x "${INSTALL_ROOT}${LIBEXECDIR}/sbrconclient.py"
  
    # Copy the uninstall script to ~/.local/share/shadowbound
    cp uninstall.sh "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound-uninstall.sh"
    chmod +x "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound-uninstall.sh"
    sed -i -e "s|^BINDIR=.*|BINDIR=\"${BINDIR}\"|" \
           -e "s|^LIBEXECDIR=.*|LIBEXECDIR=\"${LIBEXECDIR}\"|" \
           -e "s|^DATADIR=.*|DATADIR=\"${DATADIR}\"|" \
           "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound-uninstall.sh"

    # Copy sbdaemon to /etc/init.d ,set permissions and add it to boot
    if [ -f /lib/lsb/init-functions ]; then
      # on debian 8, sysvinit and systemd are present. If systemd is available we use it instead of sysvinit
      if [ -f /etc/systemd/system.conf ]; then   # used by systemd
        mkdir -p "${INSTALL_ROOT}${LIBEXECDIR}"
        cp systemd/shadowbound.init "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound.init"
        chmod +x "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound.init"
        cp systemd/shadowbound.service "${INSTALL_ROOT}/etc/systemd/system/shadowbound.service"
        sed -i "s|=/usr/libexec/shadowbound/|=${LIBEXECDIR}/|" "${INSTALL_ROOT}/etc/systemd/system/shadowbound.service"
        cp systemd/shadowbound@.service "${INSTALL_ROOT}/etc/systemd/system/shadowbound@.service"
        sed -i "s|=/usr/bin/|=${BINDIR}/|" "${INSTALL_ROOT}/etc/systemd/system/shadowbound@.service"
        if [ -z "${INSTALL_ROOT}" ]; then
          systemctl daemon-reload
          systemctl enable shadowbound.service
          echo "Starbound server will now start on boot, if you want to remove this feature run the following line"
          echo "systemctl disable shadowbound.service"
    fi
      else  # systemd not present, so use sysvinit
        cp lsb/sbdaemon "${INSTALL_ROOT}/etc/init.d/shadowbound"
        chmod +x "${INSTALL_ROOT}/etc/init.d/shadowbound"
        sed -i "s|^DAEMON=\"/usr/bin/|DAEMON=\"${BINDIR}/|" "${INSTALL_ROOT}/etc/init.d/shadowbound"
        # add to startup if the system use sysinit
        if [ -x /usr/sbin/update-rc.d -a -z "${INSTALL_ROOT}" ]; then
          update-rc.d shadowbound defaults
          echo "Starbound server will now start on boot, if you want to remove this feature run the following line"
          echo "update-rc.d -f shadowbound remove"
       fi
    fi
  elif [ -f /etc/rc.d/init.d/functions ]; then
    # on RHEL 7, sysvinit and systemd are present. If systemd is available we use it instead of sysvinit
    if [ -f /etc/systemd/system.conf ]; then   # used by systemd
      mkdir -p "${INSTALL_ROOT}${LIBEXECDIR}"
      cp systemd/shadowbound.init "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound.init"
      chmod +x "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound.init"
      cp systemd/shadowbound.service "${INSTALL_ROOT}/etc/systemd/system/shadowbound.service"
      sed -i "s|=/usr/libexec/shadowbound/|=${LIBEXECDIR}/|" "${INSTALL_ROOT}/etc/systemd/system/shadowbound.service"
      cp systemd/shadowbound@.service "${INSTALL_ROOT}/etc/systemd/system/shadowbound@.service"
      sed -i "s|=/usr/bin/|=${BINDIR}/|" "${INSTALL_ROOT}/etc/systemd/system/shadowbound@.service"
      if [ -z "${INSTALL_ROOT}" ]; then
        systemctl daemon-reload
        systemctl enable shadowbound.service
        echo "Starbound server will now start on boot, if you want to remove this feature run the following line"
        echo "systemctl disable shadowbound.service"
      fi
    else # systemd not preset, so use sysvinit
      cp redhat/sbdaemon "${INSTALL_ROOT}/etc/rc.d/init.d/shadowbound"
      chmod +x "${INSTALL_ROOT}/etc/rc.d/init.d/shadowbound"
      sed -i "s@^DAEMON=\"/usr/bin/@DAEMON=\"${BINDIR}/@" "${INSTALL_ROOT}/etc/rc.d/init.d/shadowbound"
      if [ -x /sbin/chkconfig -a -z "${INSTALL_ROOT}" ]; then
        chkconfig --add shadowbound
        echo "Starbound server will now start on boot, if you want to remove this feature run the following line"
        echo "chkconfig shadowbound off"
      fi
    fi
  elif [ -f /sbin/runscript ]; then
    cp openrc/sbdaemon "${INSTALL_ROOT}/etc/init.d/shadowbound"
    chmod +x "${INSTALL_ROOT}/etc/init.d/shadowbound"
    sed -i "s@^DAEMON=\"/usr/bin/@DAEMON=\"${BINDIR}/@" "${INSTALL_ROOT}/etc/init.d/shadowbound"
    if [ -x /sbin/rc-update -a -z "${INSTALL_ROOT}" ]; then
      rc-update add shadowbound default
      echo "Starbound server will now start on boot, if you want to remove this feature run the following line"
      echo "rc-update del shadowbound default"
    fi
  elif [ -f /etc/systemd/system.conf ]; then   # used by systemd
    mkdir -p "${INSTALL_ROOT}${LIBEXECDIR}"
    cp systemd/shadowbound.init "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound.init"
    chmod +x "${INSTALL_ROOT}${LIBEXECDIR}/shadowbound.init"
    cp systemd/shadowbound.service "${INSTALL_ROOT}/etc/systemd/system/shadowbound.service"
    sed -i "s|=/usr/libexec/shadowbound/|=${LIBEXECDIR}/|" "${INSTALL_ROOT}/etc/systemd/system/shadowbound.service"
    cp systemd/shadowbound@.service "${INSTALL_ROOT}/etc/systemd/system/shadowbound@.service"
    sed -i "s|=/usr/bin/|=${BINDIR}/|" "${INSTALL_ROOT}/etc/systemd/system/shadowbound@.service"
    if [ -z "${INSTALL_ROOT}" ]; then
      systemctl daemon-reload
      systemctl enable shadowbound.service
      echo "Starbound server will now start on boot, if you want to remove this feature run the following line"
      echo "systemctl disable shadowbound.service"
    fi
  fi

  # Create a folder in /var/log to let Shadowbound tools write its own log files
  mkdir -p "${INSTALL_ROOT}/var/log/shadowbound"
  chown "$steamcmd_user" "${INSTALL_ROOT}/var/log/shadowbound"

  # Copy shadowbound.cfg inside linux configuation folder if it doesn't already exists
  mkdir -p "${INSTALL_ROOT}/etc/shadowbound"
  cp shadowbound.cfg "${INSTALL_ROOT}/etc/shadowbound/shadowbound.cfg.NEW"
  chown "$steamcmd_user" "${INSTALL_ROOT}/etc/shadowbound/shadowbound.cfg.NEW"
  sed -i -e "s|^steamcmd_user=\"steam\"|steamcmd_user=\"$steamcmd_user\"|" \
       -e "s|\"/home/steam|\"/home/$steamcmd_user|" \
       -e "s|^install_bindir=.*|install_bindir=\"${BINDIR}\"|" \
       -e "s|^install_libexecdir=.*|install_libexecdir=\"${LIBEXECDIR}\"|" \
       -e "s|^install_datadir=.*|install_datadir=\"${DATADIR}\"|" \
       "${INSTALL_ROOT}/etc/shadowbound/shadowbound.cfg.NEW"

  if [ -f "${INSTALL_ROOT}${CONFIGFILE}" ]; then
    bash ./migrate-config.sh "${INSTALL_ROOT}${CONFIGFILE}"

    echo "A previous version of Shadowbound was detected in your system, your old configuration was not overwritten. You may need to manually update it."
    echo "A copy of the new configuration file was included in /etc/shadowbound. Make sure to review any changes and update your config accordingly!"
    exit 2
  else
    mv -n "${INSTALL_ROOT}${CONFIGFILE}.NEW" "${INSTALL_ROOT}${CONFIGFILE}"
    cp -n "${INSTALL_ROOT}/${INSTANCEDIR}/instance.cfg.example" "${INSTALL_ROOT}/${INSTANCEDIR}/main.cfg"
  fi
fi

exit 0
