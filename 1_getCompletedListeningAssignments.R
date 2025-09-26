# Go through the relabelCHN assignments and identify the relabelings that are
# finished and can be kept and discard those that are in-progress

setwd("~/Documents/GitHub/IVFCR-UMAP/")
outputDir <- "cleaning_metadata"
completed_relabel_file_info <- data.frame(
  wav_filename <- character(),
  segments_filename <- character(),
  relabels_filename <- character(),
  listenerID <- character(),
  listen_pass <- integer(),
  babyID <- character(),
  babyAge <- integer(),
  stringsAsFactors = FALSE
)
relabelCHN_assignments_files <- Sys.glob("homebank-child-voc-cleaning/relabelCHN_assignments_????.txt")
for (f in relabelCHN_assignments_files){
  assignments <- read.csv(f)
  for (l in 1:nrow(assignments)){
    if ((assignments$instructions_version[l]==3)&&(assignments$status[l]=="finished")){
      this_babyID <- sub("_.*","",assignments$wav_filename[l])
      this_babyAge <- as.integer(substr(assignments$wav_filename[l],6,7))*365 + as.integer(substr(assignments$wav_filename[l],8,9))*30 + as.integer(substr(assignments$wav_filename[l],10,11))
      this_listenerID <- sub(".txt","",sub("homebank-child-voc-cleaning/relabelCHN_assignments_","",f))
      if (nrow(subset(completed_relabel_file_info,(babyID==this_babyID)&(babyAge==this_babyAge)&(listenerID==this_listenerID)))){
        this_listen_pass <- 2
      } else{
        this_listen_pass <- 1
      }
      new_row <- data.frame(
        wav_filename = assignments$wav_filename[l],
        segments_filename = assignments$segments_filename[l],
        relabels_filename = assignments$output_filename[l],
        listenerID = this_listenerID,
        listen_pass = this_listen_pass,
        babyID = this_babyID,
        babyAge = this_babyAge,
        stringsAsFactors = FALSE
      )
      completed_relabel_file_info <- rbind(completed_relabel_file_info,new_row)
    }
  }
}
if (!dir.exists(outputDir)){
  dir.create(outputDir)
}
write.csv(completed_relabel_file_info,paste(outputDir,"/completed_relabel_file_info.csv",sep=""))
