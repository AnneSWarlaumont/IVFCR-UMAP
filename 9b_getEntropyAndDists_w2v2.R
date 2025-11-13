# Like 9a, but for each layer of w2v2 embeddings instead of mfccs

library(habtools)
library(YEAB)

setwd("~/Documents/GitHub/IVFCR-UMAP")

entropyData <- data.frame(w2v2Layer <- integer(),
                          umap_run <- character(),
                          infant <- character(),
                          age <- integer(),
                          projections_entropy <- numeric(),
                          projections_avgpairdist <- numeric())

w2v2Data <- read.csv("w2v2embeddings/all_emb_scaled_layer1.csv")
age_levels <- levels(as.factor(w2v2Data$age))
babies <- levels(as.factor(w2v2Data$infant))
nruns <- 10

for (l in 1:12){
  
  for (run in 1:nruns){
    
    runDir <- paste("w2v2_balancedRunData/w2v2balancedRun",run,"_layer",l,sep="")
    run_umap_projections <- read.csv(paste(runDir,"/full_data_balanced_umap_projections.csv",sep=""))
    
    x_breaks <- seq(min(run_umap_projections$x),max(run_umap_projections$x),length.out = 10)
    y_breaks <- seq(min(run_umap_projections$y),max(run_umap_projections$y),length.out = 10)
    
    for (baby in babies){
      
      indices <- which(run_umap_projections$infant==baby)
      a <- run_umap_projections$age[indices[1]]
      wavFiles <- run_umap_projections$wavFile[indices]
      this_umap_projections <- data.frame(cbind(run_umap_projections$x[indices],run_umap_projections$y[indices]))
      colnames(this_umap_projections) <- c("x","y")
      
      # entropy calculation
      xbin <- cut(this_umap_projections$x, breaks = x_breaks, include.lowest = TRUE)
      ybin <- cut(this_umap_projections$y, breaks = y_breaks, include.lowest = TRUE)
      h2d <- table(xbin,ybin)
      p <- h2d/sum(h2d)
      p <- p[p>0]
      this_entropy <- -sum(p * log2(p))
      
      # pairwise distances
      distvec <- as.vector(dist(this_umap_projections))
      this_meandist <- mean(distvec)
      
      entropyRow <- cbind(l,run,baby,a,this_entropy,this_meandist)
      entropyData <- rbind(entropyData,entropyRow)
      
    }
    
  }
  
}

write.csv(entropyData,"umap_data/w2v2_entropyData_runLevel.csv",row.names = FALSE)

pooledEntropyData <- data.frame(w2v2Layer <- integer(),
                                infant <- character(),
                                age <- integer(),
                                entropy_avg <- numeric(),
                                entropy_sd <- numeric(),
                                avgpairdist_avg <- numeric(),
                                avgpairdist_sd <- numeric(),
                                avgw2v2dist <- numeric(),
                                nRuns <- numeric())

# Get averages and standard deviations of entropy and avg umap dist across runs
# Also get the avg w2v2 features dist

for (layer in 1:12){
  
  w2v2Data <- read.csv(paste("w2v2embeddings/all_emb_scaled_layer",l,".csv",sep=""))
  
  for (b in babies){
    
    # umap and metadata
    this_entropyData <- subset(entropyData,(baby==b & l==layer))
    avg_ent <- mean(as.numeric(this_entropyData$this_entropy))
    sd_ent <- sd(as.numeric(this_entropyData$this_entropy))
    avg_avgpairdist <- mean(as.numeric(this_entropyData$this_meandist))
    sd_avgpairdist <- sd(as.numeric(this_entropyData$this_meandist))
    n_runs <- nrow(this_entropyData)
    a <- this_entropyData$a[1]
    
    # w2v2 features (no umap)
    this_w2v2Data <- subset(w2v2Data,infant==b, select = -c(l,infant,age,wavFile))
    distvec <- as.vector(dist(this_w2v2Data))
    this_meanw2v2dist <- mean(distvec)
    
    #store
    pooled_row <- data.frame(l = layer,
                             infant = b,
                             age = a,
                             entropy_avg = avg_ent,
                             entropy_sd = sd_ent,
                             avgpairdist_avg = avg_avgpairdist,
                             avgpairdist_sd = sd_avgpairdist,
                             avgw2v2dist = this_meanw2v2dist,
                             nRuns = n_runs)
    pooledEntropyData <- rbind(pooledEntropyData,pooled_row)
    
  }
}

write.csv(pooledEntropyData,"w2v2dispersionData.csv",row.names = FALSE)

# It could be nice to show the grid of bins used for entropy calculation
# superimposed on the umap plot.
# And then it could be nice to show a heat map corresponding to the histogram
# that forms the basis of the entropy calculation.

# Should consider using cosine similarity instead of Euclidean distance
# See cosine in the coop package
