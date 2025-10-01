# Some files have no clean infant clips based on a modal rating == 1 criterion.
# Let's check interrater reliability and disregard raters with poor agreement,
# and see if that leads to more clips being identified as clean.
# Maybe some raters were much more conservative than others in giving a 1 rating.
# I will start by checking agreement with myself, listener id lplf, on the files
# I relabeled. If there are some listeners who never did files that I did, I can
# compare them to the listener who was most reliabile agains my own ratings
# (we'll want to consider both Cohen's kappa and number of files we both did;
# if someone has high cohen's kappa but that's only based on a small number of
# recordings we might not want to have them be the stand-in for me in judging
# other listeners. But let's see what the situation is.).

# Check which assignments I completed, and which listeners did or did not have
# overlap with mine. Can get this info. from completed_relabel_file_info.csv

library(irr)

ref_listener <- "lplf" # This is me (Anne)

setwd("~/Documents/GitHub/IVFCR-UMAP/cleaning_metadata")
completed_relabels <- read.csv("completed_relabel_file_info.csv")
listeners_cleaning_data <- read.csv("listeners_cleaning_data.csv")

ref_completed <- subset(completed_relabels,listenerID==ref_listener)
other_listeners <- subset(listeners_cleaning_data,listenerID!=ref_listener)$listenerID

w_kappas_df <- data.frame(recording <- ref_completed$wav_filename)
u_kappas_df <- data.frame(recording <- ref_completed$wav_filename)

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

