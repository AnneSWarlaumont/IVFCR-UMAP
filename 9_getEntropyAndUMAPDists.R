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
                          projections_entropy <- numeric(),
                          projections_avgpairdist <- numeric())

nruns <- 10

for (run in 1:nruns){
  
  runDir <- paste("umap_data/balancedRun",run,sep="")
  
  run_umap_projections <- read.csv(paste(runDir,"/full_data_balanced_umap_projections.csv",sep=""))
  
  x_breaks <- seq(min(run_umap_projections$x),max(run_umap_projections$x),length.out = 10)
  y_breaks <- seq(min(run_umap_projections$y),max(run_umap_projections$y),length.out = 10)
  
  for (baby in babies){
    
    indices <- which(run_umap_projections$infant==baby)
    a <- run_umap_projections$age[indices[1]]
    wavFiles <- run_umap_projections$wavFile[indices]
    recording_umap_projections <- data.frame(cbind(run_umap_projections$x[indices],run_umap_projections$y[indices]))
    colnames(recording_umap_projections) <- c("x","y")
    
    # entropy calculation
    xbin <- cut(recording_umap_projections$x, breaks = x_breaks, include.lowest = TRUE)
    ybin <- cut(recording_umap_projections$y, breaks = y_breaks, include.lowest = TRUE)
    h2d <- table(xbin,ybin)
    p <- h2d/sum(h2d)
    p <- p[p>0]
    this_entropy <- -sum(p * log2(p))
    
    # pairwise distances
    distvec <- as.vector(dist(recording_umap_projections))
    this_meandist <- mean(distvec)
    
    entropyRow <- cbind(run,baby,a,this_entropy,this_meandist)
    entropyData <- rbind(entropyData,entropyRow)
    
  }
  
}

write.csv(entropyData,paste(runDir,"entropyData_runLevel.csv",sep=""))

pooledEntropyData <- data.frame(infant <- character(),
                          age <- integer(),
                          entropy_avg <- numeric(),
                          entropy_sd <- numeric(),
                          avgpairdist_avg <- numeric(),
                          avgpairdist_sd <- numeric(),
                          avgmfccdist <- numeric(),
                          nRuns <- numeric())

# Get averages and standard deviations of entropy and avg umap dist across runs
# Also get the avg mfcc features dist
for (b in babies){
  
  # umap and metadata
  baby_entropyData <- subset(entropyData,baby==b)
  avg_ent <- mean(as.numeric(baby_entropyData$this_entropy))
  sd_ent <- sd(as.numeric(baby_entropyData$this_entropy))
  avg_avgpairdist <- mean(as.numeric(baby_entropyData$this_meandist))
  sd_avgpairdist <- sd(as.numeric(baby_entropyData$this_meandist))
  n_runs <- nrow(baby_entropyData)
  a <- baby_entropyData$a[1]
  
  # mfcc features (no umap)
  baby_mfccData <- subset(mfccData,infant==b, select = -c(infant,age,wavFile))
  distvec <- as.vector(dist(baby_mfccData))
  this_meanmfccdist <- mean(distvec)
  
  #store
  pooled_row <- data.frame(infant = b,
                           age = a,
                           entropy_avg = avg_ent,
                           entropy_sd = sd_ent,
                           avgpairdist_avg = avg_avgpairdist,
                           avgpairdist_sd = sd_avgpairdist,
                           avgmfccdist = this_meanmfccdist,
                           nRuns = n_runs)
  pooledEntropyData <- rbind(pooledEntropyData,pooled_row)
}
write.csv(pooledEntropyData,paste(runDir,"entropyData_pooled.csv",sep=""),row.names = FALSE)

# It could be nice to show the grid of bins used for entropy calculation
# superimposed on the umap plot.
# And then it could be nice to show a heat map corresponding to the histogram
# that forms the basis of the entropy calculation.