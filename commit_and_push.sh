#!/bin/bash

# Navigate to the project directory
cd /Users/ameen/Documents/ScreenTimeRewards-Workspace

# Add all changes
echo "Adding all changes..."
git add .

# Commit changes
echo "Committing changes..."
git commit -m "Update entitlements configuration and bundle identifier for release"

# Push changes
echo "Pushing changes..."
git push

echo "Done!"