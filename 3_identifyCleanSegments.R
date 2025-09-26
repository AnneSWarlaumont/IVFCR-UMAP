# Identify which child (CHN) segments are "clean based on the latest pass
# available for each listener. Following the Pagliarini et al. (2022, arXiv)
# paper, we will find the modal value for each clip and then consider clips
# with a modal value of 1 (only the infant wearing the recorder, with no or only
# very negligible background noise)

setwd("~/Documents/GitHub/IVFCR-UMAP/")
recordings_cleaning_data <- read.csv("cleaning_metadata/recordings_cleaning_data.csv")
