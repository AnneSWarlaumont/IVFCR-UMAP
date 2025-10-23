# Based on each recording's *segments.csv file, extract each CHNSP, CHNNSP, FAN,
# and MAN as an individual wav file. Save in a folder per type per recording.
# Note that this will run a lot faster from the Terminal vs. RStudio; loading
# the big wav file using tuneR is very slow in RStudio for some reason.

library(tuneR)
setWavPlayer("/usr/bin/afplay")

daylongWavDir <- "~/Library/CloudStorage/Box-Box/IVFCR\ Study/LENAExports_Renamed/"
setwd("~/Documents/GitHub/IVFCR-UMAP/ivfcr_clips/")

segments_files <- list.files(pattern = "*segments.csv")

for (f in segments_files[1:length(segments_files)]){
  
  segments <- read.csv(f)
  fPrefix <- gsub("_segments.csv","",f)
  
  if (length(grep("0747_ExtraRecordings",f))==0){
    participantFolder <- paste(gsub("_.*","",fPrefix),"/",sep="")
  } else{
    participantFolder <- "0747_ExtraRecordings/"
  }
  
  bigWavFile <- paste(daylongWavDir,participantFolder,fPrefix,".wav",sep="")
  
  segWavDir <- paste(fPrefix,"_segWavFiles/",sep="")
  
  if (!dir.exists(segWavDir)){
    dir.create(segWavDir)
  }
  
  for (s in 1:nrow(segments)){
    startSec <- segments$startsec[s]
    endSec <- segments$endsec[s]
    segType <- segments$segtype[s]
    clipWav <- readWave(bigWavFile,from=startSec,to=endSec,units="seconds")
    clipWavFile <- paste(segWavDir,paste(fPrefix,"_",startSec,"_",endSec,"_",segType,".wav",sep=""))
    writeWave(clipWav,clipWavFile,extensible = FALSE)
  }
  
}