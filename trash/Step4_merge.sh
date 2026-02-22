#!/bin/bash

set -euo pipefail

# ------------------------------------------------------------
# Stage 1: Prepare input files and convert to binary
# ------------------------------------------------------------
cd Scarico

outdir="all_merged"
mkdir -p "$outdir"

# directory of this script (so we can call sibling scripts reliably)
script_dir="$(dirname "$(readlink -f "$0")")"

# absolute path to the input CSV (so we can reference it after cd)
report_csv_abs="$(readlink -f ../plink_files_report.csv)"
report_base_dir="$(dirname "$report_csv_abs")"

echo "Collecting valid PED/MAP entries..."

merge_pairs_file="$outdir/merge_pairs.tsv"
merge_pairs_abs="$(readlink -f "$merge_pairs_file")"

# TSV columns: folder<TAB>ped_path<TAB>map_path[\toptional snp-map]
awk -F',' 'NR>1 && $2!="missing" && $3!="missing" {print $1"\t"$2"\t"$3"\t"$4}' "$report_csv_abs" > "$merge_pairs_file"

idx=0
: > "$outdir/merge_list.txt"
: > "$outdir/prefix_list.txt"


# merge_pairs_file now: folder<TAB>ped_path<TAB>map_path[\toptional snp_map_path]

while IFS=$'\t' read -r folder ped_path map_path snp_map_path; do
  idx=$((idx + 1))
  # sanitize folder basename to safe filename (replace non-alnum with _)
  folder_base=$(basename "$folder")
  safe_name=$(echo "$folder_base" | tr -c '[:alnum:]._-' '_')
  prefix="${safe_name}_${idx}"

  ped_abs=$(readlink -f "${ped_path}")
  map_abs=$(readlink -f "${map_path}")
  ln -sf "${ped_abs}" "${outdir}/${prefix}.ped"
  ln -sf "${map_abs}" "${outdir}/${prefix}.map"

  # record prefix list and merge list (skip first for merge_list.txt as PLINK expects)
  echo "$prefix" >> "$outdir/prefix_list.txt"
  if [ "$idx" -gt 1 ]; then
    echo "${prefix}.ped ${prefix}.map" >> "${outdir}/merge_list.txt"
  fi
done < "$merge_pairs_file"

# SNP map will be auto-detected per prefix based on PED location


cd "$outdir"

echo "Converting PED/MAP to binary (BED/BIM/FAM)..."

: > log
: > convert_fail_prefixes.txt
: > prefix_list.tmp

while read -r prefix; do
  if ! plink --cow --file "$prefix" --make-bed --real-ref-alleles --out "$prefix" >> log 2>&1; then
    echo "PLINK failed on $prefix (see $outdir/log)"
    # skip this prefix (don't add to temporary list)
    echo "$prefix" >> convert_fail_prefixes.txt
  else
    # conversion succeeded, keep this prefix
    echo "$prefix" >> prefix_list.tmp
  fi
done < prefix_list.txt



mappe_reference="../../mappe_reference/GGP_Bov_100K_HTS_20040701_A1.csv"

awk -F ',' 'NR>7 {print $2,$10,$11}'  $mappe_reference | awk 'NR>1 && NF==3' > ref.map

awk -F',' 'NR>7 {gsub(/\[|\]/,"",$4); split($4,a,"/"); print $2,a[1],a[2]}'  $mappe_reference  \
                | awk 'NR>1 && NF==3' > ref.all


awk '{print $1":"$2":"$3":"$4, $2, $3}' ref.map > ref.all.sync



while read -r PREFIX; do
  plink --cow \
      --bfile "${PREFIX}" \
      --extract <(awk '{print $1}' ref.map ) \
      --update-map ref.map 3 1 \
      --update-chr ref.map 2 1 \
      --make-bed \
      --out "${PREFIX}_update"
done < prefix_list.tmp



while read -r PREFIX; do

  awk '$5!="0" && $6!="0"' "${PREFIX}_update.bim"  | cut -f2 > valid_snps.txt
  echo $(wc -l  valid_snps.txt)
  plink2 --cow --bfile "${PREFIX}_update"  --extract valid_snps.txt   --make-bed --out tmp
  plink2 --cow --bfile tmp  --update-alleles ref.all.sync  --make-bed --out "${PREFIX}_update_final"

done < prefix_list.tmp



: > update_final_prefixes.txt
while read -r PREFIX; do
  if [[ -f "${PREFIX}_update_final.bed" && -f "${PREFIX}_update_final.bim" && -f "${PREFIX}_update_final.fam" ]]; then
    echo "${PREFIX}_update_final" >> update_final_prefixes.txt
  fi
done < prefix_list.tmp


first=$(head -n 1 update_final_prefixes.txt)
awk 'NR>1{print $0}' update_final_prefixes.txt > tmp

plink --cow  --bfile $first  --merge-list  tmp  --make-bed  --out merged

#
