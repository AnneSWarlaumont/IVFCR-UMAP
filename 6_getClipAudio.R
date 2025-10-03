# Based on each recording's best_clip_labels*.csv file, extract each clean
# CHN as an individual audio folder. Save in a folder with the same name as the
# csv file.

library(tuneR)
setWavPlayer("/usr/bin/afplay")

# The full recording audio files are not shared as part of this repository b/c
# they exceed GitHub's file size limits. They can be found in the San Joaquin
# Valley Public HomeBank Corpus https://doi.org/10.21415/43YW-XE49

SJV_dir <- "~/Library/CloudStorage/Box-Box/SanJoaquinValleyCorpus_Public/"
setwd("~/Documents/GitHub/IVFCR-UMAP/cleaning_metadata/")

clip_table_files <- list.files(pattern = "best_clip_labels*")
for (f in clip_table_files){
  
  clip_table <- read.csv(f)
  bigWavFile <- paste(SJV_dir,clip_table$recording[1],sep="")
  
  for (v in 1:nrow(clip_table)){
    startSec <- clip_table$startSecond[v]
    endSec <- clip_table$endSecond[v]
    clean <- clip_table$clean[v]
    if (clean){
      clipWav <- readWave(bigWavFile,from=startSec,to=endSec,units="seconds")
      #play(clipWav)
    }
  }
  
}

