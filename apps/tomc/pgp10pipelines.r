# Fetch data files before running this:
#  cd /tmp
#  for m in \
#  e360ecc2fb53790628bc990fc6568f00 \
#  a7c1c32fd653dd069bd9a17740f58e83 \
#  8b0d68956d7b747e816c0f1f1fb25d40 \
#  31e81993fe9a19104d864f56f5ed7155 \
#  d3323e14a7bb07d0ea058a144cfbe856 \
#  611289629595e6331701b3ac2a74319f \
#  b0e21209c3ccc04f33d32498ec3b8a67
#  do
#   wget http://genomerator-dev.freelogy.org/pgp10factory/allstats.cgi?$m -q -O $m
#   md5sum $m
#  done
# Then:
#  R --no-save < /path/to/pgp10pipelines.r

T_1s_1c <- read.delim("e360ecc2fb53790628bc990fc6568f00",header=TRUE)[1:10,]
T_1s_3c <- read.delim("a7c1c32fd653dd069bd9a17740f58e83",header=TRUE)[1:10,]
T_2s_3c <- read.delim("8b0d68956d7b747e816c0f1f1fb25d40",header=TRUE)[1:10,]
T_1s_1c_hg18 <- read.delim("31e81993fe9a19104d864f56f5ed7155",header=TRUE)[1:10,]
T_1s_3c_hg18 <- read.delim("d3323e14a7bb07d0ea058a144cfbe856",header=TRUE)[1:10,]
T_2s_3c_hg18 <- read.delim("611289629595e6331701b3ac2a74319f",header=TRUE)[1:10,]

Allstats <- T_1s_1c
Allstats <- merge(Allstats, T_1s_1c, by="X", suffixes=c("",".1s_1c"), sort=FALSE)
Allstats <- merge(Allstats, T_1s_3c, by="X", suffixes=c("",".1s_3c"), sort=FALSE)
Allstats <- merge(Allstats, T_2s_3c, by="X", suffixes=c("",".2s_3c"), sort=FALSE)
Allstats <- merge(Allstats, T_1s_1c_hg18, by="X", suffixes=c("",".1s_1c_hg18"), sort=FALSE)
Allstats <- merge(Allstats, T_1s_3c_hg18, by="X", suffixes=c("",".1s_3c_hg18"), sort=FALSE)
Allstats <- merge(Allstats, T_2s_3c_hg18, by="X", suffixes=c("",".2s_3c_hg18"), sort=FALSE)

