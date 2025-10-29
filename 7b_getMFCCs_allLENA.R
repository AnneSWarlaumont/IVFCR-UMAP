# Get MFCCs, deltas, and delta deltas for each ivfcr clip's wav file
# Store in one table for each recording? Or in separate tables per segment type?

library(tuneR)

setwd("~/Documents/IVFCR_LENA_Segments/")

wavDirs <- list.files(pattern = "*segWavFiles")

for (wavDir in wavDirs[9:length(wavDirs)]){
  
  clip_mfcc_d_dd_sums <- data.frame()
  clip_mfcc_d_dd_means <- data.frame()
  
  wavFiles <- list.files(path = paste(wavDir), pattern = "*.wav")
  
  for (wavFile in wavFiles){ # example of a wavFile string: "0009_000302_35925.87_35927.2_TVN.wav"
    
    clip_wav <- readWave(paste(wavDir,"/",wavFile,sep=""))
    
    if (length(clip_wav@left) / clip_wav@samp.rate >= 0.025){
      clip_melfcc <- melfcc(clip_wav)
      clip_deltas <- deltas(clip_melfcc)
      clip_deltadeltas <- deltas(clip_deltas)
      clip_mfcc_d_dd <- cbind(clip_melfcc,clip_deltas,clip_deltadeltas)
      
      clip_mfcc_d_dd_mean <- colMeans(clip_mfcc_d_dd)
      
      write.table(cbind(wavFile,t(clip_mfcc_d_dd_mean)),paste(gsub("_segWavFiles","",wavDir),"_mfcc_d_dd_means.csv",sep=""),append=TRUE,sep=",",row.names=FALSE,col.names=FALSE)
    }
    
  }
  
}
