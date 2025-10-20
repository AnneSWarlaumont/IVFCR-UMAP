# Get the LENA segment onsets and offsets for all labels as well as separately
# for CHNSP, CHNNSP, FAN, and MAN. Put in CSV files analogous to the
# best_clip_labels*.csv files in the cleaning_metadata folder

setwd("~/Documents/GitHub/IVFCR-UMAP/")

itsDir <- "~/Library/CloudStorage/Box-Box/IVFCR\ Study/LENAExports_Renamed/"
itsFiles <- list.files(itsDir, pattern = "*.its", recursive = TRUE)
outputDir <- "ivfcr_clips/"

if (!dir.exists(outputDir)){
  dir.create(outputDir)
}

for (i in itsFiles){
  iFile <- paste(itsDir,i,sep="")
  outFile <- paste(outputDir,"/",gsub(".*/|\\.its","",i),"_segments.csv",sep="")
  system2("perl",args = c("segments.pl",shQuote(path.expand(iFile)),outFile))
}

