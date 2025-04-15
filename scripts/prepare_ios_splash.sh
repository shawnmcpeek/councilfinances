#!/bin/bash

# Create the iOS launch image directory if it doesn't exist
mkdir -p ios/Runner/Assets.xcassets/LaunchImage.imageset

# Copy the knights3.png to the iOS assets directory
cp assets/images/knights3.png ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png
cp assets/images/knights3.png ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png
cp assets/images/knights3.png ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png 