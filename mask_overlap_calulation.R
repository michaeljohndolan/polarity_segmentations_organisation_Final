#Initial code for analysing overlap of LH segmentation masks to produce heatmaps.
#There are separate code chunks for analysis of PNs and MBONs/DANs
#Assumes you ran the LH_mask_creation.R code and named the masks as described.
#Convert all the tifs to nrrds, required for nat's CMTK statistics command. 

#Note this requires CMTK and you'll need to set the path, which you can do manually: 
# options(nat.cmtk.bindir="/Users/dolanm/opt/local/bin")

source("http://bioconductor.org/biocLite.R")
biocLite()
biocLite("made4")
library(nat)
library(ggplot2)
library(made4)
library(xlsx)
library(NMF)                # aheatmap()

setwd("/Volumes/Samsung_T3/LH_segmentations/macro_input/")

#Clear up any tif files and find all the nrrds
file.remove(list.files(pattern = "*.tif"))
all.nrrds<-list.files(pattern = "*.nrrd")

#Function for calculating the percentage overlap between two masks. 
#Does not use actual n, rather divides score by 255. 
mask.overlap<-function (mask1, mask2) {
  olp<-cmtk.statistics(f = mask1, mask=mask2)
  total.overlap<-(olp[2,8])/255
  n<-(olp[1,8]/255)+(olp[2,8]/255)
  return ((total.overlap/n)*100)
}
#Function to calculate the overlap between a mask and all target masks.
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
#Function to run all the comparisions for query catagory. Note query/target catagory takes
# or c("axonmemb", "den", "whole").Query/target type refers to input, output or local.
#Saves a spreadsheet and a heatmap.
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

#To read in a result matrix properly and analyse in more detail
readin<-function(file) {
as.matrix(read.table(file, header=TRUE,row.names=1))
} 

#Code to import the neurotransmitter assignments for making figures. 
NT_annotations.chat.vglut<-read.xlsx("/Users/dolanm/Dropbox/JFRCvisitorProject/Neurotransmitter_Staining/NT_annotations.xlsx", sheetIndex=1)
NT_annotations.GABA<-read.xlsx("/Users/dolanm/Dropbox/JFRCvisitorProject/Neurotransmitter_Staining/NT_annotations.xlsx", sheetIndex=2)

NT_annotations.chat.vglut<-select(NT_annotations.chat.vglut, Chat_positive, Vglut_positive, Cell.Type)
NT_annotations.GABA<-select(NT_annotations.GABA, GABA_positive, Cell.Type)
NT_annotations<-merge(NT_annotations.GABA, NT_annotations.chat.vglut, by="Cell.Type")
NT_annotations$result<-"Unknown"
NT_annotations$Cell.Type<-paste0("CellType_", NT_annotations$Cell.Type) #To match CellType names 
#Need to merge into unique entries 
NT_annotations<-select(NT_annotations, Cell.Type, result)
NT_annotations<-unique(NT_annotations)
table(NT_annotations$Cell.Type) #check for duplicates/inconsistant cell-types

for(i in 1:nrow(NT_annotations)) {
  Line<-NT_annotations[i,]
  if(Line$GABA_positive=="Yes") NT_annotations$result[i]<-"GABA"
  if(Line$Chat_positive=="Yes") NT_annotations$result[i]<-"ChAT"
  if(Line$Vglut_positive=="Yes") NT_annotations$result[i]<-"Glutamate"
  if(Line$GABA_positive=="Yes" & Line$Vglut_positive=="Yes") NT_annotations$result[i]<-"GABA and Glutamate"
  if(Line$GABA_positive=="Yes" & Line$Chat_positive=="Yes") NT_annotations$result[i]<-"GABA and ChAT"
  if(Line$Chat_positive=="Yes" & Line$Vglut_positive=="Yes") NT_annotations$result[i]<-"ChAT and Glutamate"
  if(Line$Chat_positive=="Yes" & Line$Vglut_positive=="Yes" & Line$GABA_positive=="Yes") {
    NT_annotations$result[i]<-"ChAT, Glutamate and GABA"
  }
}

#Inital run on a small number of cell-types to trial the analysis code.
catagory.overlap(query_type = "Input", target_type = "Input", 
                 query_catagory = "axonmemb", target_catagory = "axonmemb")

#Read back in the data
data<-readin(file="Input_axonmemb_x_Input_axonmemb.txt")

#Now run the different analyses
catagory.overlap(query_type = "Output", target_type = "Output", 
                 query_catagory = "axonmemb", target_catagory = "axonmemb")

catagory.overlap(query_type = "Output", target_type = "Output", 
                 query_catagory = "den", target_catagory = "den")

catagory.overlap(query_type = "Input", target_type = "Output", 
                 query_catagory = "axonmemb", target_catagory = "den")

catagory.overlap(query_type = "Local", target_type = "Output", 
                 query_catagory = "memb", target_catagory = "den")

catagory.overlap(query_type = "Local", target_type = "Input", 
                 query_catagory = "memb", target_catagory = "axonmemb")

catagory.overlap(query_type = "Output", target_type = "Input", 
                 query_catagory = "axonmemb", target_catagory = "den")

#Now replicate the heatmaps with NT information 
data<-readin(file="Output_axonmemb_x_Output_axonmemb.txt")
col<-data.frame(Cell.Type=colnames(data))
NT_LHN<-left_join(x=col, NT_annotations, by="Cell.Type") #Match but maintain order 
NTs.col<-list(Neurotransmitter=NT_LHN$result)
aheatmap(data, annCol=NTs.col, annColors="terrain", filename="test.pdf")






