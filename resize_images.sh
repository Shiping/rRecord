#!/bin/bash

# Create directories for resized images if they don't exist
mkdir -p Images/screen/1320x2868
mkdir -p Images/screen/2064x2752

# Resize images to 1320x2868
for img in Images/screen/0{1,2,3}.jpg; do
    filename=$(basename "$img")
    magick "$img" -resize 1320x2868! "Images/screen/1320x2868/$filename"
done

# Resize images to 2064x2752
for img in Images/screen/0{1,2,3}.jpg; do
    filename=$(basename "$img")
    magick "$img" -resize 2064x2752! "Images/screen/2064x2752/$filename"
done

echo "Images have been resized successfully"
