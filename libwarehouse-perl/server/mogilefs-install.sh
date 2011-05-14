#!/bin/sh

set -ex
cd /tmp

if ! which mogilefsd
then

    apt-get install -y \
	liblinux-aio-perl \
	libbsd-resource-perl \
	libcompress-zlib-perl \
	libnet-netmask-perl \
	libio-stringy-perl \
	libwww-perl

    echo no | perl -MCPAN -e shell
    perl -MCPAN -e 'install Sys::Syscall, Danga::Socket, DBI, IO::AIO, Perlbal, String::CRC32, Gearman::Server, Gearman::Client::Async'

    mkdir -p /tmp/mogilefs
    cd /tmp/mogilefs
    (
	package=MogileFS-Client-1.08
	wget -c http://danga.com/dist/MogileFS/client-perl/$package.tar.gz
	md5sum $package.tar.gz | grep 2d7a6853100566496c408c752408442d
	tar xzf $package.tar.gz
	cd $package
	perl Makefile.PL
	make
	make test
	sudo make install
    )
    (
	package=MogileFS-Utils-2.12
	wget -c http://danga.com/dist/MogileFS/$package.tar.gz
	md5sum $package.tar.gz | grep 69d2160ee6394efa63542eb4b5bb8c32
	tar xzf $package.tar.gz
	cd $package
	perl Makefile.PL
	make
	make test
	sudo make install
    )
    (
	package=mogilefs-server-2.17
	wget -c http://danga.com/dist/MogileFS/server/$package.tar.gz
	md5sum $package.tar.gz | grep 96814eb32b258557a1beea73d2ff4647
	tar xzf $package.tar.gz
	cd $package
	perl Makefile.PL
	make
	make test || echo >&2 '*** "make test" failed, continuing anyway ***'
	sudo make install
    )
fi

if ! dpkg --list runit >/dev/null
    then
    touch /etc/inittab
    apt-get install -y runit
fi

if grep -q runsvdir /etc/inittab
    then
    perl -pi~ -e 's/^[^\#]/\#$&/ if /runsvdir/' /etc/inittab
fi

cat >/etc/init.d/runit <<'EOF'
#!/bin/sh
case "$1" in
    start)
    start-stop-daemon --start --background --exec /usr/sbin/runsvdir-start
    ;;
    stop)
    sv exit /var/service/*
    start-stop-daemon --stop --exec /usr/bin/runsvdir
    ;;
esac
EOF
chmod +x /etc/init.d/runit
update-rc.d runit defaults 20 80

if ! ps -C runsvdir
    then
    if [ -x /etc/init.d/runit ]
	then
	/etc/init.d/runit start
    fi
fi

sv="/var/service/mogstored"
mkdir -p $sv/log/main

if ! [ -e $sv/run ]
then
    cat >"$sv/run" <<EOF
#!/bin/sh
exec mogstored 2>&1
EOF
    chmod 755 "$sv/run"
fi

if ! [ -e $sv/log/run ]
then
    cat >"$sv/log/run" <<EOF
#!/bin/sh
exec svlogd -tt main
EOF
    chmod 755 "$sv/log/run"
fi

if ! [ -e "/etc/mogilefs/mogstored.conf" ]
then
    mkdir -p /etc/mogilefs
    mkdir -p /mogdata
    cat >"/etc/mogilefs/mogstored.conf" <<EOF
httplisten=0.0.0.0:7500
mgmtlisten=0.0.0.0:7501
docroot=/mogdata
EOF
fi

