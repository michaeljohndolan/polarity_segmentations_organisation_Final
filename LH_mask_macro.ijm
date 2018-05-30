//For creating a mask of  dendrites or axons of registered LHNs from the segmentations

//Some code for interperting multiple pasted arguments
arg = getArgument;
delimiter = "*";
paths=split(arg, delimiter);

//Open the files 
for (i=0; i<paths.length; i++) {
open(paths[i]);
}
names= getList("image.titles");
for (i=0;i<names.length;i++) {
			selectWindow(names[i]);
			rename(i);
}

//Add the stacks using image calculator, currently only analyses three. Need to fix up
imageCalculator("Add create stack", "0","1");
imageCalculator("Add create stack", "Result of 0","2");
selectWindow("Result of 0");
close();

//Enhance the contrast, blur and make a mask
selectWindow("Result of Result of 0");
run("Enhance Contrast...", "saturated=0.3 equalize process_all");
run("Gaussian Blur...", "sigma=1 stack");
setAutoThreshold("Otsu dark");
setOption("BlackBackground", false);
run("Convert to Mask", "method=Otsu background=Dark calculate black");

//Save as a tif, change directory as required.
saveAs("Tiff","/Volumes/Samsung_T3/LH_segmentations/macro_input/mask.tif");


//Shut down imageJ
run("Quit");
