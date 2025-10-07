# Get MFCCs, deltas, and delta deltas for each clip's wav file
# Store in one table for each clip_labels csv?

library(tuneR)
setwd("~/Documents/GitHub/IVFCR-UMAP/cleaning_metadata/")

wavDirs <- list.files(pattern = "*wavFiles")
for (wavDir in wavDirs){
  wavFiles <- list.files(path = paste(wavDir), pattern = "*.wav")
}