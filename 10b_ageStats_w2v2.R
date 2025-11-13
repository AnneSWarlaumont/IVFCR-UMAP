setwd("~/Documents/GitHub/IVFCR-UMAP")

dispersionData_allLayers <- read.csv("w2v2dispersionData.csv")

for (layer in 1:12){
  
  dispersionData <- subset(dispersionData_allLayers,l==layer)
  
  sink(paste("dispersionStats_w2v2_layer",layer,".txt",sep=""))
  
  umap_entropy_model <- lm(scale(entropy_avg) ~ poly(scale(age),2), data = dispersionData)
  print(summary(umap_entropy_model))
  
  umap_dist_model <- lm(scale(avgpairdist_avg) ~ poly(scale(age),2), data = dispersionData)
  print(summary(umap_dist_model))
  
  embedding_dist_model <- lm(scale(avgw2v2dist) ~ poly(scale(age),2), data = dispersionData)
  print(summary(embedding_dist_model))
  
  sink()
  
}
