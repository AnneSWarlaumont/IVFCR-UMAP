###############################################################################
# Get a UMAP w2v2 projection for each transformer layer based on a subsample of
# the data that is fully balanced across age groups. (an 8c-like version of 8a)
###############################################################################

setwd("~/Documents/GitHub/IVFCR-UMAP/")

# Subsample the data so that across age groups, the number of participants and
# the number of samples per participant are constant. For # of participants,
# that will have to be the minimum number of babies at any age group. That # of
# participants will be chosen at random per age. For # of samples, we can sample
# a number per recording matching the N of the recording with the fewest infant
# vocalization clips.

min_n_clips <- 82 # from running just the top part of 8a
nruns <- 10
for (run in 1:nruns){
  
  for (l in 1:12){ # iterate through w2v2 transformer embedding layers
    
    emb_data_allclips <- read.csv(paste("w2v2embeddings/all_emb_scaled_layer",l,".csv",sep=""))
    full_emb_data <- emb_data_allclips[,4:ncol(emb_data_allclips)]
    full_babies <- emb_data_allclips$infant
    full_ages <- emb_data_allclips$age
    full_wavFiles <- emb_data_allclips$wavFile
    
    if (run==1 & l==1){
      age_levels <- levels(as.factor(emb_data_allclips$age))
      babies_by_age <- list()
      for (a in age_levels){
        babies_by_age[[a]] <- unique(as.factor(emb_data_allclips[which(emb_data_allclips$age==a),]$infant))
      }
      min_n_babies <- min(sapply(babies_by_age, length))
    }
    
    runDir <- paste("w2v2_balancedRunData/w2v2balancedRun",run,"_layer",l,sep="")
    if (!dir.exists(runDir)){
      dir.create(runDir)
    }
    # now randomly sample min_n_babies babies per age group
    # and then sample min_n_clips per sampled baby
    balanced_emb_data <- data.frame()
    balanced_data_babies <- c()
    balanced_data_ages <- c()
    for (age in age_levels){
      age_sampled_babies <- sample(babies_by_age[[age]],size=min_n_babies)
      for (baby in age_sampled_babies){
        baby_emb_data <- emb_data_allclips[which(emb_data_allclips$infant==baby),4:ncol(emb_data_allclips)]
        sampled_clips <- sample(nrow(baby_emb_data),size=min_n_clips)                            
        sampled_baby_emb_data <- baby_emb_data[sampled_clips,]                             
        balanced_emb_data <- rbind(balanced_emb_data,sampled_baby_emb_data)
        balanced_data_babies <- c(balanced_data_babies,rep(baby,min_n_clips))
        balanced_data_ages <- c(balanced_data_ages,rep(age,min_n_clips))
      }
    }
    
    random_order <- sample(nrow(balanced_emb_data))
    balanced_emb_data <- balanced_emb_data[random_order,]
    balanced_data_babies <- balanced_data_babies[random_order]
    balanced_data_ages <- balanced_data_ages[random_order]

    balanced_emb_umap <- umap(balanced_emb_data)
    cols <- turbo(24)[as.numeric(balanced_data_ages)-2]

    pdf(paste(runDir,"/balanced_emb_umap.pdf",sep=""))
    par(mar = c(5.1, 4.1, 4.1, 8.1), xpd = TRUE)
    plot(balanced_emb_umap$layout[,1],balanced_emb_umap$layout[,2],col=cols)
    legend("topright",inset = c(-.25, 0),legend=unique(sort(as.numeric(balanced_data_ages))),col=turbo(24)[as.numeric(c(3,6,9,18))-2],pch=19)
    dev.off()

    saveRDS(balanced_emb_umap,file=paste(runDir,"/balanced_emb_umap.rds",sep=""))
    saveRDS(balanced_data_ages,file=paste(runDir,"/balanced_data_ages.rds",sep=""))
    saveRDS(balanced_data_babies,file=paste(runDir,"/balanced_data_babies.rds",sep=""))

    # Get the full data projected onto the balanced UMAP
    full_data_balanced_umap_projections <- predict(balanced_emb_umap,full_emb_data)
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
  
}