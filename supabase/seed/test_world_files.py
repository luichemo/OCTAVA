"""Adds the files for the test world (supabase/seed/test_world.sql):

* one or two synthesized riffs per musician as audio clips (the first is the
  card's featured song),
* an AI avatar each, through the generate-avatar Edge Function,
* each band's clip, and recordings for some songs.

Signs in as each test musician, so everything goes through the app's normal
storage and database rules. The accounts need a temporary password first
(see "Test data" in CLAUDE.md); pass it in the OCTAVA_TEST_PASSWORD
environment variable, never on the command line or in a file.

Usage: OCTAVA_TEST_PASSWORD=... python -I supabase/seed/test_world_files.py <supabase_url> <publishable_key>

With --remove at the end it deletes all 12 test accounts instead, through the
delete-account Edge Function: their files go, and bands left empty are
deleted with their files too. That's the way to remove the test world.
"""
import io
import json
import math
import os
import random
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import wave

URL, KEY = sys.argv[1], sys.argv[2]
PASSWORD = os.environ['OCTAVA_TEST_PASSWORD']
RATE = 22050
STEP = 0.25  # seconds per note

# Each musician: their clips as (title, voice, notes). Notes are MIDI numbers
# (None = rest); drums use 1 = kick, 2 = snare, 3 = hi-hat, 0 = rest.
PEOPLE = {
    'nika': [('Odd-time groove', 'drums', [1, 3, 2, 3, 1, 1, 2, 3, 1, 3, 2, 0]),
             ('Fill practice', 'drums', [1, 2, 2, 1, 2, 2, 1, 1, 2, 2, 2, 2])],
    'mariam': [('Neo-soul melody', 'voice', [67, 70, 72, 74, 72, 70, 67, None, 65, 67, 70, None])],
    'luka': [('Garage riff', 'guitar', [52, 52, 55, 57, 52, 52, 59, 57, 52, 52, 55, 50]),
             ('Bass line idea', 'bass', [40, None, 40, 43, 45, None, 47, 45])],
    'tamar': [('Rhodes chords', 'keys', [60, 64, 67, 71, 62, 65, 69, 72, 64, 67, 71, 74])],
    'giorgi': [('Punk bass', 'bass', [40, 40, 40, 40, 43, 43, 45, 45, 40, 40, 38, 38])],
    'ana': [('Violin theme', 'strings', [74, 76, 77, 79, 77, 76, 74, 72, 74, None, 69, None])],
    'dato': [('Sax hook', 'reed', [62, 65, 67, 69, 67, 65, 62, None, 60, 62, 65, None])],
    'salome': [('City-pop hook', 'voice', [72, 74, 76, 79, 76, 74, 72, 69, 72, 74, None, None])],
    'levan': [('Club loop', 'synth', [48, None, 55, 48, 51, None, 55, 58, 48, None, 55, 60])],
    'nino': [('Cello line', 'strings', [48, 50, 52, 53, 55, 53, 52, 50, 48, None, 43, None])],
    'saba': [('First riff', 'guitar', [52, 55, 57, 52, 55, 58, 57, None])],
    'elene': [('Rock beat', 'drums', [1, 3, 2, 3, 1, 1, 2, 3])],
}

# Band clips and song recordings, uploaded by the band's first member.
BANDS = {
    '00000000-0000-4000-8000-000000000c01': ('nika', [
        ('drums', [1, 3, 2, 3, 1, 1, 2, 3] * 3),
        ('bass', [40, 40, 43, 45, 40, 40, 47, 45] * 3),
        ('guitar', [52, 55, 57, 59, 52, 55, 59, 57] * 3),
    ], ['Concrete Summer', 'Rustaveli at 3am']),
    '00000000-0000-4000-8000-000000000c02': ('ana', [
        ('strings', [74, 76, 77, 79, 77, 76, 74, 72] * 3),
        ('cello', [43, None, 47, None, 48, None, 45, None] * 3),
        ('keys', [55, 59, 62, 66, 57, 60, 64, 67] * 3),
    ], ['Mtatsminda Lullaby', 'Suliko (arrangement)']),
    '00000000-0000-4000-8000-000000000c03': ('dato', [
        ('drums', [1, 3, 2, 3, 1, 3, 2, 3] * 3),
        ('reed', [62, 65, 67, 69, 67, 65, 62, None] * 3),
        ('guitar', [55, None, 55, 58, 55, None, 53, 55] * 3),
    ], ['Sunday Funk']),
}


def freq(m):
    return 440 * 2 ** ((m - 69) / 12)


