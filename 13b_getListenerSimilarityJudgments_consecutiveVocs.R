library(tuneR)
library(audio)
library(data.table)

# Randomly select a sequence of consecutive clean baby vocalization clips.
# Get listener similarity judgment on a 3-point scale.

cat("Welcome!\n")

setwd("~/Documents/GitHub/IVFCR-UMAP")
rec_info <- fread("cleaning_metadata/recordings_cleaning_data.csv",header=TRUE,select=c("babyID","babyAge"))

# Get clips organized by baby, within each baby's list clips ar in order of onset time
baby_clip_lists <- list()
for (r in 1:nrow(rec_info)){
  b <- as.character(rec_info$babyID[r])
  a <- rec_info$babyAge[r]
  b_clip_info <- fread(paste("cleaning_metadata/best_clip_labels_",b,"_",a,".csv",sep=""))
  b_clip_info <- subset(b_clip_info,clean==TRUE)
  baby_list <- c()
  for (c in 1:nrow(b_clip_info)){
    f <- paste(b,"_",a,"_",b_clip_info$startSecond[c],"_",b_clip_info$endSecond[c],".wav",sep="")
    baby_list <- c(baby_list,f)
  }
  baby_clip_lists[[b]] <- baby_list
}

q <- FALSE
replay <- FALSE
n <- 0
judgments <- data.frame(baby <- character(),
                        file1 <- character(),
                        file2 <- character(),
                        score <- character())
while (!q){
  
  if (!replay){
    n <- n+1
    b <- as.character(sample(rec_info$babyID,1))
    i <- sample(1:(length(baby_clip_lists[[b]])-1),1)
    wavefile1 <- baby_clip_lists[[b]][i]
    wavefile2 <- baby_clip_lists[[b]][i+1]
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
      "1: Very similar\n",
      "2: Moderately different\n",
      "3: Very different\n",
      "r: Replay sound\n",
      "q: Quit.\n")
  
  i <- readline(prompt="")
  
  if (i=="q"){
    q <- TRUE
  } else if (i=="r"){
    replay <- TRUE
  } else if (i=="1"||i=="2"||i=="3") {
    # record the judgment then increase n and play the next pair
    jrow <- data.frame(baby = b,
                       file1 = wavefile1,
                       file2 = wavefile2,
                       score = i)
    judgments <- rbind(judgments,jrow)
    replay <- FALSE
  } else {
    cat("Not a valid entry. Will replay the sound")
    replay <- TRUE
  }
}

fwrite(judgments,file="anne_consecutive_vocalization_similarity.csv",append=TRUE)
