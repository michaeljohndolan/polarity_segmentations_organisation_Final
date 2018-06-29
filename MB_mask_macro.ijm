//For creating a mask of  dendrites or axons of registered LHNs from the segmentations

//Some code for interperting multiple pasted arguments
arg = getArgument;
delimiter = "*";
paths=split(arg, delimiter);

if(lengthOf(paths)==1) {
	run("Quit");
}

if(lengthOf(paths)==2) {
	num=2;
}
if(lengthOf(paths)>=3) {
	num=3;
}

//Open the files 
for (i=0; i<num; i++) {
open(paths[i]);
}
//rename the files
names= getList("image.titles");
for (i=0;i<names.length;i++) {
			selectWindow(names[i]);
			rename(i);
}
if(num==2) {
	//Add the stacks using image calculator, currently only analyses three. Need to fix up
	imageCalculator("Add create stack", "0","1");
	selectWindow("Result of 0");
	rename("myimage");
}
if (num==3) {
	//Add the stacks using image calculator, currently only analyses three. Need to fix up
	imageCalculator("Add create stack", "0","1");
	imageCalculator("Add create stack", "Result of 0","2");
	selectWindow("Result of 0");
	close();
	selectWindow("Result of Result of 0");
	rename("myimage");
}

//Enhance the contrast, blur and make a mask
selectWindow("myimage");
run("Enhance Contrast...", "saturated=0.3 equalize process_all");
run("Gaussian Blur...", "sigma=1 stack");
setAutoThreshold("Otsu dark");
setOption("BlackBackground", false);
run("Convert to Mask", "method=Otsu background=Dark calculate black");

//Save as a tif, change directory as required.
saveAs("Tiff","/Volumes/Samsung_T3/Split_Channel_Images/macro_input/mask.tif");

//Shut down imageJ
run("Quit");
