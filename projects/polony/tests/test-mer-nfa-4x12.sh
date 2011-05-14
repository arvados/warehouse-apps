#!/bin/sh

ME=test-mer-nfa-4x12
echo -n "$ME "

gread <<EOF > $ME.samples.dat
#: taql-0.1/text
# field "mer0" "uint64"
# field "mer1" "uint64"
# field "mer2" "uint64"
# field "mer3" "uint64"
#.
tgctgcagcagc cacagagatata tagttagttagt aaaaaaaaatgc
taaaaaaaaaat ccccccccccct gggggggggggt agagagagagag
EOF

gread <<EOF > $ME.genome.dat
#: taql-0.1/text
# field "mer0" "uint64"
#.
tgctgcagcagc
tcacagagatat
actagttagtta
gtaaaaaaaaaa
tgctgcagcagc
cacagagatata
tagttagttagt
aaaaaaaaaaat
cccccccccccc
gggggggggggg
gg
EOF

all-mers -m mer0 -n 12 < $ME.genome.dat | mer-nfa --snps --all \
  --m0 12 \
  --gmin0 1 --gmax0 1 --m1 12 \
  --gmin1 1 --gmax1 1 --m2 12 \
  --gmin2 1 --gmax2 1 --m3 12 \
  -r - -s $ME.samples.dat -o - \
  | gprint \
  | egrep -v '^#' \
  | cut -d\  -f1,3- \
  > $ME.noflags.4
diff -u - $ME.noflags.4 <<EOF
0 0 13 26 39
EOF

all-mers -m mer0 -n 12 < $ME.genome.dat | mer-nfa --snps --all \
  --m0 12 \
  --gmin0 0 --gmax0 1 --m1 12 \
  --gmin1 0 --gmax1 20 --m2 12 \
  --gmin2 0 --gmax2 1 --m3 12 \
  -r - -s $ME.samples.dat -o - \
  | gprint \
  | egrep -v '^#' \
  | cut -d\  -f1,3- \
  > $ME.noflags.4b
diff -u - $ME.noflags.4b <<EOF
0 0 13 26 39
EOF

all-mers -m mer0 -n 12 < $ME.genome.dat | mer-nfa --snps --all \
  --m0 12 \
  --gmin0 1 --gmax0 1 --m1 12 \
  --gmin1 1 --gmax1 1 --m2 12 \
  -r - -s $ME.samples.dat -o - \
  | gprint \
  | egrep -v '^#' \
  | cut -d\  -f1,3- \
  > $ME.noflags.3
diff -u - $ME.noflags.3 <<EOF
0 0 13 26
1 83 96 109
1 84 97 110
EOF

all-mers -m mer0 -n 12 < $ME.genome.dat | mer-nfa --snps --all \
  --m0 12 \
  --gmin0 1 --gmax0 1 --m1 12 \
  -r - -s $ME.samples.dat -o - \
  | gprint \
  | egrep -v '^#' \
  | cut -d\  -f1,3- \
  > $ME.noflags.2
diff -u - $ME.noflags.2 <<EOF
0 0 13
1 83 96
1 84 97
EOF

all-mers -m mer0 -n 12 < $ME.genome.dat | mer-nfa --snps --all \
  --m0 12 \
  -r - -s $ME.samples.dat -o - \
  | gprint \
  | egrep -v '^#' \
  | cut -d\  -f1,3- \
  > $ME.noflags.1
diff -u - $ME.noflags.1 <<EOF
0 0
1 37
0 48
1 83
1 84
EOF

echo OK

# arch-tag: Tom Clegg Sun Feb  4 17:14:37 PST 2007 (tests/test-mer-nfa-4x12.sh)
