# Fetch data files before running this:
#  cd /tmp
#  echo -n Password:; read p
#  for m in \
#  a2e33f1549957c92dc0710a37e43d888
#  do
#   wget --user=gclab --password=$p http://templeton-controller.freelogy.org/whget.cgi/$m/stats.txt -q -O $m
#   md5sum $m
#  done
# Then:
#  R --no-save < /path/to/gpplace.r

stats <- read.delim("a2e33f1549957c92dc0710a37e43d888",header=TRUE)

postscript(file="/tmp/mmrate-vs-quality.ps",
	   title="/tmp/mmrate-vs-quality.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F,
	   paper="letter")
plot(stats[,"X"],
     stats[,"mm"]/stats[,"total"],
     ylim=c(0.05,0.1),
     xlab="quality score",
     ylab="rate of mismatches, #mm / #calls"
     )

postscript(file="/tmp/basecount-vs-quality.ps",
	   title="/tmp/basecount-vs-quality.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F,
	   paper="letter")
plot(stats[,"X"],
     stats[,"total"],
     xlab="quality score",
     ylab="number of base calls"
     )

postscript(file="/tmp/mmrate-and-basecount-vs-quality.ps",
	   title="/tmp/mmrate-and-basecount-vs-quality.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F,
	   paper="letter")
binsize <- 1
xs <- by (stats[,"X"], list(mmrate=binsize*trunc(stats[,"X"]/binsize)), min);
totals <- by (stats[,"total"], list(mmrate=binsize*trunc(stats[,"X"]/binsize)), sum);
mms <- by (stats[,"mm"], list(mmrate=binsize*trunc(stats[,"X"]/binsize)), sum);
binsizecomment <- paste(" range (bin size = ", binsize, ")")
if (binsize==1) binsizecomment <- ""
plot(xs,
     mms/totals,
     ylim=c(0.05,0.1),
     xlim=c(0,1000),
     xlab=paste("quality score", binsizecomment),
     ylab="rate of mismatches, #mm / #calls"
     )
par(new=TRUE)
plot(stats[,"X"],
     stats[,"total"],
     xlim=c(0,1000),
     xlab="",
     ylab="",
     xaxt="n",
     yaxt="n",
     )
