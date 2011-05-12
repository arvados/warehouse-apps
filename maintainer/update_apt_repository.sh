#!/bin/sh

# This script assumes that:
# * `pwd` is *outside* the source tree
# * /var/www/apt/ is the apt repository to update
#
# To bootstrap:
# * git clone git://git/warehouse-apps.git
# * cp -p warehouse-apps/maintainer/update_apt_repository.sh .
# * ln -s 81cabd85a7756ed776eef882ef83ee847e4cbc97 current-commit
# * ln -s 1305237951 current-version
# * ./update_apt_repository.sh
#
# To auto-build, wrap this script using flock(1) and run it in a cron
# job or a git post-receive hook.

# ----------------------------------------------------------------------

# First clean up the message queues and semaphores that got stuck after
# the previous build (if only we could figure out what's causing this!)
#
# Note: this is dangerous, we should probably make a list of the existing
# semaphores and message queues before the run and exclude them from the xargs
# command. That would be pretty messy in bash though...
#
# ward, 2009-01-25

user=`whoami`
if [ "`/usr/bin/ipcs -s |grep 0x |grep -w $user |/usr/bin/cut -d' ' -f2`" != "" ]; then
        /usr/bin/ipcs -s |grep 0x |grep -w $user |/usr/bin/cut -d' ' -f2 |/usr/bin/xargs -n 1 /usr/bin/ipcrm -s
fi
if [ "`/usr/bin/ipcs -q |grep 0x |grep -w $user |/usr/bin/cut -d' ' -f2`" != "" ]; then
        /usr/bin/ipcs -q |grep 0x |grep -w $user |/usr/bin/cut -d' ' -f2 |/usr/bin/xargs -n 1 /usr/bin/ipcrm -q
fi

set -e
set -x

currentversion=`readlink current-version`
currentcommit=`readlink current-commit`

if ! [ -d warehouse-apps ]
then
  git clone git://git/warehouse-apps.git
fi

basedir=`pwd`

cd warehouse-apps
git config user.email "git@`hostname`"
git config user.name 'Builder'
git reset --hard
git clean -d -f -x
git fetch origin
git checkout origin/master
git reset --hard

newcommit=$(git log -1 --format=%H --diff-filter='[A|C|D|M|R|T]' warehouse)
newversion=$(git log -1 --format=%ct.%h --diff-filter='[A|C|D|M|R|T]' warehouse)

# First see if this commit updated ./warehouse/. If not, this script is a NOP.
if ! git log -1 --format=%H --diff-filter='[A|C|D|M|R|T]' $currentcommit..$newcommit warehouse | egrep -q .
then
    if [ "$1" != "-f" ]
    then
        echo Not building a new libwarehouse-perl package because no changes were made to warehouse code since commit $currentcommit.
        exit
    fi
fi

ln -sfn $newcommit $basedir/current-commit
ln -sfn $newversion $basedir/current-version

cd warehouse
./build_deb.sh

# Now install the new versions of the packages
cd ..
set +e
for dist in hardy lucid maverick natty lenny squeeze
do
    reprepro -Vb /var/www/apt remove $dist libwarehouse-perl
done
for dist in hardy lucid maverick natty lenny squeeze
do
    reprepro -Vb /var/www/apt include $dist libwarehouse-perl_$newversion*.changes
done
