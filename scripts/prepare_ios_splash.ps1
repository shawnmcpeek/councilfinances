# Create the iOS launch image directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "ios/Runner/Assets.xcassets/LaunchImage.imageset"

# Copy the knights3.png to the iOS assets directory
Copy-Item -Path "assets/images/knights3.png" -Destination "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png"
Copy-Item -Path "assets/images/knights3.png" -Destination "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png"
Copy-Item -Path "assets/images/knights3.png" -Destination "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png" 