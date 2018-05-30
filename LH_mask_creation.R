#R code used with the ImageJ macro to create the masks for further analysis.
#ImageJ can only take one argument so use * as a delimiter.
#This code requires the following directory structure
#Call imagej with java -Xmx1024m -jar /Applications/ImageJ/ImageJ.app/Contents/Java/ij.jar 
# -ijpath /Applications/ImageJ
# had to change the path, see http://rsb.info.nih.gov/ij/docs/install/osx.html#cli 
# and http://forum.imagej.net/t/running-plugins-macros-from-the-command-line/363/3
# Then had trouble saving as either compressed tifs or nrrds. Batch convert input to nrrds. 


maindir<-"/Volumes/Samsung_T3/LH_segmentations/Seg_organized/"
abovedir<-"/Volumes/Samsung_T3/LH_segmentations/"
setwd(abovedir)
dir.create("macro_input")
inputdir<-"/Volumes/Samsung_T3/LH_segmentations/macro_input/mask.tif"
#Set the command to call ImageJ and the marco. Be sure to include a space at the end! 
command<-"java -Xmx5024m -jar /Applications/ImageJ/ImageJ.app/Contents/Java/ij.jar -ijpath /Applications/ImageJ -macro /GD/LMBD/projects/polarity_segmentations_organisation_Final/LH_mask_macro.ijm "
setwd(maindir)

list1<-list.files() #Lists three different catagories 
for (i in 1:length(list1)) {
  if(list1[i]=="NotLH") next
  if(list1[i]=="NA") next
  list2<-list.files(path = paste0("./", list1[i]))
  for (j in 1:length(list2)) {
        #List the different tiffs in each cell-type within a catagory
        tiffs<-list.files(path =paste0("./", list1[i], "/", list2[j]), pattern = "*.tif", recursive = TRUE)
        #If the cell-type doesn't have any segmentations skip
        if(length(grep(pattern = "seg", x = tiffs, fixed = TRUE, value=TRUE))==0) next
        
        #Whole membrane segmentation
        tiffs.whole<-grep(pattern = "seg_whole",x = tiffs, value = TRUE, fixed = TRUE )
        tiffs.whole<-file.path(maindir, list1[i], list2[j], tiffs.whole)
        tiffs.whole<-paste(tiffs.whole, collapse = "*") #Concatenate into one argument for the ImageJ macro call
        system(paste0(command,tiffs.whole))
        #Set the mask output folder in the macro too
        file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                                ,"Mask_whole_", list1[i], "_",list2[j], "_v1.tif"))
        if(list1[i]=="Local") {
          #memb segmentation for local
          tiffs.memb<-grep(pattern = "seg_memb",x = tiffs, value = TRUE, fixed = TRUE )
          tiffs.memb<-file.path(maindir, list1[i], list2[j], tiffs.memb)
          tiffs.memb<-paste(tiffs.memb, collapse = "*") #Concatenate into one argument for the ImageJ macro call
          system(paste0(command,tiffs.memb))
          #Set the mask output folder in the macro too
          file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                                  ,"Mask_memb_", list1[i], "_",list2[j], "_v1.tif"))
          next #As local neurons do not have defined input and output regions 
        }
        
        #Axon membrane segmentation
        tiffs.axonmemb<-grep(pattern = "seg_axonmemb",x = tiffs, value = TRUE, fixed = TRUE )
        tiffs.axonmemb<-file.path(maindir, list1[i], list2[j], tiffs.axonmemb)
        tiffs.axonmemb<-paste(tiffs.axonmemb, collapse = "*") #Concatenate into one argument for the ImageJ macro call
        system(paste0(command,tiffs.axonmemb))
        #Set the mask output folder in the macro too
        file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                                ,"Mask_axonmemb_", list1[i], "_",list2[j], "_v1.tif"))
        
        #Dendrite segmentation mask creation
        tiffs.den<-grep(pattern = "seg_den",x = tiffs, value = TRUE, fixed = TRUE )
        
        tiffs.den<-file.path(maindir, list1[i], list2[j], tiffs.den)
        tiffs.den<-paste(tiffs.den, collapse = "*") #Concatenate into one argument for the ImageJ macro call
        system(paste0(command,tiffs.den))
        #Set the mask output folder in the macro too
        file.rename(from = inputdir,to = paste0("/Volumes/Samsung_T3/LH_segmentations/macro_input/"
                                                ,"Mask_den_", list1[i], "_",list2[j], "_v1.tif"))
  }
}  

#Now run the BatchConvertAnyToNrrd.txt macro from the jefferis lab 

stop()
#Delete the remaining tifs in the macro input directory 
file.remove(list.files(path="/Volumes/LaCie/Split_Channel_Images/macro_input/"
                      ,full.names=TRUE, pattern = "*.tif"))
      
    
   