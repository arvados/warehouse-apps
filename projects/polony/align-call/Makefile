DATASETDIR?=/images/uncle12d/jc_01
IMAGEDIR?=$(DATASETDIR)/IMAGES/RAW
POSITIONLIST?=$(DATASETDIR)/LOGS_ACQ/position_list.dat
BASEORDER?="PP2b,PP1,PM1,PM2,pm3d,PM4,PM5,DP5,DP4,DP3,DP2b,DP1b,DM1,DM2,DM3,DM4b,DM5,PR1RP3,DDP1,PR1RP1"
DIRORDER:=$(shell echo $(BASEORDER) | tr "," " ")
FOCUSPIXELS?=20000
OBJECTTHRESHOLD?=8200
ALIGNWINDOW?=20
NCORES?=1
SORTEDTAGS?=jc_01.tags.sort
SEGMENT_PROGRAM?=cat

nodelist:=$(shell cluster)
nodecount:=$(shell echo $(nodelist) | wc -w)

.SECONDARY:

oncluster:
	i=0; \
	for node in $(nodelist); \
	do \
		echo ">>> starting node: $$node <<<"; \
		onnode $$node make oneslice SLICES=$(nodecount) MYSLICE=$$i 2>&1 | tee -a make-output.node.$$node & \
		i=$$(($$i+1)); \
	done; \
	wait
	zcat align.reads.*.gz | time gzip -v > align.reads.gz
	make map-readcount.png

onnode:
	make oneslice SLICES=1 MYSLICE=0
	zcat align.reads.*.gz | time gzip -v > align.reads.gz
	make map-readcount.png

whatsmissing:
	for n in $(shell ls $(IMAGEDIR)/999 | tr -dc '0-9\n' | uniq); do if [ ! -e align.reads.$$n.gz ]; then echo align.reads.$$n.gz; fi; done

SLICES?=1
MYSLICE?=0
oneslice:
	make -k -j $(NCORES) $(shell ls $(IMAGEDIR)/999 | tr -dc '0-9\n' | uniq | perl -ne 'next unless ($$_ % $(SLICES) == $(MYSLICE)); s/^/align.reads./; s/$$/.gz/; print')


align.reads.%.gz: align.reads.%
	gzip -9v $<
align.reads.%: $(SORTEDTAGS)
	$(ONNODE) oneframe.sh $* >$@ 2>$@.stderr || rm -v $@
map-readcount.png: framestats.dat
	map1var.pl < $< > $@
framestats.dat: $(shell ls align.reads.* 2>/dev/null)
	framestats.pl $(POSITIONLIST) > $@

# arch-tag: Tom Clegg Fri Mar 16 20:43:08 PDT 2007 (align-call/Makefile)
