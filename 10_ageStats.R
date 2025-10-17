setwd("~/Documents/GitHub/IVFCR-UMAP")

dispersionData <- read.csv("dispersionData.csv")

sink("dispersionStats.txt")

umap_entropy_model <- lm(scale(entropy_avg) ~ poly(scale(age),2), data = dispersionData)
print(summary(umap_entropy_model))

umap_dist_model <- lm(scale(avgpairdist_avg) ~ poly(scale(age),2), data = dispersionData)
print(summary(umap_dist_model))

spectral_dist_model <- lm(scale(avgmfccdist) ~ poly(scale(age),2), data = dispersionData)
print(summary(spectral_dist_model))

sink()
