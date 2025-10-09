# Get MFCCs, deltas, and delta deltas for each clip's wav file
# Store in one table for each clip_labels csv?

library(tuneR)
library(viridis)

setwd("~/Documents/GitHub/IVFCR-UMAP/cleaning_metadata/")

wavDirs <- list.files(pattern = "^best.*wavFiles")
for (wavDir in wavDirs){
  
  clip_mfcc_d_dd_sums <- data.frame()
  clip_mfcc_d_dd_means <- data.frame()
  
  wavFiles <- list.files(path = paste(wavDir), pattern = "*.wav")
  
  for (wavFile in wavFiles){
    
    clip_wav <- readWave(paste(wavDir,"/",wavFile,sep=""))
    
    specDir <- paste("../best_clips_spectral_features/",regmatches(wavFile,regexpr("^[^_]*_[^_]*_*",wavFile)),"spectralFeatures/",sep="")
    if (!dir.exists(specDir)){
      dir.create(specDir)
    }
    
    clip_melfcc <- melfcc(clip_wav)
    clip_deltas <- deltas(clip_melfcc)
    clip_deltadeltas <- deltas(clip_deltas)
    clip_mfcc_d_dd <- cbind(clip_melfcc,clip_deltas,clip_deltadeltas)
    
    clip_mfcc_d_dd_sum <- colSums(clip_mfcc_d_dd)
    clip_mfcc_d_dd_mean <- colMeans(clip_mfcc_d_dd)
    clip_spec <- t(powspec(clip_wav@left, sr = clip_wav@samp.rate))
    clip_spec <- 10*log10(t(powspec(clip_wav@left, sr = clip_wav@samp.rate))+1e-10)
    
    pdf(paste(specDir,gsub("^[^_]*_[^_]*_","",gsub(".wav","",wavFile)),"_mfcc_d_dd.pdf",sep=""))
    image(scale(clip_mfcc_d_dd),col = viridis(256))
    dev.off()
    
    pdf(paste(specDir,gsub("^[^_]*_[^_]*_","",gsub(".wav","",wavFile)),"_spectrogram.pdf",sep=""))
    image(clip_spec,col = viridis(256))
    dev.off()
    
    write.csv(clip_mfcc_d_dd,paste(specDir,gsub("^[^_]*_[^_]*_","",gsub(".wav","",wavFile)),"_mfcc_d_dd.csv",sep=""))
    write.csv(clip_spec,paste(specDir,gsub("^[^_]*_[^_]*_","",gsub(".wav","",wavFile)),"_spectrogram.csv",sep=""))
    
    clip_mfcc_d_dd_sums <- rbind(clip_mfcc_d_dd_sums,cbind(wavFile,t(clip_mfcc_d_dd_sum)))
    clip_mfcc_d_dd_means <- rbind(clip_mfcc_d_dd_means,cbind(wavFile,t(clip_mfcc_d_dd_mean)))
    
  }
  
  write.csv(clip_mfcc_d_dd_sums,paste("../best_clips_spectral_features/",gsub("_wavFiles","",wavDir),"_mfcc_d_dd_sums.csv",sep=""))
  write.csv(clip_mfcc_d_dd_means,paste("../best_clips_spectral_features/",gsub("_wavFiles","",wavDir),"_mfcc_d_dd_means.csv",sep=""))
  
}
