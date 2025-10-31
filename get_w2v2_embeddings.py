# This code was written with help from ChatGPT and GitHub Copilot. It extracts Wav2Vec2 embeddings from audio files
# and saves them into CSV files, one for each transformer layer of the model.

import soundfile as sf
import torch
from transformers import Wav2Vec2Processor, Wav2Vec2Model
import os
import glob
import pandas as pd

processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
model = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base-960h", output_hidden_states=True)

full_ivfcr = True

def get_wav2vec2_embedding(file_path,layer):
    # Load audio
    speech, sr = sf.read(file_path)
    # Prepare input for model
    input_values = processor(speech.squeeze(), sampling_rate=16000, return_tensors="pt").input_values
    with torch.no_grad():
        outputs = model(input_values)
    # Use top transformer layer (most contextual)
    embeddings = outputs.hidden_states[layer]
    # Pool over time to get one vector per clip
    pooled_embedding = torch.mean(embeddings, dim=1).squeeze().numpy()
    return pooled_embedding

if full_ivfcr:
    audio_folders = glob.glob(os.path.expanduser('~/Documents/IVFCR_LENA_Segments/*segWavFiles'))
else:
    audio_folders = glob.glob('cleaning_metadata/best_clip_labels_*_wavFiles')
    # example element: "cleaning_metadata/best_clip_labels_196_272_wavFiles"

for audio_folder in audio_folders:

    print(audio_folder)

    if full_ivfcr:
        id_age = audio_folder.split("/")[-1].split("_segWavFiles")[0]
    else:
        id_age = audio_folder.split("best_clip_labels_")[1].split("_wavFiles")[0]

    # if id_age == "0009_000302":
    #     continue

    for l in range(1,13):

        if full_ivfcr:
            output_csv = os.path.expanduser("~/Documents/IVFCR_LENA_Segments/w2v2embeddings/" + id_age + "_w2v2_layer" + str(l) + ".csv")
            print(output_csv)
        else:
            output_csv = "w2v2embeddings/" + id_age + "_w2v2_layer" + str(l) + ".csv"

        # Process all audio files
        first = True
        for fname in os.listdir(audio_folder):
            if not fname.endswith(".wav"):
                continue
            path = os.path.join(audio_folder, fname)
            emb = get_wav2vec2_embedding(path,l)
            row = {"filename": fname}
            for i, v in enumerate(emb):
                row[f"dim_{i}"] = float(v)
            df_row = pd.DataFrame([row])

            if first:
                df_row.to_csv(output_csv, index=False, mode="w")
                first = False
            else:
                df_row.to_csv(output_csv, index=False, header=False, mode="a")
            print(f"Appended {fname} to {output_csv}")