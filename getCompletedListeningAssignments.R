# Go through the relabelCHN assignments and identify the relabelings that are
# finished and can be kept and discard those that are in-progress

setwd("~/Documents/GitHub/IVFCR-UMAP/")
babies_list <- read.csv("babies_list_cleanaudio.csv")
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
      new_row <- data.frame(
        wav_filename = assignments$wav_filename[l],
        segments_filename = assignments$segments_filename[l],
        relabels_filename = assignments$output_filename[l],
        listenerID = sub(".txt","",sub("homebank-child-voc-cleaning/relabelCHN_assignments_","",f)),
        listen_pass = sub(".csv","",sub("^.*_","",assignments$output_filename[l])),
        babyID = sub("_.*","",assignments$wav_filename[l]),
        babyAge = as.integer(substr(assignments$wav_filename[l],6,7))*365 + as.integer(substr(assignments$wav_filename[l],8,9))*30 + as.integer(substr(assignments$wav_filename[l],10,11)),
        stringsAsFactors = FALSE
      )
      completed_relabel_file_info <- rbind(completed_relabel_file_info,new_row)
    }
  }
}
write.csv(completed_relabel_file_info,"completed_relabel_file_info.csv")
