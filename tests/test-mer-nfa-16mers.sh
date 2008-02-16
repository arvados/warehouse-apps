#!/bin/sh

ME=test-mer-nfa-16mers
echo -n "$ME "

gread <<EOF > $ME.samples.dat
#: taql-0.1/text
# field "mer0" "uint64"
# field "mer1" "uint64"
#.
acgtacgtacgtacgt agctagctagctagct
aaaaaaaaaaaaaaaa cccccccccccccccc
acgtacgtacgtacgt agctagctagctagct
agctagctagctagct acgtacgtacgtacgt
EOF

gread <<EOF > $ME.genome.dat
#: taql-0.1/text
# field "mer0" "uint64"
#.
acgtacgtgggacgta
cgtttttttttttttt
tttttttttttttttt
tttttttttttttttt
tttttttttttttttt
tttttttttttttttt
tttagctagcttttag
ctagctaaaaaaaaaa
acgtacgtgggacgta
cgtttttttttttttt
tttttttttttttttt
tttttttttttttttt
tttttttttttttttt
tttttttttttttttt
tttagctagcttttag
ctagctaaaaaaaaaa
EOF

complement-mers --mer0-col mer0 --mer1-col mer1 < $ME.samples.dat > $ME.samples-2.dat

all-mers -m mer0 -n 16 < $ME.genome.dat \
| all-mers-gap -n 16 --gap-min 3 --gap-max 4 --gap-pos 8 \
| mer-nfa --snps --all \
  --m0 16 \
  --gmin0 16 --gmax0 300 --m1 16 \
  -r - -s $ME.samples-2.dat -o - \
  | tee $ME.placed.dat \
  | gprint \
  | egrep -v '^#' \
  | cut -d\  -f1,3- \
  > $ME.placed.txt
diff -u - $ME.placed.txt <<EOF || true
7 0 174
4 0 174
0 0 174
7 209 469
4 209 469
0 209 469
EOF

place-report -n 16 -r $ME.genome.dat -s $ME.samples.dat -p $ME.placed.dat --gap-min 3 --gap-max 4 --gap-pos 8 --two-inrecs-per-sample --ref-label chrZZ.fa --add-sample-id 0 | gprint >$ME.report

cat $ME.report

perl -ne 'next if /^#/; @a=split; die if $a[-3] ne 0 && $a[-3] ne 1' $ME.report

echo OK
