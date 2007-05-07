# The "Erez" pipeline
#
# Author: Tom Clegg
#

.SECONDARY:

MERCOUNTMIN?=2
MERCOUNTMAX?=4
NCORES?=1
MERSIZE?=10
LONGESTSAMPLE=64
DIM=$(MERCOUNT)x$(MERSIZE)$(CONTROLGROUP)
SAMPLES=samples-$(MERSIZE)$(CONTROLGROUP)
MERNFAOPTS:=$(shell k=0; while [ $$(($$k+1)) -lt $(MERCOUNT) ]; do echo " --m$$k $(MERSIZE) --gmin$$k 0 --gmax$$k 0"; k=$$(($$k+1)); done; echo " --m$$k $(MERSIZE)")

nfa-all:
	[ "`md5sum chromFa.zip`" = "ef679cf6867c5dd3bd1b0b56ce16b2ae  chromFa.zip" ]
	[ "`md5sum mirna454.txt.gz`" = "ecc3008932ffeafa45159db1079b71ca  mirna454.txt.gz" ]
	unzip -n chromFa.zip
	k=$(MERCOUNTMIN); \
	while [ $$(($$k*$(MERSIZE))) -le $(LONGESTSAMPLE) -a $$k -le $(MERCOUNTMAX) ]; \
	do \
		$(MAKE) nfa MERCOUNT=$$k; \
		k=$$(($$k+1)); \
	done
nfa:
	$(MAKE) -j $(NCORES) nfa-report-$(DIM).txt

include $(BUILD)/ROOTPATHS

samples-$(MERSIZE)complement.dat: mirna454.txt.gz
	zcat $< | tr ACGT TGCA | time perl $(srcroot)/erez/mirna-to-dat.pl $$((($(LONGESTSAMPLE)+$(MERSIZE)-1)/$(MERSIZE))) $(MERSIZE) > $@
samples-$(MERSIZE).dat: mirna454.txt.gz
	zcat $< | time perl $(srcroot)/erez/mirna-to-dat.pl $$((($(LONGESTSAMPLE)+$(MERSIZE)-1)/$(MERSIZE))) $(MERSIZE) > $@

%-$(MERSIZE).dat: %.fa
	time perl $(srcroot)/madeleine/chr-to-dat.pl -n $(MERSIZE) < $< > $@
	ls -l $@

%-$(DIM).nfa-placed.dat: %-$(MERSIZE).dat $(SAMPLES).dat
	all-mers -m mer0 -n $(MERSIZE) < $*-$(MERSIZE).dat \
		| mer-nfa --snps --all \
		$(MERNFAOPTS) \
		-r - -s $(SAMPLES).dat -o $@
	ls -l $@

%-$(DIM).nfa-report.dat: %-$(DIM).nfa-placed.dat $(SAMPLES).dat
	place-report --all-sample-fields --bp-after-match 64 -n $(MERSIZE) -r $*-$(MERSIZE).dat -s $(SAMPLES).dat -p $*-$(DIM).nfa-placed.dat > $@

nfa-report-$(DIM).txt: $(shell ls -1 *.fa 2>/dev/null | sed -e s,.fa,-$(DIM).nfa-report.dat,)
	for p in $^; \
		do \
			c=$${p%-$(DIM).nfa-report.dat}; \
			cat "$$p" | gprint | egrep -v '^#' | sort -u | sed -e "s/ / $$c /"; \
		done \
	| sort -n \
	| perl $(srcroot)/erez/nfa-report.pl \
	> $@
	md5sum $@

# arch-tag: Tue Jan 30 23:33:07 PST 2007 (erez/Makefile)
