#!/bin/bash

# Create CSV header (add path for SNP_Map.txt)
echo "folder,pathped,pathmap,pathSNPMap" > plink_files_report.csv

cd Scarichi

# For each University/Univ directory (non-recursive), check only top-level PLINK*
find . -maxdepth 1 -mindepth 1 -type d \( -name "*University*" -o -name "*Univ*" \) | while read -r univ_dir; do
    ped_dir="missing"
    map_dir="missing"

    # If needed, unzip only one PLINK*.zip directly inside the Univ folder (no recursion)
    # Preference: if a PLINK* dir already exists, do not unzip; otherwise unzip the first PLINK*.zip
    existing_plink=""
    for p in "$univ_dir"/PLINK*; do
        if [ -d "$p" ]; then
            existing_plink="$p"
            break
        fi
    done

    if [ -z "$existing_plink" ]; then
        first_zip=""
        for z in "$univ_dir"/PLINK*.zip; do
            [ -f "$z" ] || continue
            first_zip="$z"
            break
        done
        
        if [ -n "$first_zip" ]; then
            base=$(basename "$first_zip" .zip)
            dest="$univ_dir/$base"
            if [ ! -d "$dest" ]; then
                mkdir -p "$dest"
                unzip -q -n "$first_zip" -d "$dest"
            fi
        fi
    fi

    # Simplified: find a PLINK directory (or extract a PLINK*.zip) and pick files inside
    found_any=false

    # find an existing PLINK* directory
    plink_dir=""
    for d in "$univ_dir"/PLINK*; do
        [ -d "$d" ] || continue
        plink_dir="$d"
        break
    done

    # if no PLINK dir, look for a PLINK*.zip and extract first one (simple behavior)
    if [ -z "$plink_dir" ]; then
        first_zip=""
        for z in "$univ_dir"/PLINK*.zip; do
            [ -f "$z" ] || continue
            first_zip="$z"
            break
        done
        if [ -n "$first_zip" ]; then
            dest="$univ_dir/$(basename "$first_zip" .zip)"
            if [ ! -d "$dest" ]; then
                mkdir -p "$dest"
                unzip -q -n "$first_zip" -d "$dest"
            fi
            # if extraction created a PLINK* folder inside dest, use it; otherwise use dest
            subplink=$(find "$dest" -maxdepth 1 -type d -name "PLINK*" | head -n 1)
            if [ -n "$subplink" ]; then
                plink_dir="$subplink"
            else
                plink_dir="$dest"
            fi
        fi
    fi

    if [ -n "$plink_dir" ] && [ -d "$plink_dir" ]; then
        found_any=true

        # Find first .ped (prefer non-clean) and .map under the PLINK directory (simple, limited depth)
        # Prefer a non-clean PED (exclude *_clean.ped); if none, fall back to any .ped
        ped_file=$(find "$plink_dir" -maxdepth 2 -type f -name "*.ped" ! -name "*_clean.ped" | head -n 1)
        if [ -z "$ped_file" ]; then
            ped_file=$(find "$plink_dir" -maxdepth 2 -type f -name "*.ped" | head -n 1)
        fi
        # Prefer a non-clean MAP (exclude *_clean.map); if none, fall back to any .map
        map_file=$(find "$plink_dir" -maxdepth 2 -type f -name "*.map" ! -name "*_clean.map" | head -n 1)
        if [ -z "$map_file" ]; then
            map_file=$(find "$plink_dir" -maxdepth 2 -type f -name "*.map" | head -n 1)
        fi

        # Find SNP_Map.txt inside a SNP_Map folder under PLINK (preferred), otherwise any SNP_Map.txt
        snp_map_file=$(find "$plink_dir" -maxdepth 2 -type f -path "*/SNP_Map/*" -iname "SNP_Map.txt" | head -n 1)
        if [ -z "$snp_map_file" ]; then
            snp_map_file=$(find "$plink_dir" -maxdepth 3 -type f -iname "SNP_Map.txt" | head -n 1)
        fi
        # Also check for SNP_Map at the university root (some datasets store it there)
        if [ -z "$snp_map_file" ]; then
            if [ -f "$univ_dir/SNP_Map.txt" ]; then
                snp_map_file="$univ_dir/SNP_Map.txt"
            elif [ -f "$univ_dir/SNP_Map/SNP_Map.txt" ]; then
                snp_map_file="$univ_dir/SNP_Map/SNP_Map.txt"
            else
                # any txt inside university-level SNP_Map dir
                snp_map_file=$(find "$univ_dir/SNP_Map" -maxdepth 1 -type f -iname "*.txt" 2>/dev/null | head -n 1 || true)
            fi
        fi

        # If a non-clean PED was selected, remove any *_clean.ped to avoid ambiguity
        if [ -n "$ped_file" ] && [[ "$(basename "$ped_file")" != *_clean.ped ]]; then
            find "$plink_dir" -maxdepth 2 -type f -name "*_clean.ped" -print -delete 2>/dev/null || true
        fi

        # If a non-clean MAP was selected, remove any *_clean.map
        if [ -n "$map_file" ] && [[ "$(basename "$map_file")" != *_clean.map ]]; then
            find "$plink_dir" -maxdepth 2 -type f -name "*_clean.map" -print -delete 2>/dev/null || true
        fi

        ped_dir=${ped_file:-missing}
        map_dir=${map_file:-missing}
        snp_map_dir=${snp_map_file:-missing}

        echo "$univ_dir,$ped_dir,$map_dir,$snp_map_dir" >> ../plink_files_report.csv
    else
        echo "$univ_dir,missing,missing,missing" >> ../plink_files_report.csv
    fi
done

echo "Report has been created as plink_files_report.csv"

cd ..
