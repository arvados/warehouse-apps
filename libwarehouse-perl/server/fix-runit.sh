#!/bin/bash

# First see if we need to convert runit to run under upstart
DISTRO=`cat /etc/lsb-release  |grep CODENAME| cut -c 18-`

UPSTART=0

if [ "x$DISTRO" = "xgutsy" ]; then
	if [ ! -d /etc/event.d ]; then
		echo "Your copy of gutsy does not have upstart installed. Please fix that first and then re-run this script."
		exit;
	fi

	if [ ! -f "/etc/event.d/runit" ]; then
		echo "Converting runit to upstart"
		cat >/etc/event.d/runit <<EOF
# runit
#
# Keep runit running

start on runlevel 2
start on runlevel 3
start on runlevel 4
start on runlevel 5

stop on runlevel 0
stop on runlevel 1
stop on runlevel 6

respawn
exec /usr/sbin/runsvdir-start

EOF
		killall runsvdir
		killall runsv
		sleep 5
		initctl start runit
		rm -f /etc/inittab
		UPSTART=1
	else
		STATUS=`initctl status runit`
		#echo $STATUS
		UPSTART=1
	fi
fi

# Now make sure we only have symlinks under /var/service

declare -a tobemoved
for subject in `ls /var/service`; do 
	if [ ! -L /var/service/$subject ]; then
		tobemoved+=($subject)
	fi
done

if [ "${#tobemoved[@]}" != "0" ]; then
	# Some entries under /var/service are not symlinks
	echo Need to move directories #{tobemoved[@]} from /var/service to /etc/runit

	if [ "$UPSTART" = "1" ]; then
		initctl stop runit >> /dev/null
	else
		cat /etc/inittab |sed -e 's/^SV:123456:respawn:\/usr\/sbin\/runsvdir-start/#SV:123456:respawn:\/usr\/sbin\/runsvdir-start/' > /etc/inittab.norunit
		mv /etc/inittab /etc/inittab.orig
		mv /etc/inittab.norunit /etc/inittab
		init q
	fi
	killall runsv
	sleep 5

	if [ ! -d /etc/runit ]; then
		mkdir /etc/runit
	fi
	
	for s2 in ${tobemoved[@]}; do
		mv /var/service/$s2 /etc/runit/
		ln -s /etc/runit/$s2 /var/service
	done
	
	if [ "$UPSTART" = "1" ]; then
		initctl start runit >> /dev/null
	else
		if [ -f /etc/inittab.orig ]; then
			rm /etc/inittab
			mv /etc/inittab.orig /etc/inittab
			init q
		fi	
	fi
fi

# Make sure munged and slurmd are run from /var/service/
for subject in munged slurmd; do
	if [ ! -L /var/service/$subject ]; then
		echo "$HOSTNAME converting $subject to runit"
		mkdir -p /etc/runit/$subject/log/main
		if [ "x$subject" == "xslurmd" ]; then
			cat >/etc/runit/$subject/run <<EOF
#!/bin/sh
exec slurmd -D 2>&1
EOF
			/bin/sed -i 's_^slurmd__' /etc/rc.local
		else
			cat >/etc/runit/$subject/run <<EOF
#!/bin/sh
if [ ! -d /var/run/munge ]; then
	mkdir -p /var/run/munge
fi
chown daemon /var/run/munge
exec su daemon -c "munged -F" 2>&1
EOF
			/bin/sed -i 's_^mkdir -p /var/run/munge__' /etc/rc.local
			/bin/sed -i 's_^chown daemon /var/run/munge__' /etc/rc.local
			/bin/sed -i 's_^sudo -u daemon munged__' /etc/rc.local
		fi
		chmod +x /etc/runit/$subject/run
	  cat >/etc/runit/$subject/log/run <<EOF
#!/bin/sh
exec svlogd -tt main
EOF
	  chmod +x /etc/runit/$subject/log/run
		killall $subject
		sleep 3
	  ln -s /etc/runit/$subject /var/service
		if [ "$subject" == "munged" ]; then
			# give munged some time to wake up
			sleep 3 
		fi
	fi
done

# Now do the same for keepd/mogstored, but ONLY if this node is not diskless!

DISKLESS=`df|grep -q nfs;echo $?`
if [ "x$DISKLESS" != "x0" ]; then
	# We found local disk - this node is not diskless
	# Make sure mogstored and keepd are run from /var/service/
	for subject in mogstored keepd; do
		if [ ! -L /var/service/$subject ]; then
			echo "$HOSTNAME converting $subject to runit"
			mkdir -p /etc/runit/$subject/log/main
			if [ "x$subject" == "xkeepd" ]; then
				cat >/etc/runit/$subject/run <<EOF
#!/bin/sh
exec keepd 2>&1
EOF
				/bin/sed -i 's_^keepd__' /etc/rc.local
			else
				cat >/etc/runit/$subject/run <<EOF
#!/bin/sh
exec mogstored
EOF
				/bin/sed -i 's_^/usr/local/bin/mogstored &__' /etc/rc.local
				/bin/sed -i 's_^mogstored &__' /etc/rc.local
			fi
			chmod +x /etc/runit/$subject/run
		  cat >/etc/runit/$subject/log/run <<EOF
#!/bin/sh
exec svlogd -tt main
EOF
		  chmod +x /etc/runit/$subject/log/run
			killall $subject
			sleep 1
		  ln -s /etc/runit/$subject /var/service
		fi
	done
fi


