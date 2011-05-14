# The "Greg" pipeline
#
# Author: Tom Clegg
#

.SECONDARY:

BIGGAPMIN?=0
BIGGAPMAX?=1000

NCORES?=1
TIME?=time
MERSIZE=12
SMALLGAPMIN=5
SMALLGAPMAX=6
SMALLGAPPOS=6
POSPERREF:=$(shell echo $(SMALLGAPMAX) $(SMALLGAPMIN) - 1 + p | dc)
NFAGAPMIN:=$(shell echo '[0]sz $(BIGGAPMIN) $(SMALLGAPMIN) + $(MERSIZE) + $(POSPERREF) * $(MERSIZE) - 1 - d 0 >z p' | dc)
NFAGAPMAX:=$(shell echo '$(BIGGAPMAX) $(SMALLGAPMAX) + $(MERSIZE) + $(POSPERREF) * $(MERSIZE) - 1 + p' | dc)

include $(BUILD)/ROOTPATHS

all:
	$(MAKE) -j $(NCORES) nfa-report.txt

samples.dat: samples.txt
	$(TIME) sh $(srcroot)/greg/reads-to-dat.sh < $< > $@
%.2ips.dat: %.dat
	$(TIME) complement-mers -m mer0 -M mer1 -n 12 < $< > $@
%-$(MERSIZE).dat: %.fa
	$(TIME) perl $(srcroot)/madeleine/chr-to-dat.pl -n $(MERSIZE) < $< > $@
	ls -l $@
%.nfa-placed.dat: samples.2ips.dat %-$(MERSIZE).dat
	if [ -e $@ ]; then rm $@; fi
	all-mers -n 12 < $*-$(MERSIZE).dat \
		| all-mers-gap -n $(MERSIZE) --gap-min $(SMALLGAPMIN) --gap-max $(SMALLGAPMAX) --gap-pos $(SMALLGAPPOS) \
		| $(TIME) mer-nfa --snps --all \
		--m0 $(MERSIZE) --gmin0 $(NFAGAPMIN) --gmax0 $(NFAGAPMAX) \
		--m1 $(MERSIZE) \
		-r - -s samples.2ips.dat -o $@
	-ls -l $@
%.nfa-report.dat: samples.2ips.dat %-$(MERSIZE).dat %.nfa-placed.dat
	$(TIME) place-report --two-inrecs-per-sample \
		--gap-pos $(SMALLGAPPOS) \
		--gap-min $(SMALLGAPMIN) \
		--gap-max $(SMALLGAPMAX) \
		-n $(MERSIZE) \
		-s samples.dat \
		-r $*-$(MERSIZE).dat \
		-p $*.nfa-placed.dat \
		-o $@
%.nfa-report.txt: %.nfa-report.dat
	gprint < $< \
	| sort -u \
	| sort -n \
	| $(TIME) perl $(srcroot)/greg/nfa-report.pl samples.dat $(BIGGAPMIN) $(BIGGAPMAX) -1 \
	> $@
nfa-report.txt: $(shell ls -1 chr*.fa | sed -e 's/.fa$$/.nfa-report.txt/')
	cat $^ > $@


###
### Test / comparison tools
###

samples.txt: gmc1_15c.reads.gz
	zcat < $< > $@
	[ "`md5sum $@`" = "82989d08e9219f7aa59dcfc4e5827b25  samples.txt" ]

# arch-tag: Tom Clegg Sun Mar  4 15:22:42 PST 2007 (greg/Makefile)
