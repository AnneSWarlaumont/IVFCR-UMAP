library(tuneR)
library(audio)
library(data.table)

# Randomly select two audio clips. Get listener similarity judgment on a 5-point
# scale.

cat("Welcome!\n")

setwd("~/Documents/GitHub/IVFCR-UMAP")
clip_info <- fread("best_clips_spectral_features/all_best_clips_babies_ages_and_spectral_data.csv",header=TRUE,select=c("infant","age","wavFile"))
clip_info <- subset(clip_info,wavFile!="NA")

q <- FALSE
replay <- FALSE
n <- 0
judgments <- data.frame(file1 <- character(),
                        file2 <- character(),
                        score <- character())
while (!q){
  
  if (!replay){
    n <- n+1
    wavefile1 <- sample(clip_info$wavFile,1)
    wavefile2 <- sample(clip_info$wavFile,1)
    w1dir <- paste("cleaning_metadata/best_clip_labels_",sub("^((?:[^_]*_){2}).*", "\\1", wavefile1),"wavFiles/",sep="")
    w2dir <- paste("cleaning_metadata/best_clip_labels_",sub("^((?:[^_]*_){2}).*", "\\1", wavefile2),"wavFiles/",sep="")
    wave1 <- readWave(paste(w1dir,wavefile1,sep=""))
    wave2 <- readWave(paste(w2dir,wavefile2,sep=""))
  }
  
  cat(paste("Playing Sound 1 of Pair",n,"\n"))
  Sys.sleep(.25)
  a1 <- audio::play(audioSample(wave1@left, rate = wave1@samp.rate))
  audio::wait(a1)
  Sys.sleep(.25)
  
  cat(paste("Playing Sound 2 of Pair",n,"\n"))
  Sys.sleep(.25)
  a2 <- audio::play(audioSample(wave2@left, rate = wave2@samp.rate))
  audio::wait(a2)
  Sys.sleep(.25)
  
  cat("Enter your similarity judgment:\n",
      "1: Indistinguishable\n",
      "2: Slightly different\n",
      "3: Moderately different\n",
      "4: Very different\n",
      "5: Completely different\n",
      "r: Replay sound\n",
      "q: Quit.\n")
  
  i <- readline(prompt="")
  
  if (i=="q"){
    q <- TRUE
  } else if (i=="r"){
    replay <- TRUE
  } else if (i=="1"||i=="2"||i=="3"||i=="4"||i=="5") {
    # record the judgment then increase n and play the next pair
    jrow <- data.frame(file1 = wavefile1,
                       file2 = wavefile2,
                       score = i)
    judgments <- rbind(judgments,jrow)
    replay <- FALSE
  } else {
    cat("Not a valid entry. Will replay the sound")
    replay <- TRUE
  }
}

fwrite(judgments,file="anne_similarity_judgments.csv",append=TRUE)
