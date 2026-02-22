#!/bin/bash
set -euo pipefail

# Simple script: compute per-animal call rate from .ped files listed in plink_files_report.csv
# Does NOT call PLINK. Call rate = proportion of non-missing genotypes per individual.
# Output: callrate_list.csv with columns animal_id,batch,call_rate

OUT_FILE="callrate_list.csv"
echo "animal_id,batch,call_rate" > "$OUT_FILE"

if [ ! -f plink_files_report.csv ]; then
    echo "ERROR: plink_files_report.csv not found in current directory." >&2
    exit 1
fi

# Read CSV (skip header). Fields: folder,pathped,pathmap
tail -n +2 plink_files_report.csv | while IFS=',' read -r batch pathped pathmap || [ -n "$batch" ]; do
    # Trim surrounding quotes/spaces if present
    batch="${batch#\"}"
    batch="${batch%\"}"
    batch="${batch## }"
    batch="${batch%% }"
    pathped="${pathped#\"}"
    pathped="${pathped%\"}"
    pathped="${pathped## }"
    pathped="${pathped%% }"

    ped_to_use=""

    # If pathped is provided and file exists, use it
    if [ "$pathped" != "missing" ] && [ -f "$pathped" ]; then
        ped_to_use="$pathped"
    else
        # try to find a .ped file under the batch folder
        if [ -d "$batch" ]; then
            ped_to_use=$(find "$batch" -maxdepth 2 -type f -name "*.ped" | head -n 1 || true)
        fi
    fi

    if [ -z "$ped_to_use" ]; then
        echo "Skipping batch '$batch': no .ped file found." >&2
        continue
    fi

    # Process the .ped file: for each line, compute call rate
    # PLINK .ped: first 6 fields are FID IID PID MID Sex Phenotype; rest are 2 alleles per marker
    awk -v batch="$batch" '
    {
        if(NF<=6) next;
        total_pairs = (NF - 6) / 2;
        if(total_pairs<=0) next;
        missing = 0;
        # iterate over genotype allele pairsn
        for(i=7;i<=NF;i+=2){
            a = $i; b = $(i+1);
            if(a=="0" || b=="0") missing++;
        }
        call_rate = 1 - (missing / total_pairs);
        if(call_rate<0) call_rate=0;
        printf("%s,%s,%.6f\n", $2, batch, call_rate);
    }
    ' "$ped_to_use" >> "$OUT_FILE"

done

echo "Finished. Output written to $OUT_FILE"
