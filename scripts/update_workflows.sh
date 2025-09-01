#!/bin/bash

# Script to update GitHub Actions workflows by replacing version tags with @master
# This script recursively finds all YAML files (.yml and .yaml) in the .github/workflows/ directory
# and uses sed to replace version tags in 'uses:' lines (e.g., @v1, @v2, @0.31.0) with @master

# Find all YAML files in .github/workflows/ recursively
find .github/workflows/ -name "*.yml" -o -name "*.yaml" | while read -r file; do
    # Use sed to replace version tags in 'uses:' lines
    # The sed command targets lines starting with 'uses:' (with optional whitespace)
    # and replaces @ followed by version patterns (v1, v2, 0.31.0, etc.) with @master
    sed -i '/^[[:space:]]*uses:/ s/@[v0-9.]\+/@master/g' "$file"
    # Print a message indicating the file has been updated
    echo "Updated $file"
done

# End of script