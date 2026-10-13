"""Synthesizes a short riff for each test musician and uploads it as their clip.

Signs in as each test account (they get a temporary password first, removed
again afterwards) so uploads go through the normal storage and database rules.
Run after test_musicians.sql. Give the accounts a temporary password first
(see "Test data" in CLAUDE.md) and clear it again afterwards.
Usage: python -I supabase/seed/test_riffs.py <supabase_url> <publishable_key> <temp_password>
"""
import io
import json
import math
import random
import struct
import sys
import urllib.request
import wave

URL, KEY, PASSWORD = sys.argv[1], sys.argv[2], sys.argv[3]
RATE = 22050
STEP = 0.25  # seconds per note
REPEATS = 3  # the 8-note riff plays three times: 6 seconds

# Same riffs as the prototype. Drums: 1 = kick, 2 = snare, 0 = rest.
MUSICIANS = {
    'nika': ('drums', [1, 1, 2, 0, 1, 1, 2, 2]),
    'mariam': ('bass', [40, None, 52, 40, 43, 45, None, 47]),
    'luka': ('vocals', [64, 67, 69, 67, 64, 62, 64, None]),
    'tamar': ('keys', [60, 64, 67, 71, 72, 71, 67, 64]),
    'giorgi': ('drums', [1, 1, 1, 2, 1, 1, 1, 2]),
    'ana': ('vocals', [67, 69, 71, 74, 71, 69, 67, 64]),
    'dato': ('bass', [38, None, 38, 45, 43, None, 41, 40]),
    'salome': ('keys', [72, 69, 65, 69, 72, 74, 72, 69]),
}


def freq(m):
    return 440 * 2 ** ((m - 69) / 12)


def note(instrument, n):
    """One STEP of audio as floats in -1..1."""
    count = int(RATE * STEP)
    out = []
    for i in range(count):
        t = i / RATE
        if instrument == 'drums':
            if n == 1:  # kick: falling sine
                f = 45 + 105 * math.exp(-t * 25)
                v = math.sin(2 * math.pi * f * t) * math.exp(-t * 14) * 0.9
            elif n == 2:  # snare: noise burst
                v = (random.random() * 2 - 1) * math.exp(-t * 22) * 0.5
            else:
                v = 0.0
        elif n is None:
            v = 0.0
        else:
            f = freq(n)
            env = min(1.0, t / 0.01) * math.exp(-t * 4)
            if instrument == 'bass':  # soft saw
                v = sum(math.sin(2 * math.pi * f * k * t) / k for k in range(1, 6)) * 0.35 * env
            elif instrument == 'vocals':  # sine with vibrato
                v = math.sin(2 * math.pi * f * t + 0.004 * f * math.sin(2 * math.pi * 5.5 * t)) * 0.3 * env
            else:  # keys: triangle-ish
                v = (math.sin(2 * math.pi * f * t) + math.sin(2 * math.pi * 3 * f * t) / 9) * 0.3 * env
        out.append(v)
    return out


def wav_bytes(instrument, riff):
    samples = []
    for _ in range(REPEATS):
        for n in riff:
            samples += note(instrument, n)
    buf = io.BytesIO()
    with wave.open(buf, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32000)) for s in samples))
    return buf.getvalue(), round(len(samples) / RATE)


def call(method, path, body=None, token=None, headers=None):
    h = {'apikey': KEY, 'Authorization': f'Bearer {token or KEY}'}
    h.update(headers or {})
    data = body if isinstance(body, (bytes, type(None))) else json.dumps(body).encode()
    if body is not None and not isinstance(body, bytes):
        h['Content-Type'] = 'application/json'
    req = urllib.request.Request(URL + path, data=data, method=method, headers=h)
    with urllib.request.urlopen(req) as r:
        text = r.read().decode()
        return json.loads(text) if text else None


random.seed(8)
for name, (instrument, riff) in MUSICIANS.items():
    session = call('POST', '/auth/v1/token?grant_type=password',
                   {'email': f'{name}@test.octava.invalid', 'password': PASSWORD})
    token, uid = session['access_token'], session['user']['id']
    audio, seconds = wav_bytes(instrument, riff)
    path = f'{uid}/riff.wav'
    call('POST', f'/storage/v1/object/clips/{path}', audio, token,
         {'Content-Type': 'audio/wav', 'x-upsert': 'true'})
    call('POST', '/rest/v1/audio_clips',
         {'profile_id': uid, 'storage_path': path, 'title': f'{name.capitalize()} riff', 'duration_seconds': seconds},
         token, {'Prefer': 'return=minimal'})
    print(f'{name}: {instrument}, {seconds}s, {len(audio) // 1024} KB uploaded')
