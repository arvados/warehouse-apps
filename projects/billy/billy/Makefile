# The "Billy 12+12" pipeline
#
# Authors: Tom Clegg
#
# Example:
#
#    srcdir=/path/to/taql--devo--0.1
#    builddir=/tmp/build
#    workdir=/tmp/work
#
#    mkdir $builddir
#    cd $builddir
#    $srcdir/configure
#    $srcdir/mkx
#    $srcdir/mkx install
#
#    mkdir $workdir
#    cd $workdir
#    cp /path/to/hg18/chr18.fa .
#    cp /path/to/billy/26mers.txt .
#    cp /path/to/this/Makefile .
#    make BUILD=$builddir PATH="$PATH:$builddir/=install/bin"
#

.SECONDARY:

NCORES?=1
GAPMIN?=0
GAPMAX?=20

nfa:
	$(MAKE) -j $(NCORES) nfa-report.txt
snp:
	$(MAKE) -j $(NCORES) snp-report.txt
diff:
	$(MAKE) -j $(NCORES) diff-awz-nfa.txt
clean:
	-rm *.dat *.bitmap *.index *.placed *.nfa-diff-tmp

include $(BUILD)/ROOTPATHS

###
### The "snp-mers" pipeline
###

24mers.dat: 26mers.txt
	time perl $(srcroot)/billy/26mers-to-24mers-dat.pl < $< | complement-mers -m mer0 -M mer1 -n 12 > $@
24mers.mer0.bitmap: 24mers.dat
	time hash-mers -m mer0 -n 12 < $< > $@
24mers.mer1.bitmap: 24mers.dat
	time hash-mers -m mer1 -n 12 < $< > $@
24mers.index: 24mers.dat
	time index-mers -n 12 < 24mers.dat > 24mers.index
%.dat: %.fa
	time perl $(srcroot)/madeleine/chr-to-dat.pl -n 12 < $< > $@
%.placed: %.dat 24mers.mer0.bitmap 24mers.mer1.bitmap 24mers.dat 24mers.index
	all-mers -m mer0 -n 12 < $*.dat \
		| snp-mers -n 12 24mers.mer0.bitmap 24mers.mer1.bitmap \
		| billy-candidates --n-mers 12 --maxlettersingap 2 $*.dat \
		| place-mers -n 12 24mers.dat 24mers.index $*.dat \
		> $@
	-ls -l $@
snp-report.txt: $(shell ls -1 *.fa | sed -e s,.fa,.placed,)
	for p in *.placed; \
		do \
			c=$${p%.placed}; \
			gprint < "$$p" | sed -e "s/ / $$c /"; \
		done \
	| sort -n \
	| time perl $(srcroot)/billy/billy-report.pl \
	| sort -n \
	> $@
	md5sum $@

###
### The "mer-nfa" pipeline
###

nfa-samples.dat: 26mers.txt
	time perl $(srcroot)/billy/26mers-to-24mers-dat.pl < $< > $@
%.2ips.dat: %.dat
	complement-mers -m mer0 -M mer1 -n 12 < $< > $@
%.nfa-placed.dat: %.dat nfa-samples.2ips.dat
	if [ -e $@ ]; then rm $@; fi
	time all-mers -m mer0 -n 12 < $*.dat \
		| mer-nfa --snps --all \
		--m0 12 --gmin0 $(GAPMIN) --gmax0 $(GAPMAX) \
		--m1 12 \
		-r - -s nfa-samples.2ips.dat -o $@
	-ls -l $@
%.nfa-report.dat: %.nfa-placed.dat nfa-samples.dat
	place-report --two-inrecs-per-sample -n 12 -r $*.dat -s nfa-samples.dat -p $*.nfa-placed.dat | billy-grep > $@
nfa-report.txt: $(shell ls -1 *.fa | sed -e s,.fa,.nfa-report.dat,)
	for p in *.nfa-report.dat; \
		do \
			c=$${p%.nfa-report.dat}; \
			cat "$$p" | gprint | sort -u | sed -e "s/ / $$c /"; \
		done \
	| sort -n \
	| time perl $(srcroot)/billy/nfa-report.pl nfa-samples.dat \
	| sort -n \
	> $@
	md5sum $@

###
### Test / comparison tools
###

diff-awz-nfa.txt: awz-report-min.txt nfa-report-min.txt
	-diff awz-report-min.txt nfa-report-min.txt > $@
nfa-report-min.txt: nfa-report.txt
	sed -e 's/,/\t/g' < $< | cut -f1,4,6-10 | perl -ne 'chop; @a=split("\t"); print "$$a[0]\t$$a[1]\t$$a[2]$$a[3]\t$$a[4]\t$$a[5]$$a[6]\n"' > $@
awz-report-min.txt: billy-data-20070129.tar.gz
	tar xzf $< $@
	[ "`md5sum $@`" = "51bf9425121ad865fd17ebca3e8a69aa  awz-report-min.txt" ]
26mers.txt: billy-data-20070129.tar.gz
	tar xzf $< $@
	[ "`md5sum $@`" = "dd3c006a1dc4000751355c2d53f578f0  26mers.txt" ]

###
### Debug tools
###

%.nfa-diff: %.nfa-report.dat %.placed
	gprint < $*.nfa-report.dat | grep -v \# | sort -nu | cut -d\  -f1,3,5,6 | tr ACGT acgt > $*.nfa-diff-tmp
	-gprint < $*.placed | grep -v \# | sort -nu | cut -d\  -f1,2,5,6 | tr ACGT acgt | diff -u - $*.nfa-diff-tmp > $@
	ls -l $@

# arch-tag: Tom Clegg Sun Nov 12 01:49:08 PST 2006 (billy/Makefile)
