# This code was written with help from ChatGPT and GitHub Copilot. It extracts Wav2Vec2 embeddings from audio files
# and saves them into CSV files, one for each transformer layer of the model.

import torch
from transformers import Wav2Vec2Processor, Wav2Vec2Model
import os
import glob
import pandas as pd
from collections import defaultdict
from tqdm import tqdm
import csv
import soundfile as sf
import numpy as np
import gc

torch.set_num_threads(1)
torch.set_num_interop_threads(1)

processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
model = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base-960h", output_hidden_states=True)

full_ivfcr = True

def get_all_layer_embeddings(file_path):

    max_duration = 30 # in seconds

    # Open the sound file
    try:
        with sf.SoundFile(file_path,'r') as track:
            sr = track.samplerate

            # Calculate the number of frames to read
            max_frames = sr * max_duration

            # Read only the first max_frames (or fewer if the file is shorter)
            # The .read() function automatically handles seeking from the start if not specified otherwise
            speech = track.read(frames=max_frames, dtype='float32')

    except Exception as e:
        print(f"Error reading audio file {file_path}: {e}")
        return None

    # If stereo, convert to mono by averaging channels
    if speech.ndim > 1 and speech.shape[1] > 1:
        speech = np.mean(speech, axis=1)

    # Prepare input for model
    if sr != 16000:
        print(f"Warning: Audio file has sample rate {sr} Hz; 16 kHz expected.")
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

    # Open 12 CSV writers *once* per folder, append mode
    writers = {}
    for l in range(1,13): # 1 through 12 inclusive

        if full_ivfcr:
            output_csv = os.path.expanduser(
                f"~/Documents/IVFCR_LENA_Segments/w2v2embeddings/{id_age}_w2v2_layer{l}.csv"
            )
        else:
            output_csv = f"w2v2embeddings/{id_age}_w2v2_layer{l}.csv"
    
        # Write header if file doesn't exist yet
        write_header = not os.path.exists(output_csv)
        f = open(output_csv,"a",newline="")
        w = csv.writer(f)
        if write_header:
            w.writerow(["filename"] + [f"dim_{i}" for i in range(768)])
        writers[l] = (f,w)

    print(f"Opened CSV writers for layers: {list(writers.keys())}")

    for fname in tqdm(audio_files, desc=f"Processing {id_age}", unit="file"):

        path = os.path.join(audio_folder, fname)
        layer_map = get_all_layer_embeddings(path)

        for l in range(1,13):
            emb = layer_map.get(l)
            if emb is not None:
                writers[l][1].writerow([fname] + emb.tolist())

        # Free tensors
        del layer_map
        torch.cuda.empty_cache() if torch.cuda.is_available() else None
        gc.collect()

    # Close all CSV files
    for f, _ in writers.values():
        f.close()

        