# usage example:
#
# wh job list warehouse_name=templeton | ./whusage >templeton.dat
# INFILE=templeton.dat OUTFILE=templeton.png R --no-save <whusage-graph.R
#

A <- read.delim(Sys.getenv('INFILE'),header=FALSE);

# drop last 2 rows (summary)
A <- A[1:(nrow(A)-2),];

postscript(paste('|convert ps:- -rotate 90', Sys.getenv('OUTFILE')));

par(xpd=T, mar=par()$mar+c(0,0,0,10));

barplot(c(as.matrix(A[,1])),
	main=paste("Cluster utilization (",
		   Sys.getenv('INFILE'),
		   ")",
		   sep=""),
	ylab="node seconds",
	col=heat.colors(1),
	names.arg=c(as.matrix(A[,2])));

dev.off();
