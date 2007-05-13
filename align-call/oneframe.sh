#!/bin/sh

frame=${1-$FRAMENUMBER}; shift

export FOCUSPIXELS="${USER_FOCUSPIXELS-$FOCUSPIXELS}"
export ALIGNWINDOW="${USER_ALIGNWINDOW-$ALIGNWINDOW}"
export OBJECTTHRESHOLD="${USER_OBJECTTHRESHOLD-$OBJECTTHRESHOLD}"

export FOCUSPIXELS="${USER_FOCUSPIXELS-$FOCUSPIXELS}"
export IMAGEDIR="${IMAGEDIR-$DATASETDIR/IMAGES/RAW}"
export SEGMENT_PROGRAM="${SEGMENT_PROGRAM-cat}"
export DIRORDER=`echo "$BASEORDER" | tr "," " "`

(
fn=$((1$frame-10000))
echo >&2 "# frame $frame hostname `hostname`"
imagenos=`printf "%04d %04d %04d %04d" $((($fn-1)*4+1)) $((($fn-1)*4+2)) $((($fn-1)*4+3)) $((($fn-1)*4+4))`
(
	rawify.pl $IMAGEDIR/999/WL_$frame
	for dir in $DIRORDER
	do
		for imageno in $imagenos
		do
			rawify.pl $IMAGEDIR/$dir/SC_$imageno
		done
	done
) \
| $SEGMENT_PROGRAM \
| find_objects-register_raw_pipe.pl \
| raw_to_reads.pl \
| sort \
| (if [ -z "$SORTEDTAGS" ]; then cat; else join - $SORTEDTAGS; fi) \
| perl -e '
 use MogileFS::Client;
 undef $/;
 $mogc = MogileFS::Client->new(domain => $ENV{OUTPUT_DOMAIN},
                               hosts => [split(",", $ENV{OUTPUT_TRACKERS})]);
 $mogc->store_content($ENV{OUTPUT_KEY}, $ENV{OUTPUT_CLASS}, <STDIN>);
 '
) 2>/tmp/stderr.$$

cat /tmp/stderr.$$ | perl -e '
 use MogileFS::Client;
 undef $/;
 $mogc = MogileFS::Client->new(domain => $ENV{OUTPUT_DOMAIN},
                               hosts => [split(",", $ENV{OUTPUT_TRACKERS})]);
 $mogc->store_content($ENV{OUTPUT_KEY}.".stderr", $ENV{OUTPUT_CLASS}, <STDIN>);
 '
rm /tmp/stderr.$$

# arch-tag: Tom Clegg Thu Apr 12 19:41:24 PDT 2007 (align-call/oneframe.sh)
