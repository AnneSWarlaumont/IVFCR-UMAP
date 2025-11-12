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

for (l in 1:12){
  
  w2v2Data <- read.csv(paste("w2v2embeddings/all_emb_scaled_layer",l,".csv",sep=""))
  age_levels <- levels(as.factor(w2v2Data$age))
  babies <- levels(as.factor(w2v2Data$infant))
  
  nruns <- 10
  
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

# HERE (see 9a) lin 55
