#!/bin/bash 
DIR="./"

# Temporary merge list file
MERGE_LIST="merge_list.txt"

# Remove old list if exists
rm -f "$MERGE_LIST"

# Get all prefix names (*.bim → prefix before extension)
PREFIXES=($(ls *.bim | sed 's/\.bim//'))

# Check there are at least 2 datasets
if [ ${#PREFIXES[@]} -lt 2 ]; then
    echo "Need at least 2 PLINK datasets (.bed/.bim/.fam)."
    exit 1
fi

# First dataset becomes the base dataset
BASE=${PREFIXES[0]}
echo "Base dataset: $BASE"

# Add all other datasets to merge list
for ((i=1; i<${#PREFIXES[@]}; i++)); do
    echo "${PREFIXES[$i]}.bed ${PREFIXES[$i]}.bim ${PREFIXES[$i]}.fam" >> "$MERGE_LIST"
done

echo "Merge list created: $MERGE_LIST"

# Run PLINK merge
mkdir -p  merged
plink  --cow --bfile "$BASE" --merge-list "$MERGE_LIST" --make-bed --out merged/final

echo "Done. Output = merged.bed/bim/fam"
