#!/usr/bin/env bash
set -euo pipefail

IMAGE="moh.png"
if [[ ! -s "$IMAGE" ]]; then
  echo "ERROR: $IMAGE is missing or empty."
  exit 1
fi

before=$(stat -c%s "$IMAGE")
cp "$IMAGE" "$RUNNER_TEMP/moh-before.png"

sudo apt-get update -qq
sudo apt-get install -y -qq optipng

# OptiPNG performs lossless PNG recompression. Pixel colors and dimensions are preserved.
optipng -o7 -strip all "$IMAGE"

after=$(stat -c%s "$IMAGE")
echo "Home image size before: $before bytes"
echo "Home image size after:  $after bytes"
if (( after > before )); then
  cp "$RUNNER_TEMP/moh-before.png" "$IMAGE"
  echo "Optimization was larger; restored the original image."
  exit 0
fi

if (( after == before )); then
  echo "No lossless size improvement; original visual data retained."
  exit 0
fi

echo "Lossless reduction: $((before-after)) bytes"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add "$IMAGE"
if git diff --cached --quiet; then
  echo "No image changes to commit."
  exit 0
fi
git commit -m "Optimize home image losslessly"
git push
