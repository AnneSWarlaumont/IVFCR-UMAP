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
rownames(clips_data) <- NULL
babies <- levels(as.factor(clips_data$infant))

start_times <- sub("^(?:[^_]*_){2}([0-9.]+).*","\\1",clips_data$wavFile)
end_times <- sub("^(?:[^_]*_){3}([0-9.]+).wav","\\1",clips_data$wavFile)

baby <- babies[1] # Later can turn this into a for loop that goes through all the babies in the clean clips dataset
indices <- which(clips_data$infant==baby)
b_data <- data.frame(x=full_spectral_umap$layout[indices,1],y=full_spectral_umap$layout[indices,2],time=as.numeric(start_times[indices]),endtime=as.numeric(end_times[indices]),wavF=clips_data$wavFile[indices])
b_data <- b_data[order(b_data$time),]

pngDir <- paste(umapDir,baby,"_pngs/",sep="")
if (!dir.exists(pngDir)){
  dir.create(pngDir)
}

# create base plot (all points without a current vocalization focus)
baseplot <- ggplot(b_data, aes(x,y,color=time)) +
  geom_point(size = 1, shape = 1) +
  scale_color_viridis_c(option = "cividis") +
  theme_minimal()
ggsave(paste(pngDir,"baseplot.png",sep=""),width=5,height=4,dpi=300)

# create the plots with a large dot on the current vocalization and save pngs
for (i in 1:nrow(b_data)){
  i_plot <- baseplot +
    geom_point(data = b_data[i,], aes(x,y,color=time), size = 5, shape = 19)
  ggsave(paste(pngDir,"voc",i,"_plot.png",sep=""),width=5,height=4,dpi=300)
}

fps <- 30
prev_end <- b_data$time[1]
all_frames <- c()
all_audio <- list()

for (i in 1:nrow(b_data)){
  
  # set the pause time before dot and audio should appear
  pause_sec <- b_data$time[i]-prev_end
  
  plot_file <- paste(pngDir,"voc",i,"_plot.png",sep="")
  
  # read in this voc's wav file
  iWavF <- b_data$wavF[i]
  rec <- sub("^((?:[^_]*_){2}).*","\\1",iWavF)
  iWavFP <- paste(wavParentDir,"best_clip_labels_",rec,"wavFiles/",iWavF,sep="")
  wav <- readWave(iWavFP)
  
  # create the silent pause on the baseplot image
  if (pause_sec>0){
    silent_seconds <- round(log10(pause_sec+1)*fps)/fps
    all_frames <- c(all_frames, rep(paste(pngDir,"baseplot.png",sep=""), silent_seconds*fps))
    silent <- silence(duration = silent_seconds, xunit = "time", samp.rate = wav@samp.rate, bit = 16, pcm = TRUE)
    all_audio <- c(all_audio, silent) 
  }
  
  # get the number of frames the plot should show, based on the clip duration
  # and pad the audio with a little silence if needed to match the frame res
  audio_dur <- length(wav@left) / wav@samp.rate
  audio_frames <- audio_dur*fps
  n_frames <- ceiling(audio_frames)
  all_frames <- c(all_frames, rep(plot_file, n_frames))
  pad_dur <- (ceiling(audio_frames)-audio_frames)/fps
  if (pad_dur > 0){
    pad <- silence(duration = pad_dur, xunit = "time", samp.rate = wav@samp.rate, bit = 16, pcm = TRUE)
    all_audio <- c(all_audio, wav, pad)
  } else{
    all_audio <- c(all_audio, wav)
  }
  
  # set the previous end time to the end of the current vocalization, setting up for the next voc
  prev_end <- b_data$endtime[i]
}

combined_audio <- do.call(bind, all_audio)
combined_audio_mono <- mono(combined_audio,"left")
comb_aud_fp <- paste(umapDir,baby,".wav",sep="")
writeWave(combined_audio_mono, comb_aud_fp)

av_encode_video(
  input = all_frames,
  output = paste(umapDir,baby,".mp4",sep=""),
  framerate = fps,
  audio = comb_aud_fp
)
