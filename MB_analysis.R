#Code to parse out and rename the MBONs and DANs. Then merge them into my pipeline.
# similar to LH_mask_creation.R
# Note that Yoshi has organised all his MB data manually. In directory called MB_segmentations 
# What happens to lines where is >3 images? Is the mask still made? 

library(xlsx)
library(dplyr)
source("http://bioconductor.org/biocLite.R")
biocLite()
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
setwd("./MB_segmentations/")
curdir<-getwd()
command<-"java -Xmx5024m -jar /Applications/ImageJ/ImageJ.app/Contents/Java/ij.jar -ijpath /Applications/ImageJ -macro /Users/michaeljohndolan/projects/polarity_segmentations_organisation_Final/MB_mask_macro.ijm "

#Need to rename the cell types to replace commas which is breaking the script
all.filesDAN<-list.files(path = "DAN/", recursive = FALSE)
new.namesDAN<-gsub(pattern = "'", replacement = "prime",x = all.filesDAN,fixed = TRUE)
file.rename(from = paste0("DAN/", all.filesDAN),to =  paste0("DAN/", new.namesDAN) )
all.filesMBON<-list.files(path = "MBON/", recursive = FALSE)
new.namesMBON<-gsub(pattern = "'", replacement = "prime",x = all.filesMBON,fixed = TRUE)
file.rename(from = paste0("MBON/", all.filesMBON),to =  paste0("MBON/", new.namesMBON) )

list1<-list.files() #Lists two different catagories 
for (i in 1:length(list1)) {
        list2<-list.files(path = paste0("./", list1[i]))
        for (j in 1:length(list2)) {
                #List the different tiffs in each cell-type within a catagory
                tiffs<-list.files(path =paste0("./", list1[i], "/", list2[j]), pattern = "*.tif", recursive = TRUE)

                #Dendrite segmentation mask creation
                tiffs.den<-grep(pattern = "den",x = tiffs, value = TRUE, fixed = TRUE )
                tiffs.den<-paste0(maindir, "MB_segmentations/", list1[i], "/", list2[j], "/", tiffs.den)
                tiffs.den<-paste(tiffs.den, collapse = "*") #Concatenate into one argument for the ImageJ macro call
                system(paste0(command,tiffs.den))
                #Set the mask output folder in the macro too
                file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                                        ,"Mask_den_", list1[i], "_",list2[j], "_v1.tif"))
                
                #axon segmentation mask creation
                tiffs.axon<-grep(pattern = "axon",x = tiffs, value = TRUE, fixed = TRUE )
                tiffs.axon<-paste0(maindir, "MB_segmentations/", list1[i], "/", list2[j], "/", tiffs.axon)
                tiffs.axon<-paste(tiffs.axon, collapse = "*") #Concatenate into one argument for the ImageJ macro call
                system(paste0(command,tiffs.axon))
                #Set the mask output folder in the macro too
                file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                                        ,"Mask_axon_", list1[i], "_",list2[j], "_v1.tif"))
        }
}
                
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
catagory.overlap<-function (query_type, target_type, query_catagory, target_catagory) {
  files<-list.files(pattern = "*.nrrd")
  query<-grep(x = files,pattern = query_catagory, value=TRUE)
  query<-grep(x=query, pattern = query_type, value=TRUE)
  target<-grep(x = files,pattern = target_catagory, value=TRUE)
  target<-grep(x=target, pattern=target_type, value=TRUE)
  print(target);print(query) #Test to make sure it works
  title<-paste0(query_type,"_", query_catagory,"_x_", target_type, "_", target_catagory)
  results<-matrix(nrow = length(query),ncol=length(target)
                  ,dimnames = list(extract.clust(query)
                                   ,extract.clust(target)))
  for (j in 1:length(query)) {
    results[j,]<-pairwise.overlap(mask1=query[j], target = target)
  }
  write.table(x  = results, file = paste0(title, ".txt"))
  aheatmap(results, filename=paste0(title, ".pdf")) #save to get proper proportions
}
readin<-function(file) {
  as.matrix(read.table(file, header=TRUE,row.names=1))
}

#Now run the analysis on the different MBNs versus the LHONs
# MBON axons and LHON axons 
catagory.overlap(query_type = "Output", target_type = "MBON", 
                 query_catagory = "axonmemb", target_catagory = "axon")
#DAN dendrites and LHON axons 
catagory.overlap(query_type = "Output", target_type = "DAN", 
                 query_catagory = "axonmemb", target_catagory = "den")

# MBON axons and LHON dendrites 
catagory.overlap(query_type = "Output", target_type = "MBON", 
                 query_catagory = "den", target_catagory = "axon")

#MBON outputs and LHN local neurons
catagory.overlap(query_type = "Local", target_type = "MBON", 
                 query_catagory = "memb", target_catagory = "axon")



#Simple code to concatenate the MBN data 
DANs<-readin("Output_axonmemb_x_DAN_den.txt")
MBONs<-readin("Output_axonmemb_x_MBON_axon.txt")
All<-cbind(DANs, MBONs) #LHONs versus DANs and MBONs
















