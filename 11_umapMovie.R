library(ggplot2)
library(viridis)
library(tuneR)
library(av)

setwd("~/Documents/GitHub/IVFCR-UMAP")
specFeatDir <- "best_clips_spectral_features/"
umapDir <- "umap_data/"
wavParentDir <- "cleaning_metadata/"

full_spectral_umap <- readRDS(paste(umapDir,"full_spectral_umap.rds",sep=""))
clips_data <- read.csv(paste(specFeatDir,"all_best_clips_babies_ages_and_spectral_data.csv",sep=""))
clips_data <- clips_data[-c(1,2),]
babies <- levels(as.factor(clips_data$infant))

start_times <- sub("^(?:[^_]*_){2}([0-9.]+).*","\\1",clips_data$wavFile)

baby <- babies[1] # Later can turn this into a for loop that goes through all the babies in the clean clips dataset
indices <- which(clips_data$infant==baby)
b_data <- data.frame(x=full_spectral_umap$layout[indices,1],y=full_spectral_umap$layout[indices,2],time=as.numeric(start_times[indices]),wavF=clips_data$wavFile[indices])
new_order <- order(b_data$time)
b_data <- b_data[order(b_data$time),]

pngDir <- paste(umapDir,baby,"_pngs/")
if (!dir.exists(pngDir)){
  dir.create(pngDir)
}

for (i in 1:nrow(b_data)){
  iWavF <- b_data$wavF[i]
  rec <- sub("^((?:[^_]*_){2}).*","\\1",iWavF)
  iWavFP <- paste(wavParentDir,"best_clip_labels_",rec,"wavFiles/",iWavF,sep="")
  wav <- readWave(iWavFP)
  audio_dur <- length(wav@left) / wav@samp.rate
  ggplot(b_data, aes(x,y,color=time)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "cividis") +
    theme_minimal() +
    geom_point(data = b_data[i,], aes(x,y,color=time), size = 5, shape = 19)
}