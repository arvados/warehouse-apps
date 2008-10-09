# get basic stuff and read in the data
for(x in commandArgs()) {
   curarg = strsplit(x,'=',fixed=TRUE)  # split arguments into two parts
   if(!is.na(curarg[[1]][2])) {         # see if 2nd argument is NA (ignore if is)
      assign(curarg[[1]][1],curarg[[1]][2])
  }
}

postscript(paste("|convert ps:- ",imagefile,sep=""), width=as.numeric(graph_w),horizontal=F, height=as.numeric(graph_h), onefile=F);

A <- read.table(infile,header=T,sep='')
color <- gray(seq(0,1,by=.25))
palette(color)
par(xpd=T,mar=c(1,1,1,1));
barplot(t(as.matrix(A[,20:24])), col=1:5,axes=F,ylim=c(0,1000),border='#eeeeee')
dev.off();
