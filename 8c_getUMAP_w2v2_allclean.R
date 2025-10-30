library(umap)
library(viridis)
library(dplyr)

setwd("~/Documents/GitHub/IVFCR-UMAP")
inputDir <- "w2v2embeddings/"
umapDir <- "umap_data/"

if (!dir.exists(umapDir)){
  dir.create(umapDir)
}

# l <- 1 (for development purposes)
for (l in 1:12){
  
  lcsvpattern <- paste("layer",l,".csv",sep="")
  w2v2_emb_files <- list.files(path=inputDir,pattern=lcsvpattern)
  all_embeddings <- data.frame()
  full_wavFiles <- c()
  full_ages <- c()
  full_babies <- c()
  min_n_clips <- 1e10
  
  # f <- w2v2_emb_files[1] (for development purposes)
  for (f in w2v2_emb_files){
    emb_data <- read.csv(paste(inputDir,f,sep=""))
    if (nrow(emb_data) < min_n_clips){
      min_n_clips <- nrow(emb_data)
    }
    wavFiles <- emb_data$filename
    emb_data <- emb_data[,grep("dim",colnames(emb_data))]
    all_embeddings <- rbind(all_embeddings,emb_data)
    full_wavFiles <- c(full_wavFiles,wavFiles)
    age_days <- as.numeric(gsub("_.*","",gsub("^[^_]*_","",wavFiles)))
    age_months <- round(age_days/30)
    full_ages <- c(full_ages,age_months)
    babies <- regmatches(wavFiles,regexpr("^[^_]*",wavFiles))
    full_babies <- c(full_babies,babies)
    full_wavFiles <- c(full_wavFiles,wavFiles)
  }
  
  random_order <- sample(nrow(all_embeddings))
  all_embeddings <- all_embeddings[random_order,]
  all_embeddings <- scale(all_embeddings)
  full_babies <- full_babies[random_order]
  full_ages <- full_ages[random_order]
  full_wavFiles <- full_wavFiles[random_order]
  
  write.csv(all_embeddings,file=paste(inputDir,"all_embeddings_scaled.csv",sep=""),row.names = FALSE)
  
  emb_umap <- umap(all_embeddings)
  saveRDS(emb_umap,file=paste(umapDir,"emb_umap_w2v2layer",l,"_fullclean.rds",sep=""),ascii = TRUE)
  
  emb_pc <- prcomp(t(all_embeddings))
  emb_2pc_rot <- emb_pc$rotation[,1:2]
  
  start_times <- sub("^(?:[^_]*_){2}([0-9.]+).*","\\1",full_wavFiles)
  end_times <- sub("^(?:[^_]*_){3}([0-9.]+).wav","\\1",full_wavFiles)
  emb_umap_df <- data.frame(x=emb_umap$layout[,1],y=emb_umap$layout[,2],time=as.numeric(start_times),endtime=as.numeric(end_times),full_wavFiles,baby=full_babies,age=full_ages)
  emb_pca2_df <- data.frame(x=emb_2pc_rot[,1],y=emb_2pc_rot[,2],time=as.numeric(start_times),endtime=as.numeric(end_times),full_wavFiles,baby=full_babies,age=full_ages)
  
  baseplot <- ggplot(emb_umap_df, aes(x,y,color=age)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "viridis", begin = 3/18, direction=-1) +
    theme_minimal()
  baseplot
  
  baseplot <- ggplot(emb_pca2_df, aes(x,y,color=age)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "viridis", begin = 3/18, direction=-1) +
    theme_minimal()
  baseplot
  
  # HERE, trying to scale up this to operate over the whole "clean" dataset, like 8a
  
  # # Customize the UMAP to have higher n_neighbors and min_dist, so emphasizing
  # # global structure. Takes longer to run.
  # custom_config <- umap.defaults
  # custom_config$n_neighbors <- 100
  # custom_config$min_dist <- 0.5
  # emb_umap <- umap(emb_data_scaled[,2:ncol(emb_data_scaled)],config=custom_config)
  # saveRDS(emb_umap,file="emb_umap_global.rds",ascii = TRUE)
  
  b_data <- e_u_df[order(e_u_df$time),]
  baby = "196"
  #pngDir <- paste(umapDir,baby,"w2v2_pngs/",sep="")
  pngDir <- paste(umapDir,baby,"w2v2_layer",l,"_pca_pngs/",sep="")
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
  #comb_aud_fp <- paste(umapDir,baby,"_w2v2_global.wav",sep="")
  comb_aud_fp <- paste(umapDir,baby,"_w2v2_layer",l,"_pca.wav",sep="")
  writeWave(combined_audio_mono, comb_aud_fp)
  
  av_encode_video(
    input = all_frames,
    #output = paste(umapDir,baby,"_w2v2_global.mp4",sep=""),
    output = paste(umapDir,baby,"_w2v2_layer_",l,"pca.mp4",sep=""),
    framerate = fps,
    audio = comb_aud_fp
  )

}
