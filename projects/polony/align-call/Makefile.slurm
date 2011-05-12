all:
	@echo >&2 Please specify a target.
	false
align.reads.%:
	(cd /tmp && srun -s --ntasks 1 -c 1 sh -c 'cd $(jobdir) && oneframe.sh $*') >$@ 2>$@.stderr || rm -v $@
map-readcount.png: framestats.dat
	map1var.pl < $< > $@
framestats.dat: $(shell ls align.reads.* 2>/dev/null)
	framestats.pl $(POSITIONLIST) > $@

# arch-tag: Tom Clegg Thu Apr 12 19:40:45 PDT 2007 (align-call/Makefile.slurm)
