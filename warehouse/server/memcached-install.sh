#!/bin/sh

cd /tmp

# Get total free memory in kilobytes
size="`grep MemTotal /proc/meminfo | tr -dc 0-9`"
# Convert to megabytes
size="$(($size/1024))"
# If we have 4GB, we don't want memcached.
# If we have 6GB, we want 1 instance of memcached, with 2GB of cache.
# If we have 8GB, we want 2 instances of memcached, with 2GB of cache each.
# If we have 12GB, we want 3 instances of memcached, with 2600MB of cache each.
if [ "$size" -gt 11000 ]; then
	INSTANCES=3
	ISIZE=2600
	echo `hostname` '12GB of ram detected; want to instal 3 instances of memcached (2600MB each).'
#FIXME: how much ram do we *really* see on 8GB boxes?
elif [ "$size" -gt 7000 ]; then
	INSTANCES=2
	ISIZE=2000
	echo `hostname` '8GB of ram detected; want to instal 2 instances of memcached (2000MB each).'
elif [ "$size" -gt 5000 ]; then
	INSTANCES=1
	ISIZE=2000
	echo `hostname` '6GB of ram detected; want to instal 1 instance of memcached (2000MB).'
else
	echo `hostname` "4GB of ram detected; memcached should not be running"
	if [ -L /var/service/memcached ]; then
		rm -f /var/service/memcached
		rm -rf /etc/runit/memcached
		apt-get remove memcached --purge
	fi
	exit
fi

# If we're still here, we need to configure at least one memcached instance

# Make sure memcached is installed
if ! which memcached >/dev/null
then
    apt-get install -y memcached
fi
# But we're going to run it under 'runit'
chmod 0 /etc/init.d/memcached

# We have some runit setups that are not ideal
if [ ! -d /etc/runit ]; then
	mkdir /etc/runit
fi

# Make sure we don't have old memcached instances set up
if [ -d /var/service/memcached ]; then
	# Bring the service down. We assume that fix-runit.sh has already been run, 
	# which means that all files in /var/service/ are symlinks.
	if [ -L /var/service/memcached ]; then
		rm -f /var/service/memcached
	else
		# this is bad; the user needs to run fix-runit.sh first
		echo "/var/service/memcached is not a symlink. Run fix-runit.sh first, and then rerun this script"
		exit
	fi
	if [ -d /etc/runit/memcached ]; then
		# wait 5 seconds to make sure runit shuts down the service after we removed the symlink
		sleep 5
		rm -rf /etc/runit/memcached
	fi
fi

# See if we have *new* memcached instances defined; if we do, exit
if [ -d /var/service/memcached1 ]; then
	echo "Memcached is already configured on this machine"
	exit
fi

# Let's configure our memcached runit directories
PORT=11211
for ((i=1;i<=$INSTANCES;i+=1)); do
	mkdir -p /etc/runit/memcached$i/log/main
	cat >/etc/runit/memcached$i/run <<EOF
#!/bin/sh
exec /usr/bin/memcached -v -u nobody -m "$ISIZE" -p "$PORT"
EOF
	chmod +x /etc/runit/memcached$i/run

	cat >/etc/runit/memcached$i/log/run <<EOF
#!/bin/sh
exec svlogd -tt main
EOF
	chmod +x /etc/runit/memcached$i/log/run
	ln -s /etc/runit/memcached$i /var/service
	PORT=$(($PORT + 1))
done


