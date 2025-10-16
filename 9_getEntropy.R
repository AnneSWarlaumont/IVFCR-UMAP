# To-do: Update this to work on full dataset projected onto each of the balanced umap runs.

library(habtools)
library(YEAB)

setwd("~/Documents/GitHub/IVFCR-UMAP")

mfccData <- read.csv("best_clips_spectral_features/all_best_clips_babies_ages_and_spectral_data.csv")
mfccData <- subset(mfccData,infant!="all")
age_levels <- levels(as.factor(mfccData$age))
babies <- levels(as.factor(mfccData$infant))

entropyData <- data.frame(umap_run <- character(),
                          infant <- character(),
                          age <- integer(),
                          projections_entropy <- numeric())

nruns <- 10
for (run in 1:nruns){
  
  runDir <- paste("umap_data/balancedRun",run,sep="")
  
  run_umap_projections <- read.csv(paste(runDir,"/full_data_balanced_umap_projections.csv",sep=""))
  
  x_breaks <- seq(min(run_umap_projections$x),max(run_umap_projections$x),length.out = 10)
  y_breaks <- seq(min(run_umap_projections$y),max(run_umap_projections$y),length.out = 10)
  
  for (baby in babies){
    indices <- which(run_umap_projections$infant==baby)
    a <- run_umap_projections$age[indices[1]]
    recording_umap_projections <- data.frame(cbind(run_umap_projections$x[indices],run_umap_projections$y[indices]))
    colnames(recording_umap_projections) <- c("x","y")
    xbin <- cut(recording_umap_projections$x, breaks = x_breaks, include.lowest = TRUE)
    ybin <- cut(recording_umap_projections$y, breaks = y_breaks, include.lowest = TRUE)
    h2d <- table(xbin,ybin)
    p <- h2d/sum(h2d)
    p <- p[p>0]
    this_entropy <- -sum(p * log2(p))
    entropyRow <- cbind(run,baby,a,this_entropy)
    entropyData <- rbind(entropyData,entropyRow)
  }
  
}

# To-do: Get averages and standard deviations across runs and put those at the top of the entropyData table
for (baby in babies){
  
}

# To-do: 
# Export of the entropy results
# Write script to run stats



# It would be nice to show the grid superimposed on the umap plot
# And then perhaps also show a heatmap corresponding to the histogram used in entropy calculation.