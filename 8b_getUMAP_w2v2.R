library(umap)
library(viridis)
library(dplyr)

setwd("~/Documents/GitHub/IVFCR-UMAP")
inputDir <- "w2v2embeddings/"
umapDir <- "umap_data/"

if (!dir.exists(umapDir)){
  dir.create(umapDir)
}

f <- "196_272_w2v2.csv"

emb_data <- read.csv(paste(inputDir,f,sep=""))
random_order <- sample(nrow(emb_data))
emb_data <- emb_data[random_order,]
emb_data_scaled <- emb_data %>%
  mutate(across(where(is.numeric),scale)) # normalize each embedding dimension

write.csv(emb_data_scaled,file=paste(inputDir,"196_272_w2v2_randorder_scaled.csv",sep=""),row.names = FALSE)

emb_umap <- umap(emb_data_scaled[,2:ncol(emb_data_scaled)])
saveRDS(emb_umap,file=paste(umapDir,"emb_umap.rds",sep=""),ascii = TRUE)

start_times <- sub("^(?:[^_]*_){2}([0-9.]+).*","\\1",emb_data_scaled$filename)
end_times <- sub("^(?:[^_]*_){3}([0-9.]+).wav","\\1",emb_data_scaled$filename)

e_u_df <- data.frame(x=emb_umap$layout[,1],y=emb_umap$layout[,2],time=as.numeric(start_times),endtime=as.numeric(end_times),wavF=emb_data_scaled$filename)

baseplot <- ggplot(e_u_df, aes(x,y,color=time)) +
  geom_point(size = 1, shape = 1) +
  scale_color_viridis_c(option = "cividis") +
  theme_minimal()

baseplot

b_data <- e_u_df[order(e_u_df$time),]
baby = "196"
pngDir <- paste(umapDir,baby,"w2v2_pngs/",sep="")
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

wavParentDir <- "cleaning_metadata/"

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
comb_aud_fp <- paste(umapDir,baby,"_w2v2.wav",sep="")
writeWave(combined_audio_mono, comb_aud_fp)

av_encode_video(
  input = all_frames,
  output = paste(umapDir,baby,"_w2v2.mp4",sep=""),
  framerate = fps,
  audio = comb_aud_fp
)
