#!/bin/bash
# Usage: bash plink2f90_aligned.sh <plink_prefix>
# Example: bash plink2f90_aligned.sh merged_all_final

set -euo pipefail

prefix="$1"

# 1️⃣ export numeric additive genotypes
plink --cow --bfile "$prefix" --recode A --out "${prefix}_add"

# 2️⃣ build aligned f90 file
awk -v colstart=30 '
NR==1 { next } {                          # skip header
    id = $2                                # IID column
    geno = ""
    for (i = 7; i <= NF; i++) {
        val = $i
        if (val == "NA" || val == "") val = 0
        geno = geno "" val
    }
    # print ID left-aligned; genotype string begins at column 30
    printf "%-29s%s\n", id, geno
}' "${prefix}_add.raw" > "${prefix}_f90.txt"

# 3️⃣ clean up (optional)
rm "${prefix}_add.raw" "${prefix}_add.log"

echo "next setp map"
echo "✅ Created ${prefix}_f90.txt"
echo "   Format: [ID in cols 1–29][genotype string starts at col 30]"