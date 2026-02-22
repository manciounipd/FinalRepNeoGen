#!/bin/bash
set -euo pipefail

# Get the directory containing this script
script_dir="$(dirname "$(readlink -f "$0")")"

# Find all .bim files in current directory
mapfile -t bim_files < <(find . -maxdepth 1 -name "bin_*.bim" | sort)

if [ ${#bim_files[@]} -eq 0 ]; then
    echo "❌ No bin_*.bim files found in current directory."
    exit 1
fi

echo "Found ${#bim_files[@]} .bim files to check."
echo "Using ${bim_files[0]} as reference."

# Call check_consistency.sh with all found .bim files
"$script_dir/check_consistency.sh" "${bim_files[@]}"