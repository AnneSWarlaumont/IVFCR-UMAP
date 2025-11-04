library(umap)
library(viridis)

setwd("~/Documents/GitHub/IVFCR-UMAP")
inputDir <- "best_clips_spectral_features/"
umapDir <- "umap_data/"

if (!dir.exists(umapDir)){
  dir.create(umapDir)
}

spectral_data_files <- list.files(path = inputDir, pattern = "^best.*means.csv")

full_spectral_data <- data.frame()
full_wavFiles <- c()
full_ages <- c()
full_babies <- c()
min_n_clips <- 1e10
for (f in spectral_data_files){
  spectral_data <- read.csv(paste(inputDir,f,sep=""))
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
  full_wavFiles <- c(full_wavFiles,wavFiles)
}

random_order <- sample(nrow(full_spectral_data))
full_spectral_data <- full_spectral_data[random_order,]
full_spectral_data <- scale(full_spectral_data) # normalize each spectral feature
full_babies <- full_babies[random_order]
full_ages <- full_ages[random_order]
full_wavFiles <- full_wavFiles[random_order]

spec_feature_names <- c()
spec_feature_types <- c("MFCC","dMFCC","ddMFCC")
mfcc_num <- 12
for (t in spec_feature_types){
  for (i in 1:mfcc_num){
    sf_name <- paste(t,i,sep="")
    spec_feature_names <- c(spec_feature_names,sf_name)
  }
}

csv_data <- rbind(cbind("all","scaled:center","NA",t(attr(full_spectral_data,"scaled:center"))),
                  cbind("all","scaled:scale","NA",t(attr(full_spectral_data,"scaled:scale"))),
                  cbind(full_babies,full_ages,full_wavFiles,full_spectral_data))
colnames(csv_data) <- c("infant","age","wavFile",spec_feature_names)
rownames(csv_data) <- NULL
write.csv(csv_data,file=paste(inputDir,"all_best_clips_babies_ages_and_spectral_data.csv",sep=""),row.names = FALSE)

full_spectral_umap <- umap(full_spectral_data)
cols <- turbo(24)[as.numeric(full_ages)-2]

pdf(paste(umapDir,"full_spectral_umap.pdf",sep=""))
par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
plot(full_spectral_umap$layout[,1],full_spectral_umap$layout[,2],col=cols)
legend("topright",inset = c(-.25, 0),legend=unique(sort(as.numeric(full_ages))),col=turbo(24)[as.numeric(c(3,6,9,18))-2],pch=19)
dev.off()

saveRDS(full_spectral_umap,file=paste(umapDir,"full_spectral_umap.rds",sep=""),ascii = TRUE)

###############################################################################
# Get a UMAP projection based on a subsample of the data that is fully balanced
# across age groups.
###############################################################################

# To-do: Perform the random selection of balanced data a bunch of times
# so later analyses can average over those different UMAP runs.

# Subsample the data so that across age groups, the number of participants and
# the number of samples per participant are constant. For # of participants,
# that will have to be the minimum number of babies at any age group. That # of
# participants will be chosen at random per age. For # of samples, we can sample
# a number per recording matching the N of the recording with the fewest infant
# vocalization clips.

age_levels <- levels(as.factor(full_ages))
babies_by_age <- list()
for (age in age_levels){
  babies_by_age[[age]] <- unique(as.factor(full_babies[which(full_ages==age)]))
}
min_n_babies <- min(sapply(babies_by_age, length))

nruns <- 10
for (run in 1:nruns){
  
  runDir <- paste("umap_data/balancedRun",run,sep="")
  if (!dir.exists(runDir)){
    dir.create(runDir)
  }
  
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
  
  pdf(paste(runDir,"/balanced_spectral_umap.pdf",sep=""))
  par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
  plot(balanced_spectral_umap$layout[,1],balanced_spectral_umap$layout[,2],col=cols)
  legend("topright",inset = c(-.25, 0),legend=unique(sort(as.numeric(balanced_data_ages))),col=turbo(24)[as.numeric(c(3,6,9,18))-2],pch=19)
  dev.off()
  
  saveRDS(balanced_spectral_umap,file=paste(runDir,"/balanced_spectral_umap.rds",sep=""),ascii = TRUE)
  saveRDS(balanced_data_ages,file=paste(runDir,"/balanced_data_ages.rds",sep=""),ascii = TRUE)
  saveRDS(balanced_data_babies,file=paste(runDir,"/balanced_data_babies.rds",sep=""),ascii = TRUE)
  
  # Get the full data projected onto the balanced UMAP
  full_data_balanced_umap_projections <- predict(balanced_spectral_umap,full_spectral_data)
  cols <- turbo(24)[as.numeric(full_ages)-2]
  pdf(paste(runDir,"/fulldata_balanced_umap.pdf",sep=""))
  par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
  plot(full_data_balanced_umap_projections[,1],full_data_balanced_umap_projections[,2],col=cols)
  legend("topright",inset = c(-.25, 0),legend=unique(sort(as.numeric(full_ages))),col=turbo(24)[as.numeric(c(3,6,9,18))-2],pch=19)
  dev.off()
  
  csv_data <- cbind(full_babies,full_ages,full_wavFiles,full_data_balanced_umap_projections)
  colnames(csv_data) <- c("infant","age","wavFile","x","y")
  rownames(csv_data) <- NULL
  write.csv(csv_data,file=paste(runDir,"/full_data_balanced_umap_projections.csv",sep=""),row.names = FALSE)
}
