#!/bin/sh

# Install remainder of core.
for path in /usr/ports/core/*; do
    port=`basename $path`
    if [ $port = "COPYING" -o $port = "COPYRIGHT" ]; then continue; fi
    # Skip ports whose upstream source has rotated and is not needed in a
    # build container (no networking daemons necessary inside docker).
    case $port in
        dhcpcd) continue ;;
    esac
    if prt-get isinst $port; then
        continue
    fi
    if ! prt-get -is --install-scripts depinst $port; then
        echo "WARN: pre-sysup: skipping $port (install/source fetch failed)" >&2
    fi
done

# Some programs used in the build system are linked against libreadline/libhistory,
# so there is a problem when some ports are updated. We'll symlink the old version
# to the new one, and just update everything that (currently) relies on readline.
prt-get update readline || echo "WARN: pre-sysup: readline update failed" >&2

ln -sf /lib/libreadline.so.8.0 /lib/libreadline.so.7
ln -sf /lib/libhistory.so.8.0 /lib/libhistory.so.7

# When we update openssl, wget will be in trouble, so grab sources beforehand.
# Other ports too, courtesy of SiFuh's suggestion in IRC.
ports="wget curl exim openssh bindutils"

for port in $ports; do
  cd /usr/ports/core/$port
  echo $port
  pkgmk -do || echo "WARN: pre-sysup: source fetch failed for $port" >&2
done

prt-get update openssl || echo "WARN: pre-sysup: openssl update failed" >&2

for port in $ports; do
  cd /usr/ports/core/$port
  pkgmk -is -if -u || echo "WARN: pre-sysup: update failed for $port" >&2
done

prt-get remove iputils || echo "WARN: pre-sysup: iputils removal failed" >&2
