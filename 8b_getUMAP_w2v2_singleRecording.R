library(umap)
library(viridis)
library(dplyr)
library(ggplot2)
library(tuneR)
library(av)

setwd("~/Documents/GitHub/IVFCR-UMAP")
inputDir <- "w2v2embeddings/"
umapDir <- "umap_data/"

if (!dir.exists(umapDir)){
  dir.create(umapDir)
}

for (l in 1:12){
  
  f <- paste("196_272_w2v2_layer",l,".csv",sep="")
  baby <- "196"
  #f <- paste("344_283_w2v2_layer",l,".csv",sep="")
  # baby = "344"
  
  emb_data <- read.csv(paste(inputDir,f,sep=""))
  random_order <- sample(nrow(emb_data))
  emb_data <- emb_data[random_order,]
  emb_data_scaled <- emb_data %>%
    mutate(across(where(is.numeric),scale)) # normalize each embedding dimension
  
  write.csv(emb_data_scaled,file=paste(inputDir,"196_272_w2v2_randorder_scaled.csv",sep=""),row.names = FALSE)
  
  emb_umap <- umap(emb_data_scaled[,2:ncol(emb_data_scaled)])
  
  emb_pca <- prcomp(emb_data_scaled[,2:ncol(emb_data_scaled)])
  
  start_times <- sub("^(?:[^_]*_){2}([0-9.]+).*","\\1",emb_data_scaled$filename)
  end_times <- sub("^(?:[^_]*_){3}([0-9.]+).wav","\\1",emb_data_scaled$filename)
  
  e_u_df <- data.frame(x=emb_umap_proj[,1],y=emb_umap$layout[,2],time=as.numeric(start_times),endtime=as.numeric(end_times),wavF=emb_data_scaled$filename)
  e_p_df <- data.frame(x=emb_pca$x[,1],y=emb_pca$x[,2],time=as.numeric(start_times),endtime=as.numeric(end_times),wavF=emb_data_scaled$filename)
  
  e_baseplot <- ggplot(e_u_df, aes(x,y,color=time)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "cividis") +
    theme_minimal()
  
  e_baseplot
  
  p_baseplot <- ggplot(e_p_df, aes(x,y,color=time)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "cividis") +
    theme_minimal()

  p_baseplot
  
  b_u_data <- e_u_df[order(e_u_df$time),]
  b_p_data <- e_p_df[order(e_u_df$time),]
  
  u_pngDir <- paste(umapDir,baby,"w2v2_layer",l,"_umap_pngs/",sep="")
  if (!dir.exists(u_pngDir)){
    dir.create(u_pngDir)
  }
  p_pngDir <- paste(umapDir,baby,"w2v2_layer",l,"_pca_pngs/",sep="")
  if (!dir.exists(p_pngDir)){
    dir.create(p_pngDir)
  }
  
  # create base plot (all points without a current vocalization focus)
  u_baseplot <- ggplot(b_u_data, aes(x,y,color=time)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "cividis") +
    theme_minimal()
  ggsave(paste(u_pngDir,"umap_baseplot.png",sep=""),width=5,height=4,dpi=300)
  # p_baseplot <- ggplot(b_p_data, aes(x,y,color=time)) +
  #   geom_point(size = 1, shape = 1) +
  #   scale_color_viridis_c(option = "cividis") +
  #   theme_minimal()
  # ggsave(paste(p_pngDir,"pca_baseplot.png",sep=""),width=5,height=4,dpi=300)
  
  # create the plots with a large dot on the current vocalization and save pngs
  for (i in 1:nrow(b_u_data)){
    u_i_plot <- u_baseplot +
      geom_point(data = b_u_data[i,], aes(x,y,color=time), size = 5, shape = 19)
    ggsave(paste(u_pngDir,"voc",i,"_u_plot.png",sep=""),width=5,height=4,dpi=300)
    # p_i_plot <- p_baseplot +
    #   geom_point(data = b_p_data[i,], aes(x,y,color=time), size = 5, shape = 19)
    # ggsave(paste(p_pngDir,"voc",i,"_p_plot.png",sep=""),width=5,height=4,dpi=300)
  }
  
  wavParentDir <- "cleaning_metadata/"
  
  fps <- 30
  prev_end <- b_u_data$time[1]
  all_frames <- c()
  all_audio <- list()
  
  for (i in 1:nrow(b_u_data)){
    
    # set the pause time before dot and audio should appear
    pause_sec <- b_u_data$time[i]-prev_end
    
    u_plot_file <- paste(u_pngDir,"voc",i,"_u_plot.png",sep="")
    
    # read in this voc's wav file
    iWavF <- b_u_data$wavF[i]
    rec <- sub("^((?:[^_]*_){2}).*","\\1",iWavF)
    iWavFP <- paste(wavParentDir,"best_clip_labels_",rec,"wavFiles/",iWavF,sep="")
    wav <- readWave(iWavFP)
    
    # create the silent pause on the baseplot image
    if (pause_sec>0){
      silent_seconds <- round(log10(pause_sec+1)*fps)/fps
      all_frames <- c(all_frames, rep(paste(u_pngDir,"umap_baseplot.png",sep=""), silent_seconds*fps))
      silent <- silence(duration = silent_seconds, xunit = "time", samp.rate = wav@samp.rate, bit = 16, pcm = TRUE)
      all_audio <- c(all_audio, silent) 
    }
    
    # get the number of frames the plot should show, based on the clip duration
    # and pad the audio with a little silence if needed to match the frame res
    audio_dur <- length(wav@left) / wav@samp.rate
    audio_frames <- audio_dur*fps
    n_frames <- ceiling(audio_frames)
    all_frames <- c(all_frames, rep(u_plot_file, n_frames))
    pad_dur <- (ceiling(audio_frames)-audio_frames)/fps
    if (pad_dur > 0){
      pad <- silence(duration = pad_dur, xunit = "time", samp.rate = wav@samp.rate, bit = 16, pcm = TRUE)
      all_audio <- c(all_audio, wav, pad)
    } else{
      all_audio <- c(all_audio, wav)
    }
    
    # set the previous end time to the end of the current vocalization, setting up for the next voc
    prev_end <- b_u_data$endtime[i]
  }
  
  combined_audio <- do.call(bind, all_audio)
  combined_audio_mono <- mono(combined_audio,"left")
  comb_aud_fp <- paste(umapDir,baby,"_w2v2_layer",l,"_umap.wav",sep="")
  writeWave(combined_audio_mono, comb_aud_fp)
  
  av_encode_video(
    input = all_frames,
    output = paste(umapDir,baby,"_w2v2_layer_",l,"umap.mp4",sep=""),
    framerate = fps,
    audio = comb_aud_fp
  )
  
}