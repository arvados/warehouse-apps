# get basic stuff and read in the data
for(x in commandArgs()) {
   curarg = strsplit(x,'=',fixed=TRUE)  # split arguments into two parts
   if(!is.na(curarg[[1]][2])) {         # see if 2nd argument is NA (ignore if is)
      assign(curarg[[1]][1],curarg[[1]][2])
  }
}

postscript(paste("|convert ps:- -rotate 90 ",imagefile,sep=""), width=as.numeric(graph_w), height=as.numeric(graph_h), onefile=F);

T <- read.delim(infile,header=TRUE,row.names=1);

color <- gray(seq(1,0,by=(1/(ncol(T)-1))*-1));
palette(color)
par(xpd=TRUE, mar=par()$mar+c(3,0,0,12));

top_axis <- ceiling(max(T)/10)*10;

# Plot the data
barplot(
        as.matrix(t(T)),
        main=title,
        ylim=c(0,top_axis),
        ylab= "% of Total",
        axes=TRUE,
        beside=TRUE,
        col=1:ncol(T)
);
legend((nrow(T)*ncol(T))+nrow(T)+1,max(T),dimnames(T)[2][[1]], cex=1, fill=1:ncol(T),title='Whatever Title');

dev.off();
