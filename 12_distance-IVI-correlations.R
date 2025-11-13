# For each recording, can look in best_clip_labels_<baby>_<agedays>.csv to 
# get start and end times of each clean clip (need to subset by the "clean"
# column). Can then look the clip up by wavFile in all_emb_scaled_layer<l>.csv
# where the convention is <baby>_<agedays>_<startsec>_<endsec>.wav, to get
# the embedding data. Or can look up the clip wavFile in each run's
# full_data_balanced_umap_projections.csv file, for either mfcc or w2v2 umaps,
# or in all_best_clips_babies_ages_and_spectral_data.csv for the 36 mfcc values.

# Then, get IVI-distance (or IVI-cosine) betas and their CIs, controlling for
# (1|ID).
# We can then see which metrics give the highest correlations with IVI.

# It may also be interesting to train an age classifier on mfcc, w2v2 or umap
# positions to see which shows the strongest association with age, and then
# use that feature.

# We could also look into pca vs umap.

# First things first though, perhaps just compare across w2v2 layers and mfccs,
# without UMAP or PCA. And focus on the IVI-distance beta