#!/bin/sh

ME=test-mer-nfa-smallgap
echo -n "$ME "

gread <<EOF > $ME.samples.dat
#: taql-0.1/text
# field "readid" "uint64"
# field "mer0" "uint64"
# field "mer1" "uint64"
#.
10 acgtacgtacgtac agctagctagctag
20 aaaaaaaaaaaaaa cccccccccccccc
30 acgtacgtacgtac agctagctagctag
40 ctagctagctagct gtacgtacgtacgt
EOF

gread <<EOF > $ME.genome.dat
#: taql-0.1/text
# field "mer0" "uint64"
#.
acgtacggggtacg
tacttttttttttt
tttttttttttttt
tttttttttttttt
tttttttttttttt
tttttttttttttt
tttagctagctttt
agctagacgtacgg
gggtacgtactttt
tttttttttttttt
tttttttttttttt
tttttttttttttt
tttttttttttttt
tttttttttttttt
tttttttttttttt
tttttttttttttt
ttttttttttagct
agctttttagctag
ctccccccccccgg
gggggggggggg
EOF

complement-mers --mer0-col mer0 --mer1-col mer1 < $ME.samples.dat > $ME.samples-2.dat

all-mers -m mer0 -n 14 < $ME.genome.dat \
| all-mers-gap -n 14 --gap-min 3 --gap-max 4 --gap-pos 7 \
| mer-nfa --snps --all \
  --m0 14 \
  --gmin0 14 --gmax0 300 --m1 14 \
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

place-report -n 14 -r $ME.genome.dat -s $ME.samples.dat -p $ME.placed.dat --gap-min 3 --gap-max 4 --gap-pos 7 --two-inrecs-per-sample --ref-label chrZZ.fa --sample-id-col readid | gprint >$ME.report

cat $ME.report

perl -ne 'next if /^#/; @a=split; die if $a[-3] ne 0 && $a[-3] ne 1' $ME.report

echo OK
