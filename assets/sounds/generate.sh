#!/usr/bin/env bash
# Regenerates the four Randomix sound cues.
#
# They are synthesised rather than sampled so the repo carries no third-party
# audio: every cue is a short expression evaluated by ffmpeg's aevalsrc, faded
# and encoded to mono Ogg Vorbis (pw-play reads it through libsndfile).
#
#   ./generate.sh [output-dir]     default: ../../shell/assets/randomix
set -euo pipefail

out="${1:-$(cd "$(dirname "$0")/../.." && pwd)/shell/assets/randomix}"
mkdir -p "$out"

# name  duration  expression
cues=(
  # Rising chirp, like a wheel picking up speed.
  "spin 0.70 0.22*sin(2*PI*(400*t+600*t*t))"
  # One short blip for the coin.
  "flip 0.18 0.30*sin(2*PI*1000*t)*exp(-18*t)"
  # A rattle: a fast-decaying tick every 70 ms.
  "roll 0.42 0.25*sin(2*PI*500*t)*exp(-40*mod(t\\,0.07))"
  # Two-note chime for an answer landing.
  "answer 0.90 0.22*(sin(2*PI*660*t)*exp(-5*t)+0.7*sin(2*PI*990*t)*exp(-4*max(t-0.12\\,0)))"
)

for cue in "${cues[@]}"; do
  read -r name dur expr <<<"$cue"
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "aevalsrc='$expr':s=44100:d=$dur" \
    -af "afade=t=in:d=0.008,afade=t=out:st=$(awk "BEGIN{print $dur-0.05}"):d=0.05,volume=0.9" \
    -ac 1 -ar 44100 -c:a libvorbis -q:a 4 \
    "$out/$name.ogg"
  printf '%s: %s bytes\n' "$name.ogg" "$(stat -c%s "$out/$name.ogg")"
done
