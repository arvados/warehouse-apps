all: 4mer-6093.jpg 4mer-6094.jpg k678-trial1.jpg k678-trial2.jpg k678-trial3.jpg
all: 4mer-6093.png 4mer-6094.png k678-trial1.png k678-trial2.png k678-trial3.png
clean:
	-rm 4mer-*.jpg k678-*.jpg 4mer-*.png k678-*.png *.tab
k678-%.png: k678-%.txt
	INFILE="$<" OUTFILE="$@" R --no-save < k678.R
4mer-%.png: %.tab
	INFILE="$<" OUTFILE="$@" R --no-save < 4mer-variants.R
%.jpg: %.png
	convert "$<" "$@"
%.tab: %.txt
	< $< cut -d\  -f4,8,11,14,17 | tee $*.tmp | sort -n | perl dec2fasta.pl | perl -pe 's, ,\t,g' > $@
