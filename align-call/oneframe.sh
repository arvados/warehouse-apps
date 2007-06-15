#!/bin/sh

frame="$1"
if [ -z "$frame" ]
then
 frame="$FRAMENUMBER"
fi


export REVISIONDIR="/usr/local/polony-tools/$REVISION"
export PATH="$REVISIONDIR/install/bin:$REVISIONDIR/src/align-call:$PATH"

export FOCUSPIXELS="${USER_FOCUSPIXELS-$FOCUSPIXELS}"
export ALIGNWINDOW="${USER_ALIGNWINDOW-$ALIGNWINDOW}"
export OBJECTTHRESHOLD="${USER_OBJECTTHRESHOLD-$OBJECTTHRESHOLD}"
export IMAGEFILTER="${USER_IMAGEFILTER-none}"

export IMAGEDIR="${IMAGEDIR-$DATASETDIR/IMAGES/RAW}"
export DIRORDER=`echo "$BASEORDER" | tr "," " "`

(
set -e
env >&2
echo >&2
fn=$((1$frame-10000))
echo >&2 "# frame $frame hostname `hostname`"
imagenos=`printf "%04d %04d %04d %04d" $((($fn-1)*4+1)) $((($fn-1)*4+2)) $((($fn-1)*4+3)) $((($fn-1)*4+4))`
(
	set -e
	perl -S rawify.pl $IMAGEDIR/999/WL_$frame
	for dir in $DIRORDER
	do
		for imageno in $imagenos
		do
			perl -S rawify.pl $IMAGEDIR/$dir/SC_$imageno
		done
	done
) \
| perl -S filter-$IMAGEFILTER.pl \
| perl -S find_objects-register_raw_pipe.pl \
| perl -S raw_to_reads.pl \
| sort \
| (if [ -z "$SORTEDTAGS" ]; then cat; else join - $SORTEDTAGS; fi)
) 2>/tmp/stderr.$$ >/tmp/stdout.$$ || ( rm -f /tmp/stderr.$$ /tmp/stdout.$$; exit 1 )

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
