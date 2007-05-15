#!/bin/sh

set -e
set -x

date
echo "Installing revision $1 from $2."

export dir=/usr/local/polony-tools/"$1"
export svnrepos="$2"

srun -N$SLURM_NNODES sh -c '
rm -rf "$dir" && \
mkdir "$dir" && \
cd "$dir" && \
ln -s . install && \
svn export "$svnrepos" src && \
touch .fetched && \
sh ./src/tests/autotests.sh && \
touch .installed && \
touch .tested'
