# 
library(nat.flybrains)

library(doMC)
registerDoMC(7)
allpns.JFRC2013=xform_brain(allpns.FCWB, ref=JFRC2013, sample = FCWB, .parallel=T)
open3d()
plot3d(JFRC2013)
plot3d(allpns.JFRC2013, skipRedraw = T)
fileformats(class='neuron', write=TRUE)
x=resample(allpns.JFRC2013[[1]], 1)
clear3d();plot3d(x)
points3d(xyzmatrix(x), col='black', size=2)
dim(JFRC2013)
prod(dim(JFRC2013))*8/1e9
y=as.im3d(xyzmatrix(x), JFRC2013)
write.im3d(y, '/GD/projects/Mike/overlaps/pn1.nrrd', dtype='byte')

table(allpns.FCWB[,'PNType'])
table(allpns.FCWB[,'Glomerulus'])

setwd("/GD/projects/Mike/overlaps/")
for(g in unique(subset(allpns.FCWB, PNType!='LHN')[,'Glomerulus'])  ){
  message("g=",g)
  mypns=subset(allpns.JFRC2013, Glomerulus==g)
  mypns.resample=nlapply(mypns, resample, 1)
  myvol=as.im3d(xyzmatrix(mypns.resample), JFRC2013)
  write.im3d(y, paste0(g,'.nrrd'), dtype='byte')
}
