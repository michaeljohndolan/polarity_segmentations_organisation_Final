#Code to organize all the segmentations in a more efficient manner compared to the older polarity_segmentations_organisation code. 
#This uses outputs from filemaker which were manually edited to change multiple cell-type lines to the cell-type segmented. 

#Load required libraries and paths
library(xlsx)
library(dplyr)
library(here)
seg_path<-("/Volumes/Data/LH_segmentations")
NAmaster_path<-("/Users/dolanm/Dropbox/JFRCvisitorProject/Neuroanatomy_Master.xlsx")

#Preprocess and merge NAmaster with the Polarity and Case4 filemaker db outputs
setwd("~/projects/polarity_segmentations_organisation_Final")
NA_master<-read.xlsx2(file = NAmaster_path, sheetIndex = 1)
NA_master<-filter(NA_master, PolarityDataAvailable.green.means.segmentation.done.=="Yes")
NA_master<-select(NA_master, LHClusters., FinalNames, Polarity, Neurotransmitter)
Case4<-read.xlsx(file = "Case4_Segment.xlsx", sheetIndex = 1)
Polarity<-read.xlsx(file = "Polarity_Segment.xlsx", sheetIndex = 1)

#Remove extra characters from the cell-type names
NA_master$LHClusters.<-gsub(x = NA_master$LHClusters., pattern = "\n", replacement = "", fixed = TRUE)
Case4$Splitlines_cluster..Cluster<-gsub(x = Case4$Splitlines_cluster..Cluster, pattern = "\n", replacement = "", fixed = TRUE)
Polarity$Splitlines_cluster..Cluster<-gsub(x = Polarity$Splitlines_cluster..Cluster, pattern = "\n", replacement = "", fixed = TRUE)

#Merge the Case4 and Polarity data frames with my NAmaster
merge1<-merge(x = Case4,by.x = "Splitlines_cluster..Cluster", y = NA_master, by.y = "LHClusters.",all.x = TRUE, all.y=FALSE)
names(merge1)<-c("celltype", "ImageID", "LineCode", "Segment", "FinalNames", "Polarity", "Neurotransmitter")
merge2<-merge(x = Polarity,by.x = "Splitlines_cluster..Cluster", y = NA_master, by.y = "LHClusters.",all.x = TRUE, all.y=FALSE)
merge2<-select(merge2, Splitlines_cluster..Cluster, PolarityImageCode, LineCode, Segmentable, FinalNames,Polarity, Neurotransmitter )
names(merge2)<-c("celltype", "ImageID", "LineCode", "Segment", "FinalNames", "Polarity", "Neurotransmitter")

ImagesToClusters<-rbind(merge1, merge2)


#Pull all the segmentations from the older directory structure and place in the new storage directory. This will be where we can modify individual 
#segmentations and then rerun the organization code futher below to regenerate the polarity/cell-type directory structure. 
setwd(seg_path)
dir.create(path = "Seg_organized")
all_segs<-list.files(pattern = "seg", recursive = TRUE)
file.copy(all_segs, ".")
all_segs<-list.files(pattern = "seg", recursive = FALSE)

#Need to standardize these filenames to make the organization easy  
#How many different file varients are there? 
x<-all_segs
y<-grep(pattern = "*~63x_Aligned63xScale_c*", x = all_segs, value = TRUE)
z<-grep(pattern = "*-Aligned63xScale_c*", x = all_segs, value = TRUE)
m<-union(y,z)
length(x)==length(m) #Confirm that these are the only two patterns
all_segs_63fix<-gsub(all_segs, pattern = "-Aligned63xScale_c", replacement = "~63x_Aligned63xScale_c")
file.rename(all_segs, to = all_segs_63fix)
all_segs<-list.files(pattern = "seg", recursive = FALSE)

#Using ImagesToClusters df, recreate the segmentation directory structure
sapply(X = file.path(unique(ImagesToClusters$Polarity)), dir.create)

for(i in 1:length(all_segs)) {
  seg<-all_segs[i]
  ID<-sapply(strsplit(seg, "~"), "[", 1)
  ID<-gsub(pattern = "seg_whole_", replacement = "", x = ID)
  ID<-gsub(pattern = "seg_axonmemb_", replacement = "", x = ID)
  ID<-gsub(pattern = "seg_axon_", replacement = "", x = ID)
  ID<-gsub(pattern = "seg_memb_", replacement = "", x = ID)
  ID<-gsub(pattern = "seg_den_", replacement = "", x = ID)
  
  line<-filter(ImagesToClusters, grepl(pattern = ID, ImageID)) #Match the segmentation image with the original ImageID
  if(length(line[,1])==0) next #Leaves the problematic images in the main directory. Note this is likely some issue with annotations
  
  celltype<-as.character(line[,1]) 
  ImageID<-as.character(line[,2])
  LineCode<-as.character(line[,3])
  Pol<-as.character(line[,6])
  
  Clustdir<-file.path(Pol, celltype)
  if(file.exists(Clustdir)) {
    print("No new celltype directory made")
  } else dir.create(Clustdir)
  
  ImIDDir<- file.path(Clustdir,ImageID)
  if(file.exists(ImIDDir)) {
    print("No new ImID directory made")
  } else dir.create(ImIDDir)
  
  file.rename(from= seg , to= file.path(ImIDDir, seg))
  print(i)
}
