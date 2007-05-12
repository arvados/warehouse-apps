#!/bin/sh

# usage:
#
# NCORES=X [set-other-env-vars-for-align-call-pipeline] .../slurmit.sh
#
# X = number of concurrent jobs to run (max = n procs in slurm cluster)
#
# Make sure `pwd` and the taql distribution are reachable by the same path
# on all compute nodes as they are on this node!
#

export LC_ALL=POSIX

NCORES=${NCORES-32}

src=`dirname $0`
src=`dirname $src`
src=`cd $src && pwd`
srcbasename=`basename $src`

export jobdir=`pwd`
export installdir=`pwd`/install

if mkdir -p "$installdir"
then
  export CXXFLAGS="-O3"
  export CFLAGS="-O3"
  mkdir -p build
  (
    cd build
    ln -sfn "$installdir" "./=install"
    "$src/configure"
    "$src/mkx"
    "$src/mkx" install
  )
fi

export IMAGEDIR="${IMAGEDIR-$DATASETDIR/IMAGES/RAW}"
export SEGMENT_PROGRAM="${SEGMENT_PROGRAM-cat}"
export DIRORDER=`echo "$BASEORDER" | tr "," " "`

ln -sf $src/align-call/Makefile.slurm Makefile

targets=`PATH="$src/align-call:$PATH"; framelist.pl $IMAGEDIR | perl -pe 's/^/align.reads./'`
make \
  -j $NCORES \
  PATH="$installdir/bin:$src/align-call:$PATH" \
  $targets

# arch-tag: Tom Clegg Thu Apr 12 11:54:11 PDT 2007 (align-call/slurmit.sh)
