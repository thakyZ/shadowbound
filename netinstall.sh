#!/bin/bash

#
# Net Installer, used with curl
#

steamcmd_user="$1"
channel=${2:-master} # if defined by 2nd argument install the defined version, otherwise install master
shift
shift

output=/dev/null

if [ "$1" = "--verbose" ]; then
	output=/dev/fd/1
	shift
elif [[ "$1" =~ ^--output= ]]; then
	output="${1#--output=}"
	shift
fi

# Download and untar installation files
cd /tmp
COMMIT="`curl -L -k -s https://api.github.com/repos/thakyZ/shadowbound/git/refs/heads/${channel} | sed -n 's/^ *"sha": "\(.*\)",.*/\1/p'`"

if [ -z "$COMMIT" ]; then
	if [ "$channel" != "master" ]; then
		echo "Channel ${channel} not found - trying master"
		channel=master
		COMMIT="`curl -L -k -s https://api.github.com/repos/thakyZ/shadowbound/git/refs/heads/${channel} | sed -n 's/^ *"sha": "\(.*\)",.*/\1/p'`"
	fi
fi

if [ -z "$COMMIT" ]; then
	echo "Unable to retrieve latest commit"
	exit 1
fi

mkdir shadowbound-${channel}
cd shadowbound-${channel}
curl -L -k -s https://github.com/thakyZ/shadowbound/archive/${COMMIT}.tar.gz | tar xz

# Install Shadowbound
cd shadowbound-${COMMIT}/tools
sed -i "s|^shaboundCommit='.*'$|shaboundCommit='${COMMIT}'|" shadowbound
version=`<../.version`
sed -i "s|^shaboundVersion=\".*\"|shaboundVersion='${version}'|" shadowbound
chmod +x install.sh
bash install.sh "$steamcmd_user" "$@" >"$output" 2>&1

status=$?

rm -rf /tmp/shadowbound-${channel}

# Print messages
case "$status" in
  "0")
    echo "Shadowbound was correctly installed in your system inside the home directory of $steamcmd_user!"
    ;;
  "1")
    echo "Something where wrong :("
    ;;
  "2")
    echo "WARNING: A previous version of Shadowbound was detected in your system, your old configuration was not overwritten. You may need to manually update it."
    echo "Shadowbound was correctly installed in your system inside the home directory of $steamcmd_user!"
    ;;
esac
