#Code to parallelize the mask overlap analysis 
library(nat)
library(ggplot2)
library(made4)
library(xlsx)
library(NMF)                # aheatmap()
library(foreach)
library(doParallel)
library(doMC)
registerDoMC(cores=7)

setwd("/Volumes/Samsung_T3/Split_Channel_Images/macro_input/")

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
        #Get the pariwiseoverlap function to set the rname and colname 
        results<-foreach(j=1:length(query), .combine="cbind") %dopar% pairwise.overlap(mask1=query[j], target = target)
        dimnames(results)<-list(extract.clust(query),extract.clust(target))
        write.table(x  = results, file = paste0(title, ".txt"))
        aheatmap(results, filename=paste0(title, ".pdf")) #save to get proper proportions
}

catagory.overlap(query_type = "Input", target_type = "Output", 
                 query_catagory = "axonmemb", target_catagory = "den")


