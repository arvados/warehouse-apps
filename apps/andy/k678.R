# -*- mode: c; -*-

# Read the tab delimited data in place-stats.tab
A <- read.delim(Sys.getenv('INFILE'),header=TRUE,check.names=FALSE);

A_max <- max(apply(A,2,sum));
names(A) <- chartr(',','\n',names(A));
names(A) <- gsub('s<','snps<',names(A));
names(A) <- gsub('<1','=0',names(A));

# Now split out anything after row number 6
row_split <- A[6:nrow(A),1:ncol(A)]
split_sum <- apply(row_split,2,sum)
sum_matrix <- as.matrix(split_sum)
sum_matrix[1,1] <- '>4';
sum_total <- t(as.table(sum_matrix))

# Take Anything after row 6
A <- A[1:5,1:ncol(A)]

A <- rbind(A,sum_total[1,1:ncol(sum_total)])

# Start the postscript device, and set it to output to Imagemagick
postscript(paste('|convert ps:- -rotate 90',Sys.getenv('OUTFILE')));

par(xpd=T, mar=par()$mar+c(3,0,0,12));

barplot(as.matrix(A[,2:ncol(A)]),
	main=paste("log(#placements) for k=6,7,8 with snps<1,2,3 (",
		   Sys.getenv('INFILE'),
		   ")",
		   sep=""),
	ylab="reads",
	space=c(0.5,0,0,0.5,0,0,0.5,0,0),
	cex.names=0.8,
	col=heat.colors(nrow(A)));

legend(ncol(A)+1,
       A_max,
       c(A[1:nrow(A),1]),
       cex=1,
       fill=heat.colors(nrow(A)),
       title='P=log(placements)');

dev.off();
