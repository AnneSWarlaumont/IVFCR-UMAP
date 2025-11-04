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
  
  emb_pca <- prcomp(all_embeddings)
  saveRDS(emb_pca,file=paste(umapDir,"emb_pca_w2v2layer",l,"_fullclean.rds",sep=""),ascii = TRUE)
  
  start_times <- sub("^(?:[^_]*_){2}([0-9.]+).*","\\1",full_wavFiles)
  end_times <- sub("^(?:[^_]*_){3}([0-9.]+).wav","\\1",full_wavFiles)
  
  emb_u_df <- data.frame(x=emb_umap$layout[,1],y=emb_umap$layout[,2],time=as.numeric(start_times),endtime=as.numeric(end_times),full_wavFiles,baby=full_babies,age=full_ages)
  emb_p_df <- data.frame(x=emb_pca$x[,1],y=emb_pca$x[,2],time=as.numeric(start_times),endtime=as.numeric(end_times),full_wavFiles,baby=full_babies,age=full_ages)
  
  emb_u_df <- emb_u_df[order(emb_u_df$time),]
  emb_p_df <- emb_p_df[order(emb_p_df$time),]
  
  # create base plot (all points without a current vocalization focus)
  baseplot_umap <- ggplot(emb_u_df, aes(x,y,color=age)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "viridis", begin = 3/18, direction=-1) +
    theme_minimal()
  ggsave(paste(umapDir,"baseplot_umap_w2v2_layer",l,".png",sep=""),width=5,height=4,dpi=300)
  
  baseplot_pca <- ggplot(emb_p_df, aes(x,y,color=age)) +
    geom_point(size = 1, shape = 1) +
    scale_color_viridis_c(option = "viridis", begin = 3/18, direction=-1) +
    theme_minimal()
  ggsave(paste(umapDir,"baseplot_pca_w2v2_layer",l,".png",sep=""),width=5,height=4,dpi=300)

}
