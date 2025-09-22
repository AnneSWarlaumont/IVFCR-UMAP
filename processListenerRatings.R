# Plan:
# Go through the relabelCHN assignments and identify the relabelings that are
# finished and can be kept and discard those that are in-progress
# While at it, create a master list of files to be included, together with some
# metadata for each
# Get the modal rating for each LENA segment
# Perhaps do this using only first pass or using 2nd pass if available
# Computer inter-rater and intra-rater reliability
# Get clean lists of the subset of clips that are clean as defined by Pagliarini
# et al. (2022)

setwd("~/Documents/GitHub/IVFCR-UMAP/")
babies_list <- read.csv("babies_list_cleanaudio.csv")
completed_relabel_file_info <- data.frame(
  wav_filename <- character(),
  segments_filename <- character(),
  relabels_filename <- character(),
  listenerID <- character(),
  round <- integer(),
  stringsAsFactors = FALSE
)
relabelCHN_assignments_files <- Sys.glob("homebank-child-voc-cleaning/relabelCHN_assignments_????.txt")
for (f in relabelCHN_assignments_files){
  assignments <- read.csv(f)
  for (l in 1:nrow(assignments)){
    if ((assignments$instructions_version[l]==3)&&(assignments$status[l]=="finished")){
      new_row <- data.frame(
        wav_filename <- assignments$wav_filename[l],
        # here
      )
    }
  }
}