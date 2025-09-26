# Create a summary table of recordings with "clean" versions and some metadata
# And a similar table for listeners

setwd("~/Documents/GitHub/IVFCR-UMAP/cleaning_metadata")
completed_relabels <- read.csv("completed_relabel_file_info.csv")

recordings_data <- data.frame(
  babyID <- character(),
  babyAge <- integer(),
  n_pass1 <- integer(),
  n_pass2 <- integer(),
  listeners_pass1 <- character(),
  listeners_pass2 <- character(),
  stringsAsFactors = FALSE
)

listeners_data <- data.frame(
  listenerID <- character(),
  n_pass1 <- integer(),
  n_pass2 <- integer(),
  recordings_pass1 <- character(),
  recordings_pass2 <- character(),
  stringsAsFactors = FALSE
)

for (a in 1:nrow(completed_relabels)){
  
  # Get the current row babyID, babyAge, and listenerID
  this_babyID <- completed_relabels$babyID[a]
  this_babyAge <- completed_relabels$babyAge[a]
  this_listenerID <- completed_relabels$listenerID[a]
  listen_pass <- completed_relabels$listen_pass[a]
  wav_filename <- completed_relabels$wav_filename[a]
  
  # Check if there is a row of recordings_data for this babyID and age.
  # If so, update the n_pass and listener_pass columns.
  # If not, create a new row and populate all the columns.
  if (nrow(subset(recordings_data,(babyID==this_babyID)&(babyAge==this_babyAge))>0)){
    this_row <- which(recordings_data$babyID==this_babyID&recordings_data$babyAge==this_babyAge)
    if (listen_pass == 1){
      recordings_data$n_pass1[this_row] <- recordings_data$n_pass1[this_row] + 1
      new_string <- paste(recordings_data$listeners_pass1[this_row],this_listenerID,sep=",")
      recordings_data$listeners_pass1[this_row] <- new_string
    } else if (listen_pass == 2){
      recordings_data$n_pass2[this_row] <- recordings_data$n_pass2[this_row] + 1
      if (recordings_data$listeners_pass2[this_row]==""){
        new_string <- this_listenerID
      } else{
        new_string <- paste(recordings_data$listeners_pass2[this_row],this_listenerID,sep=",")
      }
      recordings_data$listeners_pass2[this_row] <- new_string
    }
  } else{
    new_row <- data.frame(
      babyID = this_babyID,
      babyAge = this_babyAge,
      n_pass1 = 1,
      n_pass2 = 0,
      listeners_pass1 = this_listenerID,
      listeners_pass2 = "",
      stringsAsFactors = FALSE
    )
   recordings_data <- rbind(recordings_data,new_row) 
  }
  
  # Check if there is a row of listeners_data for this listener.
  # If so, update the n_pass and recordings_pass columns.
  # If not, create a new row and populate all the columns.
  if (nrow(subset(listeners_data,listenerID==this_listenerID)>0)){
    this_row <- which(listeners_data$listenerID==this_listenerID)
    if (listen_pass == 1){
      listeners_data$n_pass1[this_row] <- listeners_data$n_pass1[this_row] + 1
      new_string <- paste(listeners_data$recordings_pass1[this_row],wav_filename,sep=",")
      listeners_data$recordings_pass1[this_row] <- new_string
    } else if (listen_pass == 2){
      listeners_data$n_pass2[this_row] <- listeners_data$n_pass2[this_row] + 1
      if (listeners_data$recordings_pass2[this_row]==""){
        new_string <- wav_filename
      } else{
        new_string <- paste(listeners_data$recordings_pass2[this_row],wav_filename,sep=",")
      }
      listeners_data$recordings_pass2[this_row] <- new_string
    }
  } else{
    new_row <- data.frame(
      listenerID = this_listenerID,
      n_pass1 = 1,
      n_pass2 = 0,
      recordings_pass1 = wav_filename,
      recordings_pass2 = "",
      stringsAsFactors = FALSE
    )
    listeners_data <- rbind(listeners_data,new_row) 
  }
  
}