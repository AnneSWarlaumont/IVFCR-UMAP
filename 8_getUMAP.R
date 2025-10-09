library(umap)
library(viridis)

setwd("~/Documents/GitHub/IVFCR-UMAP/best_clips_spectral_features")

spectral_data_files <- list.files(pattern = "^best.*means.csv")

full_spectral_data <- data.frame()
full_wavFiles <- c()
full_ages <- c()
full_babies <- c()
min_n_clips <- 1e10
for (f in spectral_data_files){
  spectral_data <- read.csv(f)
  if (nrow(spectral_data) < min_n_clips){
    min_n_clips <- nrow(spectral_data)
  }
  wavFiles <- spectral_data$wavFile
  spectral_data <- spectral_data[,grep("V",colnames(spectral_data))]
  full_spectral_data <- rbind(full_spectral_data,spectral_data)
  full_wavFiles <- c(full_wavFiles,wavFiles)
  age_days <- as.numeric(gsub("_.*","",gsub("^[^_]*_","",wavFiles)))
  age_months <- round(age_days/30)
  full_ages <- c(full_ages,age_months)
  babies <- regmatches(wavFiles,regexpr("^[^_]*",wavFiles))
  full_babies <- c(full_babies,babies)
}

random_order <- sample(nrow(full_spectral_data))
full_spectral_data <- full_spectral_data[random_order,]
full_babies <- full_babies[random_order]
full_ages <- full_ages[random_order]

full_spectral_umap <- umap(full_spectral_data)
cols <- turbo(24)[as.numeric(full_ages)-2]

pdf("full_spectral_umap.pdf")
par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
plot(full_spectral_umap$layout[,1],full_spectral_umap$layout[,2],col=cols)
legend("topright",inset = c(-.25, 0),legend=unique(sort(as.numeric(full_ages))),col=turbo(24)[as.numeric(c(3,6,9,18))-2],pch=19)
dev.off()

saveRDS(full_spectral_umap,file="full_spectral_umap.rds",ascii = TRUE)


# subsample the data so that across age groups, the number of participants and
# the number of samples per participant are constant. For # of participants,
# that will have to be two (chosen at random?) and for # of samples, we can
# choose that to match the smallest #, or choose some smaller N, perhaps chosen
# to be the N of the recording with the least # of samples 

age_levels <- levels(as.factor(full_ages))
babies_by_age <- list()
for (age in age_levels){
  babies_by_age[[age]] <- unique(as.factor(full_babies[which(full_ages==age)]))
}
min_n_babies <- min(sapply(babies_by_age, length))

# now randomly sample min_n_babies babies per age group
# and then sample min_n_clips per sampled baby
balanced_spectral_data <- data.frame()
balanced_data_babies <- c()
balanced_data_ages <- c()
for (age in age_levels){
  age_sampled_babies <- sample(babies_by_age[[age]],size=min_n_babies)
  for (baby in age_sampled_babies){
    baby_spectral_data <- full_spectral_data[which(full_babies==baby),]
    sampled_clips <- sample(nrow(baby_spectral_data),size=min_n_clips)                            
    sampled_baby_spectral_data <- baby_spectral_data[sampled_clips,]                             
    balanced_spectral_data <- rbind(balanced_spectral_data,sampled_baby_spectral_data)
    balanced_data_babies <- c(balanced_data_babies,rep(baby,min_n_clips))
    balanced_data_ages <- c(balanced_data_ages,rep(age,min_n_clips))
  }
}
random_order <- sample(nrow(balanced_spectral_data))
balanced_spectral_data <- balanced_spectral_data[random_order,]
balanced_data_babies <- balanced_data_babies[random_order]
balanced_data_ages <- balanced_data_ages[random_order]

balanced_spectral_umap <- umap(balanced_spectral_data)
cols <- turbo(24)[as.numeric(balanced_data_ages)-2]

pdf("balanced_spectral_umap.pdf")
par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
plot(balanced_spectral_umap$layout[,1],balanced_spectral_umap$layout[,2],col=cols)
legend("topright",inset = c(-.25, 0),legend=unique(sort(as.numeric(balanced_data_ages))),col=turbo(24)[as.numeric(c(3,6,9,18))-2],pch=19)
dev.off()

saveRDS(balanced_spectral_umap,file="balanced_spectral_umap.rds",ascii = TRUE)
saveRDS(balanced_data_ages,file="balanced_data_ages.rds",ascii = TRUE)
saveRDS(balanced_data_babies,file="balanced_data_babies.rds",ascii = TRUE)

# Customize the UMAP to have higher n_neighbors, so a smoother distribution of
# points. Takes longer to run.
custom_config <- umap.defaults
custom_config$n_neighbors <- 15
custom_config$min_dist <- 0.5
custom_balanced_umap <- umap(balanced_spectral_data,config=custom_config)
pdf("custom_balanced_umap.pdf")
par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
plot(custom_balanced_umap$layout[,1],custom_balanced_umap$layout[,2],col=cols)
legend("topright",inset = c(-.25, 0),legend=unique(sort(as.numeric(balanced_data_ages))),col=turbo(24)[as.numeric(c(3,6,9,18))-2],pch=19)
dev.off()
saveRDS(custom_balanced_umap,file="custom_balanced_umap.rds",ascii = TRUE)
