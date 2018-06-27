//This is code to make masks of each of the brain regions in order 
//to make a heatmap of the output axons and the different brain regions. 

arg = getArgument;
open(arg);

//Run a very liberal autothreshold algorithm 
run("Auto Threshold", "method=Li white stack");

//Save as a tif, change directory as required.
saveAs("Tiff","/Volumes/Samsung_T3/DPX_Standard2013/Mask20131111/nc82_mask/mask");

//Shut down imageJ
run("Quit");

