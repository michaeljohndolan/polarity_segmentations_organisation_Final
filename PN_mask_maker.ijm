
dir= getDirectory("Choose Directory");
print(dir);
files=getFileList(dir);
for (i=0; i<files.length; i++) {
	open(files[i]);
	
	//Initial processing to convert traced data from R
	run("32-bit");
	run("Gaussian Blur 3D...", "x=1 y=1 z=1");
	resetMinAndMax();
	run("8-bit"); 
	run("Convert to Mask", "method=Default background=Dark calculate black");
	rename("1");
	
	//Duplicate and flip 
	run("Duplicate...", "duplicate");
	selectWindow("1-1");
	rename("2");
	run("Flip Horizontally", "stack");
	
	//Add the two images together 
	imageCalculator("Add create stack", "1","2");

	//close others
	selectWindow("1"); close();
	selectWindow("2"); close();

	//Remove the scale
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

	//Open the LH mask and perform the cropping to remove non-LH parts of the neuron
	open("/Users/michaeljohndolan/projects/polarity_segmentations_organisation_Final/Mask_nc82_LH.nrrd");
	imageCalculator("AND create stack", "Result of 1","Mask_nc82_LH.nrrd");
	close("Mask_nc82_LH.nrrd");
	close("Result of 1");
	selectWindow("Result of Result of 1");
	
	//Save
	setKeyDown("alt");
	run("Nrrd ... ", "nrrd=["+ dir + "Mask_" + files[i] + "]");
	setKeyDown("none");
	close();
}

