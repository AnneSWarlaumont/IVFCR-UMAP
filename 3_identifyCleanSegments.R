# Identify which child (CHN) segments are "clean based on the latest pass
# available for each listener. Following the Pagliarini et al. (2022, arXiv)
# paper, we will find the modal value for each clip and then consider clips
# with a modal value of 1 (only the infant wearing the recorder, with no or only
# very negligible background noise)

setwd("~/Documents/GitHub/IVFCR-UMAP/")
recordings_cleaning_data <- read.csv("cleaning_metadata/recordings_cleaning_data.csv")
relabel_file_info <- read.csv("cleaning_metadata/completed_relabel_file_info.csv")

for (r in 1:nrow(recordings_cleaning_data)){
  
  r_babyID <- recordings_cleaning_data$babyID[r]
  r_babyAge <- recordings_cleaning_data$babyAge[r]
  
  # if a listener also appears in listeners_pass2, look up their pass 2 labels filename
  # otherwise, look up their pass 1 labels filename
  p1_listeners <- unlist(strsplit(recordings_cleaning_data$listeners_pass1[r],","))
  p2_listeners <- unlist(strsplit(recordings_cleaning_data$listeners_pass2[r],","))
  for (l in p1_listeners){
    if (l %in% p2_listeners){
      pass <- 2
    } else{
      pass <- 1
    }
    relabels_row <- subset(relabel_file_info,
                           (listenerID==l
                            &listen_pass==pass
                            &babyID==recordings_cleaning_data$babyID[r]
                            &babyAge==recordings_cleaning_data$babyAge[r]))
    r_wav_filename <- relabels_row$wav_filename
    r_relabels_filename <- relabels_row$relabels_filename
    r_relabels_filepath <- paste("homebank-child-voc-cleaning/",r_relabels_filename,sep="")
    r_l_clip_labels <- read.csv(r_relabels_filepath)
    
    # create a table where each row is a clip
    # columns will be: start time, end time, listener 1 judgement, etc.
    if (!exists("r_clip_labels")){
      n_clips <- nrow(r_l_clip_labels)
      r_clip_labels <- data.frame(recording = rep(r_wav_filename,n_clips),
                                  startSeconds = r_l_clip_labels$startSeconds,
                                  endSeconds = r_l_clip_labels$endSeconds)
    }
    colname <- paste(l,pass,"targetChildProminence",sep="_")
    r_clip_labels[[colname]] <- r_l_clip_labels$targetChildProminence
  }
  
  # add a modal value column and a clean (TRUE/FALSE) column
  for (c in 1:nrow(r_clip_labels)){
    labels <- r_clip_labels[c,!(names(r_clip_labels) %in% c("recording","startSeconds","endSeconds"))]
    freqs <- table(as.numeric(labels))
    modal_prom <- as.numeric(names(which.max(freqs))) # TODO! fix this (see step 5)
    r_clip_labels$modal_prominence[c] <- modal_prom
    if (modal_prom==1){
      r_clip_labels$clean[c] <- TRUE
    } else{
      r_clip_labels$clean[c] <- FALSE
    }
  }
  
  write.csv(r_clip_labels,paste("cleaning_metadata/clip_labels_",r_babyID,"_",r_babyAge,".csv",sep=""))
  rm("r_clip_labels")
}