# Create a master list of recordings with "clean" versions and their metadata

setwd("~/Documents/GitHub/IVFCR-UMAP/")
completed_relabel_file_info <- read.csv("completed_relabel_file_info.csv")

cleaned_recordings_metadata <- data.frame(
  babyID <- character(),
  babyAge <- integer(),
  pass1_n <- integer(),
  pass2_n <- integer(),
  pass3_n <- integer(),
  pass1_listeners <- character(),
  pass2_listeners <- character(),
  pass3_listeners <- character()
)

for (a in 1:nrow(completed_relabel_file_info)){
  # here (not sure exactly how I want to go about populating the above data frame quite yet, or whether I will keep that data structure)
}