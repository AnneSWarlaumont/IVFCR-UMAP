# Some files have no clean infant clips based on a modal rating == 1 criterion.
# Let's check interrater reliability and disregard raters with poor agreement,
# and see if that leads to more clips being identified as clean.
# Maybe some raters were much more conservative than others in giving a 1 rating.
# I will start by checking agreement with myself, listener id lplf, on the files
# I relabeled. If there are some listeners who never did files that I did, I can
# compare them to the listener who was most reliabile agains my own ratings
# (we'll want to consider both Cohen's kappa and number of files we both did;
# if someone has high cohen's kappa but that's only based on a small number of
# recordings we might not want to have them be the stand-in for me in judging
# other listeners. But let's see what the situation is.).

# Check which assignments I completed, and which listeners did or did not have
# overlap with mine. Can get this info. from completed_relabel_file_info.csv