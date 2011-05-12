# get basic stuff and read in the data
for(x in commandArgs()) {
   curarg = strsplit(x,'=',fixed=TRUE)  # split arguments into two parts
   if(!is.na(curarg[[1]][2])) {         # see if 2nd argument is NA (ignore if is) 
      assign(curarg[[1]][1],curarg[[1]][2])
  }	
}

postscript(paste("|convert ps:- -rotate 90 ",imagefile,sep=""), width=6, height=3, onefile=F);
T <- read.delim(infile,header=TRUE);

# Split the data into 2 for the 0 and 1 for m
#graphs <- split(T,T["m"]);

# build the pretty tables of data
data_0 <- T[,3:14]

color <- gray(c(1,.8,.4,.2,0));
palette(color)
#par(xpd=TRUE, pin=c(5,2));
par(xpd=TRUE);

y_tickmarks = c(0,25,50,75,100,125);
# Plot the data
barplot(
        as.matrix(data_0),
        main=paste(organism,", m=",m,sep=""),
        ylim=c(0,100),
        ylab= "% of Total Mismatches",
        axes=TRUE,
        beside=TRUE,
        col=1:5
);

dev.off();
