library(umap)
setwd("~/Documents/GitHub/IVFCR-UMAP/best_clips_spectral_features")

spectral_data_files <- list.files(pattern = "^best.*means.csv")

full_spectral_data <- data.frame()
full_wavFiles <- c()
full_ages <- c()
for (f in spectral_data_files){
  spectral_data <- read.csv(f)
  wavFiles <- spectral_data$wavFile
  spectral_data <- spectral_data[,grep("V",colnames(spectral_data))]
  full_spectral_data <- rbind(full_spectral_data,spectral_data)
  full_wavFiles <- c(full_wavFiles,wavFiles)
  age_days <- as.numeric(gsub("_.*","",gsub("^[^_]*_","",wavFiles)))
  age_months <- round(age_days/30)
  full_ages <- c(full_ages,age_months)
}

full_spectral_umap <- umap(full_spectral_data)
cols <- rainbow(length(levels(as.factor(full_ages))))[as.factor(full_ages)]

pdf("full_spectral_umap.pdf")
par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
plot(full_spectral_umap$layout[,1],full_spectral_umap$layout[,2],col=cols)
legend("topright",inset = c(-.25, 0),legend=levels(as.factor(full_ages)),col=rainbow(length(levels(as.factor(full_ages)))),pch=19)
dev.off()

saveRDS(full_spectral_umap,file="full_spectral_umap.rds",ascii = TRUE)

custom_config <- umap.defaults
custom_config$n_neighbors <- 100
#custom_config$min_dist <- .2
custom_umap <- umap(full_spectral_data,config=custom_config)

pdf("custom_umap_100neighbors.pdf")
par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
plot(custom_umap$layout[,1],custom_umap$layout[,2],col=cols)
legend("topright",inset = c(-.25, 0),legend=levels(as.factor(full_ages)),col=rainbow(length(levels(as.factor(full_ages)))),pch=19)
dev.off()

saveRDS(custom_umap,file="custom_umap_100neighbors.rds",ascii = TRUE)
