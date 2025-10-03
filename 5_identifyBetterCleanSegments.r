# Let's include only listeners with weighted kappa >= .8

library(dplyr)

setwd("~/Documents/GitHub/IVFCR-UMAP/cleaning_metadata/")
w_kappas <- read.csv("weighted_kappas.csv")

# Get the average kappa for each listener
w_kappas$recording <- NULL
w_kappas$X <- NULL
avg_kappas <- colMeans(w_kappas, na.rm = FALSE)
best_listeners <- names(which(avg_kappas>=.8))

clip_files <- list.files(pattern = "clip_labels*")
for (f in clip_files){
  
  clip_labels <- read.csv(f)
  best_clip_labels <- clip_labels %>% select(starts_with(best_listeners))
  modal_prom <- numeric()
  cleanB <- logical()
  
  # add a modal value column and a clean (TRUE/FALSE) column
  for (c in 1:nrow(best_clip_labels)){
    freqs <- table(as.numeric(best_clip_labels[c,]))
    modal_prom[c] <- as.numeric(names(which.max(freqs)))
    if (modal_prom[c]==1){
      cleanB[c] <- TRUE
    } else{
      cleanB[c] <- FALSE
    }
  }
  
  best_clip_labels$modal_prominence <- modal_prom
  best_clip_labels$clean <- cleanB
  best_clip_labels$recording <- clip_labels$recording
  best_clip_labels$startSecond <- clip_labels$startSeconds
  best_clip_labels$endSecond <- clip_labels$endSeconds
  
  write.csv(best_clip_labels,paste("best_",f,sep=""))
  
}