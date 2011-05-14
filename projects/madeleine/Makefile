################################################################
# Copyright (C) 2006 Harvard University
# Author: Tom Clegg
# 
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
# 

.SECONDARY:

NCORES?=1
MAXSAMPLES?=2000000
HALFMAXSAMPLES:=$(shell echo 0 k $(MAXSAMPLES) 2 / p | dc)

nfa:
	$(MAKE) samples.split.$(MAXSAMPLES)
	$(MAKE) -j $(NCORES) nfa-report.txt
diff:
	$(MAKE) y2.annotate.out.rawcalls mut_strain.mck
	-ln -s y2.annotate.out.rawcalls samples
	[ "`md5sum samples`" = "9992599b070b145f9c9082176ca61c6d  samples" ]
	-ln -s mut_strain.mck genome
	[ "`md5sum genome`" = "f2bd106e8b02c62072889a8a048d14de  genome" ]
	$(MAKE) samples.split.$(MAXSAMPLES)
	$(MAKE) nfa diff-y2-nfa.txt
clean:
	-rm *.dat samples.part.* samples.split.*

include $(BUILD)/ROOTPATHS

###
### The "mer-nfa" pipeline
###

N_MERS=12
SMALLGAPMIN?=5
SMALLGAPMAX?=6
BIGGAPMIN?=750
BIGGAPMAX?=1250
POSPERREF:=$(shell echo $(SMALLGAPMAX) $(SMALLGAPMIN) - 1 + p | dc)
NFAGAPMIN:=$(shell echo '[0]sz $(BIGGAPMIN) $(SMALLGAPMIN) + $(N_MERS) + $(POSPERREF) * $(N_MERS) - 1 - d 0 >z p' | dc)
NFAGAPMAX:=$(shell echo '$(BIGGAPMAX) $(SMALLGAPMAX) + $(N_MERS) + $(POSPERREF) * $(N_MERS) - 1 + p' | dc)

samples.split.$(MAXSAMPLES): samples
	-rm samples.part.* samples.split.*
	perl $(srcroot)/madeleine/samples-split.pl $(HALFMAXSAMPLES) samples.part. < samples
	touch $@
samples.part.%.dat: samples.part.%
	time perl $(srcroot)/madeleine/y2rawcalls-to-$(N_MERS)mers.pl < $< > $@
genomesize: genome
	tr -dc ACGTNacgtn < $< | wc -c > $@
genome.dat: genome
	time perl $(srcroot)/madeleine/chr-to-dat.pl -n $(N_MERS) < $< > $@
all-mers.dat: genome.dat
	time all-mers -m mer0 -n $(N_MERS)  < $< | all-mers-gap -n $(N_MERS) --gap-min 5 --gap-max 6 --gap-pos 6 > $@
%.2ips.dat: %.dat
	complement-mers -m mer0 -M mer1 -n 12 < $< > $@
%.nfa-placed.dat: %.2ips.dat all-mers.dat
	if [ -e $@ ]; then rm $@; fi
	mer-nfa --snps --all \
		--m0 $(N_MERS) --gmin0 $(NFAGAPMIN) --gmax0 $(NFAGAPMAX) \
		--m1 $(N_MERS) \
		-r all-mers.dat -s $*.2ips.dat -o $@
	-ls -l $@
%.nfa-report.txt: %.dat genome.dat %.nfa-placed.dat genomesize
	place-report --two-inrecs-per-sample \
		--gap-pos 6 \
		--gap-min 5 \
		--gap-max 6 \
		-n $(N_MERS) \
		-s $*.dat \
		-r genome.dat \
		-p $*.nfa-placed.dat \
	| gprint \
	| sort -u \
	| sort -n \
	| perl $(srcroot)/madeleine/nfa-report.pl $* $(BIGGAPMIN) $(BIGGAPMAX) `cat genomesize` \
	> $@
nfa-report.txt: $(shell ls -1 samples.part.???? | sed -e 's/$$/.nfa-report.txt/')
	cat $^ > $@

###
### Test / comparison tools
###

y2.annotate.out:
	tar xzf madeleine-data-20070129.tar.gz $@
	[ "`md5sum $@`" = "028cc5dbf9c4f39233de44a4a72e1a6f  $@" ]
y2.annotate.out.rawcalls:
	tar xzf madeleine-data-20070129.tar.gz $@
	[ "`md5sum $@`" = "9992599b070b145f9c9082176ca61c6d  $@" ]
mut_strain.mck:
	tar xzf madeleine-data-20070129.tar.gz $@
	[ "`md5sum $@`" = "f2bd106e8b02c62072889a8a048d14de  $@" ]
diff-y2-nfa.txt: y2.annotate.out nfa-report.txt
	-diff y2.annotate.out nfa-report.txt > $@

# arch-tag: Tom Clegg Fri Dec  8 16:50:43 PST 2006 (madeleine/Makefile)
