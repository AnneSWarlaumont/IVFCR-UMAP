# This code was written with help from ChatGPT and GitHub Copilot. It extracts Wav2Vec2 embeddings from audio files
# and saves them into CSV files, one for each transformer layer of the model.

import soundfile as sf
import torch
from transformers import Wav2Vec2Processor, Wav2Vec2Model
import os
import glob
import pandas as pd
from collections import defaultdict
from tqdm import tqdm

torch.set_num_threads(1)
torch.set_num_interop_threads(1)

processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
model = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base-960h", output_hidden_states=True)

full_ivfcr = True

def get_all_layer_embeddings(file_path):
    speech, sr = sf.read(file_path)
    
    # If the wav is longer than 30 s, truncate
    max_samples = int(sr * 30)
    if len(speech) > max_samples:
        speech = speech[:max_samples]

    # Prepare input for model
    input_values = processor(speech.squeeze(), sampling_rate=16000, return_tensors="pt").input_values
    with torch.no_grad():
        outputs = model(input_values)
    layer_map = {}
    for idx, embeddings in enumerate(outputs.hidden_states):
        pooled = torch.mean(embeddings, dim=1)[0]
        pooled = pooled.cpu().numpy()
        layer_map[idx] = pooled
    return layer_map

if full_ivfcr:
    audio_folders = glob.glob(os.path.expanduser('~/Documents/IVFCR_LENA_Segments/*segWavFiles'))
else:
    audio_folders = glob.glob('cleaning_metadata/best_clip_labels_*_wavFiles')
    # example element: "cleaning_metadata/best_clip_labels_196_272_wavFiles"

for audio_folder in audio_folders:

    print(audio_folder)

    layer_buffers = defaultdict(list)

    if full_ivfcr:
        id_age = audio_folder.split("/")[-1].split("_segWavFiles")[0]
    else:
        id_age = audio_folder.split("best_clip_labels_")[1].split("_wavFiles")[0]

    if id_age == "0009_000302" or id_age == "0437_000902" or id_age=="0196_000607" or id_age=="0223_000600" or id_age=="0583_010604" or id_age=="0656_000302" or id_age=="0009_000901" or id_age=="384B_000903" or id_age=="0932_000602b" or id_age=="0840_010603" or id_age=="0973_000304":
        continue

    # Process all audio files
    audio_files = [f for f in os.listdir(audio_folder) if f.endswith(".wav")]
    for fname in tqdm(audio_files, desc=f"Processing {id_age}", unit="file"):

        path = os.path.join(audio_folder, fname)
        layer_map = get_all_layer_embeddings(path)

        for l in range(1,13):

            emb = layer_map.get(l)
            if emb is None:
                continue

            row = {"filename": fname}
            for i, v in enumerate(emb):
                row[f"dim_{i}"] = float(v)

            layer_buffers[l].append(row)

    for l, rows in layer_buffers.items():
        if full_ivfcr:
            output_csv = os.path.expanduser("~/Documents/IVFCR_LENA_Segments/w2v2embeddings/" + id_age + "_w2v2_layer" + str(l) + ".csv")
        else:
            output_csv = "w2v2embeddings/" + id_age + "_w2v2_layer" + str(l) + ".csv"
        df = pd.DataFrame(rows)
        df.to_csv(output_csv,index=False)

        