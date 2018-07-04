#LHIN analysis using the data from temperature and taste projection neuron lines 

library(xlsx)
library(dplyr)
biocLite("made4")
library(nat)
library(ggplot2)
library(made4)
library(xlsx)
library(NMF)                # aheatmap()

#First lets make the masks
maindir<-"/Volumes/Samsung_T3/"
setwd(maindir)
inputdir<-"/Volumes/Samsung_T3/LH_segmentations/macro_input/mask.tif"
command<-"java -Xmx5024m -jar /Applications/ImageJ/ImageJ.app/Contents/Java/ij.jar -ijpath /Applications/ImageJ -macro /Users/michaeljohndolan/projects/polarity_segmentations_organisation_Final/MB_mask_macro.ijm "

#First the taste masks 
list1<-list.files() #Lists two different catagories 
for (i in 1:length(list1)) {
  list2<-list.files(path = paste0("./", list1[i]))
  for (j in 1:length(list2)) {
    #List the different tiffs in each cell-type within a catagory
    tiffs<-list.files(path =paste0("./", list1[i], "/", list2[j]), pattern = "*.tif", recursive = TRUE)
    
    #axon segmentation mask creation
    tiffs.axon<-grep(pattern = "axonmemb_",x = tiffs, value = TRUE, fixed = TRUE )
    tiffs.axon<-paste0(maindir, "Taste_segmentations/", list1[i], "/", list2[j], "/", tiffs.axon)
    tiffs.axon<-paste(tiffs.axon, collapse = "*") #Concatenate into one argument for the ImageJ macro call
    system(paste0(command,tiffs.axon))
    #Set the mask output folder in the macro too
    file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                            ,"Mask_axonmemb_", list1[i], "_",list2[j], "_v1.tif"))
  }
}

#Run the temperature masks 
setwd("/Volumes/Samsung_T3/TemperaturePN_segmentations")
list1<-list.files() #Lists two different catagories 
for (i in 1:length(list1)) {
  list2<-list.files(path = paste0("./", list1[i]))
  for (j in 1:length(list2)) {
    #List the different tiffs in each cell-type within a catagory
    tiffs<-list.files(path =paste0("./", list1[i], "/", list2[j]), pattern = "*.tif", recursive = TRUE)
    
    #axon segmentation mask creation
    tiffs.axon<-grep(pattern = "axonmemb_",x = tiffs, value = TRUE, fixed = TRUE )
    tiffs.axon<-paste0(maindir, "TemperaturePN_segmentations/", list1[i], "/", list2[j], "/", tiffs.axon)
    tiffs.axon<-paste(tiffs.axon, collapse = "*") #Concatenate into one argument for the ImageJ macro call
    system(paste0(command,tiffs.axon))
    #Set the mask output folder in the macro too
    file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                            ,"Mask_axonmemb_", list1[i], "_",list2[j], "_v1.tif"))
  }
}


#Change the tifs to nrrds


#Now to perform the overlap analysis.Code modified from mask_overlap_calulation.R 
setwd("/Volumes/Samsung_T3/LH_segmentations/macro_input/") #Ran the analysis off harddrive. 

#Function for calculating the percentage overlap between two masks. 
#Does not use actual n, rather divides score by 255. 
mask.overlap<-function (mask1, mask2) {
  olp<-cmtk.statistics(f = mask1, mask=mask2)
  total.overlap<-(olp[2,8])/255
  n<-(olp[1,8]/255)+(olp[2,8]/255)
  return ((total.overlap/n)*100)
}
pairwise.overlap<-function(mask1, target) {
  pairwise<-vector()
  for(i in 1:length(target)){
    pairwise<-c(pairwise,
                mean(c(mask.overlap(mask1=mask1, mask2=target[i])
                       ,mask.overlap(mask1=target[i], mask2=mask1))))
    print(mask1)
    pairwise[is.infinite(pairwise)]<-100 #Turn all the mask1:mask1 overlap comparisions to 100
  }
  pairwise
}
extract.clust<-function(x=character()) {
  split<-strsplit(x, "_", fixed = TRUE)
  clusters<-sapply(split, "[", 4)
  clusters<-paste0("CellType_", clusters)
  clusters
}

files<-list.files(pattern = "*.nrrd")
query<-c(grep(x = files,pattern = "Input", value=TRUE), grep(x = files,pattern = "TastePN", value=TRUE), grep(x = files,pattern = "TempPN", value=TRUE))
query<-grep(x = query, pattern = "axonmemb", value=TRUE)

target<-grep(x = files,pattern = "Output", value=TRUE)
target<-grep(x=target, pattern="den" , value=TRUE)

print(target);print(query) #Test to make sure it works
title<-paste0("Output_den_x_LHIN_axonmemb")
results<-matrix(nrow = length(query),ncol=length(target)
                ,dimnames = list(extract.clust(query)
                                 ,extract.clust(target)))
for (j in 1:length(query)) {
  results[j,]<-pairwise.overlap(mask1=query[j], target = target)
}
write.table(x  = results, file = paste0(title, ".txt"))
aheatmap(results, filename=paste0(title, ".pdf")) #save to get proper proportions



readin<-function(file) {
  as.matrix(read.table(file, header=TRUE,row.names=1))
}