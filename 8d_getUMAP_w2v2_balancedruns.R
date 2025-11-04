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

age_levels <- levels(as.factor(full_ages))
babies_by_age <- list()
for (age in age_levels){
  babies_by_age[[age]] <- unique(as.factor(full_babies[which(full_ages==age)]))
}
min_n_babies <- min(sapply(babies_by_age, length))

nruns <- 10
for (run in 1:nruns){
  
  for (l in 1:12){ # iterate through w2v2 transformer embedding layers
    
    emb_data_allclips <- read.csv("w2v2embeddings/all_embeddings_scaled.csv") # unfortunately all_embeddings_scaled.csv doesn't have the data I need so need to work on that
    
    runDir <- paste("w2v2balancedRun",run,sep="")
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
    
  }
  
}