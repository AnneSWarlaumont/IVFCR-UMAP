# This code is largely from ChatGPT

import soundfile as sf
import torch
import torchaudio
from transformers import Wav2Vec2Processor, Wav2Vec2Model
import os
import numpy as np
import pandas as pd

processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
model = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base-960h", output_hidden_states=True)

audio_folder = "cleaning_metadata/best_clip_labels_196_272_wavFiles"
output_csv = "w2v2embeddings/196_272_w2v2.csv"

def get_wav2vec2_embedding(file_path):
    # Load audio
    speech, sr = sf.read(file_path)
    # Prepare input for model
    input_values = processor(speech.squeeze(), sampling_rate=16000, return_tensors="pt").input_values
    with torch.no_grad():
        outputs = model(input_values)
    # Use top transformer layer (most contextual)
    embeddings = outputs.hidden_states[-1]
    # Pool over time to get one vector per clip
    pooled_embedding = torch.mean(embeddings, dim=1).squeeze().numpy()
    return pooled_embedding

# Process all audio files
first = True
for fname in os.listdir(audio_folder):
    if not fname.endswith(".wav"):
        continue
    path = os.path.join(audio_folder, fname)
    emb = get_wav2vec2_embedding(path)
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