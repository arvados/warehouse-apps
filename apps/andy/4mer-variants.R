A <- read.delim(Sys.getenv('INFILE'),header=FALSE);

# drop last column ("badindex")
A <- A[,1:ncol(A)-1];

postscript(paste('|convert ps:- -rotate 90', Sys.getenv('OUTFILE')));

par(xpd=T, mar=par()$mar+c(0,0,0,10));

barplot(as.matrix(t(A[,2:ncol(A)])),
	main=paste("Distribution of reads sampled from hg18 (",
		   Sys.getenv('INFILE'),
		   ")",
		   sep=""),
	ylab="variants",
	col=heat.colors(ncol(A)-1),
	names.arg=c(as.matrix(A[,1])));

legend (nrow(A),
	max(A[,2:ncol(A)]),
	c('count','skip','bad'),
	cex=0.8,
	fill=heat.colors(ncol(A)-1));

dev.off();
