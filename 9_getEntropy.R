library(habtools)
library(YEAB)

setwd("~/Documents/GitHub/IVFCR-UMAP/best_clips_spectral_features")

my_umap <- readRDS("balanced_spectral_umap.rds")
babies_data <- readRDS("balanced_data_babies.rds")
ages_data <- readRDS("balanced_data_ages.rds")

age_levels <- levels(as.factor(ages_data))
babies <- levels(as.factor(babies_data))

x_breaks <- seq(min(my_umap$layout[,1]),max(my_umap$layout[,1]),length.out = 10)
y_breaks <- seq(min(my_umap$layout[,2]),max(my_umap$layout[,2]),length.out = 10)

entropy_by_age <- list()
for (age in age_levels){
  age_umap_data <- cbind(my_umap$layout[which(ages_data==age),1],my_umap$layout[which(ages_data==age),2])
  xbin <- cut(age_umap_data[,1], breaks = x_breaks, include.lowest = TRUE)
  ybin <- cut(age_umap_data[,2], breaks = y_breaks, include.lowest = TRUE)
  h2d <- table(xbin,ybin)
  p <- h2d/sum(h2d)
  p <- p[p>0]
  entropy_by_age[age] <- -sum(p * log2(p))
}

# Need to add export of the entropy results
# And also implement it at the recording level

# It would be nice to show the grid superimposed on the umap plot
# And then perhaps also show a heatmap corresponding to the histogram used in entropy calculation.