postscript(file="/tmp/placed-vs-reads.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
plot(t(T_2s_3c[,"reads"])*36,
     t(T_2s_3c[,"places"])*36,
     xlab="bases input",
     ylab="bases placed")

postscript(file="/tmp/covered-vs-reads.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
plot(t(T_2s_3c[,"reads"])*36,
     t(T_2s_3c[,"covers"]),
     ylim=c(0,8956949),
     xlab="bases input",
     ylab="loci covered")

postscript(file="/tmp/con-dis-nocall-1s1c.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
barplot(t(T_1s_1c[,c("con","dis","nocall")]),
	col=gray(c(.8,.5,1)),
	ylab="concordant, discordant, nocall")

postscript(file="/tmp/con-dis-nocall-1s3c.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
barplot(t(T_1s_3c[,c("con","dis","nocall")]),
	col=gray(c(.8,.5,1)),
	ylab="concordant, discordant, nocall")

postscript(file="/tmp/con-dis-nocall-2s3c.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
barplot(t(T_2s_3c[,c("con","dis","nocall")]),
	col=gray(c(.8,.5,1)),
	ylab="concordant, discordant, nocall")

postscript(file="/tmp/con-dis-nocall-1s1c-hg18.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
barplot(t(T_1s_1c_hg18[,c("con","dis","nocall")]),
	col=gray(c(.8,.5,1)),
	ylab="concordant, discordant, nocall")

postscript(file="/tmp/con-dis-nocall-1s3c-hg18.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
barplot(t(T_1s_3c_hg18[,c("con","dis","nocall")]),
	col=gray(c(.8,.5,1)),
	ylab="concordant, discordant, nocall")

postscript(file="/tmp/con-dis-nocall-2s3c-hg18.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)
barplot(t(T_2s_3c_hg18[,c("con","dis","nocall")]),
	col=gray(c(.8,.5,1)),
	ylab="concordant, discordant, nocall");



postscript(file="/tmp/filter-effect-55k.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)

foo <- Allstats[,c("con.1s_1c","dis.1s_1c","nocall.1s_1c")]
foo[11:20,] <- Allstats[,c("con.1s_3c","dis.1s_3c","nocall.1s_3c")]
foo[21:30,] <- Allstats[,c("con.2s_3c","dis.2s_3c","nocall.2s_3c")]

barplot(t(foo[order(c(3*(1:10)-2,3*(1:10)-1,3*(1:10))),]),
	space=c(0,rep(c(0,0,1),9),0,0),
	col=gray(c(.8,.5,1)),
	main="Effect of filters on concordance (55k probe reference)",
	ylab="concordant, discordant, nocall",
	xaxt="n")
axis(1,
     labels=c(1:10),
     at=(1:10)*4-2.5,
     tick=FALSE)



postscript(file="/tmp/filter-effect-hg18.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)

foo <- Allstats[,c("con.1s_1c_hg18","dis.1s_1c_hg18","nocall.1s_1c_hg18")]
foo[11:20,] <- Allstats[,c("con.1s_3c_hg18","dis.1s_3c_hg18","nocall.1s_3c_hg18")]
foo[21:30,] <- Allstats[,c("con.2s_3c_hg18","dis.2s_3c_hg18","nocall.2s_3c_hg18")]

barplot(t(foo[order(c(3*(1:10)-2,3*(1:10)-1,3*(1:10))),]),
	space=c(0,rep(c(0,0,1),9),0,0),
	col=gray(c(.8,.5,1)),
	main="Effect of filters on concordance (hg18 reference)",
	ylab="concordant, discordant, nocall",
	xaxt="n")
axis(1,
     labels=c(1:10),
     at=(1:10)*4-2.5,
     tick=FALSE)



postscript(file="/tmp/reference-effect-2s3c.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)

foo <- Allstats[,c("con.2s_3c","dis.2s_3c")]
foo[11:20,] <- Allstats[,c("con.2s_3c_hg18","dis.2s_3c_hg18")]

barplot(t(foo[ order(c(2*(1:10)-1, 2*(1:10))), ]),
	space=c(0,rep(c(0,1),9),0),
	col=gray(c(.8,.5,1)),
	main="Effect of reference (55k probe or hg18) on concordance",
	ylab="concordant, discordant",
	xlab="55k, hg18",
	xaxt="n")
axis(1,
     labels=c(1:10),
     at=(1:10)*3-2.5,
     tick=FALSE)


postscript(file="/tmp/filter-effect-on-het-and-dbsnp.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)

foo <- Allstats[,c("het.y.1s_1c","hom.y.1s_1c","het.n.1s_1c","hom.n.1s_1c")]
foo[11:20,] <- Allstats[,c("het.y.1s_3c","hom.y.1s_3c","het.n.1s_3c","hom.n.1s_3c")]
foo[21:30,] <- Allstats[,c("het.y.2s_3c","hom.y.2s_3c","het.n.2s_3c","hom.n.2s_3c")]

barplot(t(foo[order(c(3*(1:10)-2,3*(1:10)-1,3*(1:10))),]),
	space=c(0,rep(c(0,0,1),9),0,0),
	main="Effect of filters on het/hom/dbsnp calls (55k probe reference)",
	ylab="het/dbsnp, hom/dbsnp, het/other, hom/other",
	xlab="1s1c/1s3c/2s3c for each participant",
	xaxt="n")
axis(1,
     labels=c(1:10),
     at=(1:10)*4-2.5,
     tick=FALSE)


postscript(file="/tmp/filter-effect-on-het-and-dbsnp-proportion.ps",
	   width=6,
	   height=6,
	   horizontal=F,
	   onefile=F)

foo <- Allstats[,c("het.y.1s_1c","hom.y.1s_1c","het.n.1s_1c","hom.n.1s_1c")]
foo[11:20,] <- Allstats[,c("het.y.1s_3c","hom.y.1s_3c","het.n.1s_3c","hom.n.1s_3c")]
foo[21:30,] <- Allstats[,c("het.y.2s_3c","hom.y.2s_3c","het.n.2s_3c","hom.n.2s_3c")]
foo <- foo/rowSums(foo)

barplot(t(foo[order(c(3*(1:10)-2,3*(1:10)-1,3*(1:10))),]),
	space=c(0,rep(c(0,0,1),9),0,0),
	main="Effect of filters on het/hom/dbsnp calls (55k probe reference)",
	ylab="proportion of het/dbsnp, hom/dbsnp, het/other, hom/other",
	xlab="1s1c/1s3c/2s3c for each participant",
	xaxt="n")
axis(1,
     labels=c(1:10),
     at=(1:10)*4-2.5,
     tick=FALSE)
