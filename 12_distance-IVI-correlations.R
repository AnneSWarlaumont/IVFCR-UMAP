# For each recording, can look in best_clip_labels_<baby>_<agedays>.csv to 
# get start and end times of each clean clip (need to subset by the "clean"
# column). Can then look the clip up by wavFile in all_emb_scaled_layer<l>.csv
# where the convention is <baby>_<agedays>_<startsec>_<endsec>.wav, to get
# the embedding data. Or can look up the clip wavFile in each run's
# full_data_balanced_umap_projections.csv file, for either mfcc or w2v2 umaps,
# or in all_best_clips_babies_ages_and_spectral_data.csv for the 36 mfcc values.

# Then, get IVI-distance (or IVI-cosine) betas and their CIs, controlling for
# (1|ID).
# We can then see which metrics give the highest correlations with IVI.

# It may also be interesting to train an age classifier on mfcc, w2v2 or umap
# positions to see which shows the strongest association with age, and then
# use that feature.

# We could also look into pca vs umap.

# First things first though, perhaps just compare across w2v2 layers and mfccs,
# without UMAP or PCA. And focus on the IVI-distance beta

library(data.table)

setwd("~/Documents/GitHub/IVFCR-UMAP")

rec_info <- fread("cleaning_metadata/recordings_cleaning_data.csv",
                  select = c("babyID","babyAge"))

ivi_data <- data.frame()
  
for (r in 1:nrow(rec_info)){
  bID <- rec_info$babyID[r]
  bAge <- rec_info$babyAge[r]
  clip_info <- read.csv(paste("cleaning_metadata/best_clip_labels_",bID,"_",bAge,".csv",sep=""))
  clip_info <- subset(clip_info,clean)
  for (c in 1:(nrow(clip_info)-1)){
    ivi <- (clip_info$startSecond[c+1]-clip_info$endSecond[c])
    clip1_wavFile <- paste(bID,"_",bAge,"_",clip_info$startSecond[c],"_",clip_info$endSecond[c],".wav",sep="")
    clip2_wavFile <- paste(bID,"_",bAge,"_",clip_info$startSecond[c+1],"_",clip_info$endSecond[c+1],".wav",sep="")
    ivi_data_row <- data.frame(babyID = bID,
                               babyAge = bAge,
                               ivi_in_seconds = ivi,
                               wavFile1 = clip1_wavFile,
                               wavFile2 = clip2_wavFile)
    ivi_data <- rbind(ivi_data, ivi_data_row)
  }
}

fwrite(ivi_data,file="clean_ivi_data.csv")

for (l in 1:12){
  w2v2_embeddings <- fread(paste("w2v2embeddings/all_emb_scaled_layer",l,".csv",sep=""))
  layer_distances <- c()
  for (i in 1:nrow(ivi_data)){
    clip_embeddings <- rbind(subset(w2v2_embeddings,wavFile == ivi_data$wavFile1[i], select = -c(infant,age,wavFile)),
                        subset(w2v2_embeddings,wavFile == ivi_data$wavFile2[i], select = -c(infant,age,wavFile)))
    ## Looks like there is a bug that the w2v2_embeddings wavFile values are mismatched to the infant ID and age variables.
    ## So next work session I need to look into where that arose from and fix up the analysis pipeline accordingly.
    ## As well as re-computing the stats calculated previously.
    this_dist <- dist(clip_embeddings)
  }
}
