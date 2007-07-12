#!/bin/sh

export REVISIONDIR="/usr/local/polony-tools/$REVISION"
export PATH="$REVISIONDIR/install/bin:$PATH"

export FOCUSPIXELS="${USER_FOCUSPIXELS-$FOCUSPIXELS}"
export ALIGNWINDOW="${USER_ALIGNWINDOW-$ALIGNWINDOW}"
export OBJECTTHRESHOLD="${USER_OBJECTTHRESHOLD-$OBJECTTHRESHOLD}"
export IMAGEFILTER="${USER_IMAGEFILTER-none}"

export IMAGEDIR="${IMAGEDIR-$DATASETDIR/IMAGES/RAW}"
export DIRORDER=`echo "$BASEORDER" | tr "," " "`

if [ -z "$MAPFUNCTION" ]
then
  MAPFUNCTION=callreads
fi
export MAPFUNCTION

$REVISIONDIR/src/mapreduce/$MAPFUNCTION-map \
 2>/tmp/stderr.$$ >/tmp/stdout.$$ \
 || ( rm -f /tmp/stderr.$$ /tmp/stdout.$$; exit 1 )

# this is a really silly workaround; mogilefs can't store empty files
if [ -z /tmp/stdout.$$ ]
then
  echo -n X >>/tmp/stdout.$$
fi

if cat /tmp/stderr.$$ | perl -e '
 use MogileFS::Client;
 undef $/;
 $mogc = MogileFS::Client->new(domain => $ENV{OUTPUT_DOMAIN},
                               hosts => [split(",", $ENV{OUTPUT_TRACKERS})]);
 for(1..5)
 {
   exit(0)
   if $mogc->store_content($ENV{OUTPUT_KEY}.".stderr", $ENV{OUTPUT_CLASS}, <STDIN>);
 }
 exit(1);
 '
then
  cat /tmp/stdout.$$ | perl -e '
 use MogileFS::Client;
 undef $/;
 $mogc = MogileFS::Client->new(domain => $ENV{OUTPUT_DOMAIN},
                               hosts => [split(",", $ENV{OUTPUT_TRACKERS})]);
 for(1..5)
 {
   exit(0)
   if $mogc->store_content($ENV{OUTPUT_KEY}, $ENV{OUTPUT_CLASS}, <STDIN>);
 }
 exit(1);
 '
fi
rm -f /tmp/stderr.$$ /tmp/stdout.$$

# arch-tag: Tom Clegg Thu Apr 12 19:41:24 PDT 2007 (align-call/oneframe.sh)
