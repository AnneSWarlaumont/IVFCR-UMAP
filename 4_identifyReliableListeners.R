# Get interrater reliability in comparison to the primary (reference) listener

library(irr)

ref_listener <- "lplf" # This is me (Anne)

setwd("~/Documents/GitHub/IVFCR-UMAP/cleaning_metadata/")
completed_relabels <- read.csv("completed_relabel_file_info.csv")
listeners_cleaning_data <- read.csv("listeners_cleaning_data.csv")

# Check which assignments I completed, and which listeners did or did not have
# overlap with mine.
ref_completed <- subset(completed_relabels,listenerID==ref_listener)
other_listeners <- subset(listeners_cleaning_data,listenerID!=ref_listener)$listenerID

w_kappas_df <- data.frame(recording = ref_completed$wav_filename)
u_kappas_df <- data.frame(recording = ref_completed$wav_filename)

for (i in 1:nrow(ref_completed)){
  
  w <- ref_completed$wav_filename[i]
  this_babyID <- ref_completed$babyID[i]
  this_babyAge <- ref_completed$babyAge[i]
  
  clip_labels_file <- paste("clip_labels_",this_babyID,"_",this_babyAge,".csv",sep="")
  clip_labels <- read.csv(clip_labels_file)
  
  label_cols <- grep(".*targetChildProminence",names(clip_labels),value=TRUE)
  
  ref_col <- label_cols[grepl(ref_listener,label_cols)]
  other_cols <- label_cols[!grepl(ref_listener,label_cols)]
  
  for (l in other_listeners){
    if(length(grep(l,other_cols))>0){
      l_col <- other_cols[which(grepl(l,other_cols))[1]]
      w_kappa <- kappa2(cbind(clip_labels[[ref_col]],clip_labels[[l_col]]),weight="squared")$value
      u_kappa <- kappa2(cbind(clip_labels[[ref_col]],clip_labels[[l_col]]),weight="unweighted")$value
      w_kappas_df[[l]][i] <- w_kappa
      u_kappas_df[[l]][i] <- u_kappa
    } else{
      w_kappas_df[[l]][i] <- NA
      u_kappas_df[[l]][i] <- NA
    }
  }
  
}

write.csv(w_kappas_df,"weighted_kappas.csv")
write.csv(u_kappas_df,"unweighted_kappas.csv")