def note(voice, n):
    """One STEP of audio as floats in -1..1."""
    count = int(RATE * STEP)
    out = []
    for i in range(count):
        t = i / RATE
        if voice == 'drums':
            if n == 1:  # kick: a falling sine
                f = 45 + 105 * math.exp(-t * 25)
                v = math.sin(2 * math.pi * f * t) * math.exp(-t * 14) * 0.9
            elif n == 2:  # snare: a noise burst
                v = (random.random() * 2 - 1) * math.exp(-t * 22) * 0.5
            elif n == 3:  # hi-hat: short, quiet noise
                v = (random.random() * 2 - 1) * math.exp(-t * 80) * 0.25
            else:
                v = 0.0
        elif n is None:
            v = 0.0
        else:
            f = freq(n)
            attack = min(1.0, t / 0.01)
            if voice == 'bass':  # soft saw
                v = sum(math.sin(2 * math.pi * f * k * t) / k for k in range(1, 6)) * 0.35
                v *= attack * math.exp(-t * 4)
            elif voice == 'guitar':  # plucked, a little overdriven
                raw = sum(math.sin(2 * math.pi * f * k * t) / (k * k) for k in range(1, 8))
                v = math.tanh(raw * 2.2) * 0.4 * attack * math.exp(-t * 6)
            elif voice == 'keys':  # electric-piano-ish
                v = (math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2 * t))
                v *= 0.35 * attack * math.exp(-t * 3)
            elif voice in ('strings', 'cello'):  # bowed: saw with vibrato
                fv = f * (1 + 0.006 * math.sin(2 * math.pi * 5.5 * t))
                v = sum(math.sin(2 * math.pi * fv * k * t) / k for k in range(1, 7)) * 0.22
                v *= min(1.0, t / 0.06)
            elif voice == 'reed':  # sax-like: odd harmonics
                v = sum(math.sin(2 * math.pi * f * k * t) / k for k in (1, 3, 5, 7)) * 0.3
                v *= min(1.0, t / 0.03) * (0.8 + 0.2 * math.exp(-t * 3))
            elif voice == 'synth':  # square-ish lead over a kick on the beat
                v = math.tanh(math.sin(2 * math.pi * f * t) * 3) * 0.25 * attack
            else:  # voice: sine with vibrato
                fv = f * (1 + 0.008 * math.sin(2 * math.pi * 5 * t))
                v = math.sin(2 * math.pi * fv * t) * 0.45 * min(1.0, t / 0.04)
        out.append(v)
    return out


def render(parts, repeats=2):
    """Mixes [(voice, notes)] into mono 16-bit WAV bytes; returns (bytes, seconds)."""
    tracks = []
    for voice, notes in parts:
        samples = []
        for _ in range(repeats):
            for n in notes:
                samples.extend(note(voice, n))
        tracks.append(samples)
    length = max(len(t) for t in tracks)
    mix = [sum(t[i] for t in tracks if i < len(t)) / max(1, len(tracks) ** 0.5) for i in range(length)]
    peak = max(1e-9, max(abs(s) for s in mix))
    buf = io.BytesIO()
    with wave.open(buf, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(s / peak * 0.9 * 32767)) for s in mix))
    return buf.getvalue(), max(1, math.ceil(length / RATE))


def call(method, path, token=None, body=None, raw=None, content_type='application/json', prefer=None):
    headers = {'apikey': KEY, 'Authorization': f'Bearer {token or KEY}'}
    data = None
    if raw is not None:
        data, headers['Content-Type'] = raw, content_type
    elif body is not None:
        data, headers['Content-Type'] = json.dumps(body).encode(), 'application/json'
    if prefer:
        headers['Prefer'] = prefer
    req = urllib.request.Request(URL + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            text = r.read().decode() or 'null'
            return r.status, json.loads(text) if text.strip()[:1] in '[{"n' else text
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def sign_in(name):
    status, data = call('POST', '/auth/v1/token?grant_type=password',
                        body={'email': f'{name}@test.octava.invalid', 'password': PASSWORD})
    if status != 200:
        raise SystemExit(f'sign-in failed for {name}: {status} {data}')
    return data['access_token'], data['user']['id']


def upload(bucket, path, data, token):
    status, body = call('POST', f'/storage/v1/object/{bucket}/{path}', token, raw=data,
                        content_type='audio/wav')
    if status not in (200, 201):
        raise SystemExit(f'upload to {bucket}/{path} failed: {status} {body}')


def main():
    random.seed(7)
    stamp = int(time.time() * 1000)
    for name, clips in PEOPLE.items():
        token, uid = sign_in(name)
        first = None
        for k, (title, voice, notes) in enumerate(clips):
            data, seconds = render([(voice, notes)], repeats=3)
            path = f'{uid}/{stamp + k}.wav'
            upload('clips', path, data, token)
            status, rows = call('POST', '/rest/v1/audio_clips', token, prefer='return=representation',
                                body={'profile_id': uid, 'storage_path': path, 'title': title,
                                      'duration_seconds': seconds})
            if status not in (200, 201):
                raise SystemExit(f'clip row for {name} failed: {status} {rows}')
            first = first or rows[0]['id']
        call('PATCH', f'/rest/v1/profiles?id=eq.{uid}', token, body={'featured_clip_id': first})
        status, avatar = call('POST', '/functions/v1/generate-avatar', token, body={})
        print(f'{name}: {len(clips)} clip(s), avatar {"ok" if status == 200 else f"skipped ({status})"}')

    for band, (who, parts, songs) in BANDS.items():
        token, _ = sign_in(who)
        data, seconds = render(parts, repeats=1)
        path = f'{band}/{stamp}.wav'
        upload('band-clips', path, data, token)
        status, body = call('POST', '/rest/v1/rpc/set_band_clip', token,
                            body={'band': band, 'path': path, 'seconds': seconds})
        if status not in (200, 204):
            raise SystemExit(f'band clip for {band} failed: {status} {body}')
        for k, title in enumerate(songs):
            status, rows = call('GET', f'/rest/v1/songs?band_id=eq.{band}&title=eq.'
                                + urllib.parse.quote(title) + '&select=id', token)
            song = rows[0]['id']
            data, seconds = render(parts, repeats=2 + k)
            path = f'{band}/{stamp + 10 + k}.wav'
            upload('band-songs', path, data, token)
            call('PATCH', f'/rest/v1/songs?id=eq.{song}', token,
                 body={'recording_path': path, 'recording_seconds': seconds})
        print(f'band {band[-3:]}: clip and {len(songs)} recording(s)')


def remove():
    for name in PEOPLE:
        try:
            token, _ = sign_in(name)
        except SystemExit as e:
            print(f'{name}: {e}')
            continue
        status, body = call('POST', '/functions/v1/delete-account', token, body={})
        print(f'{name}: {"deleted" if status == 200 else f"failed ({status}) {body}"}')


remove() if '--remove' in sys.argv else main()
