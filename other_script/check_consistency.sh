#!/bin/bash
# Usage: bash check_bim_consistency.sh *.bim
# Example: bash check_bim_consistency.sh panel*.bim

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 file1.bim file2.bim [file3.bim ...]"
  exit 1
fi

ref="$1"
shift
tmpdir="bim_check_tmp"
mkdir -p "$tmpdir"

echo "🔍 Reference BIM: $ref"
awk '{print $2,$1,$4,$5,$6}' "$ref" | sort -k1,1 > "$tmpdir/ref.txt"

for f in "$@"; do
  name=$(basename "$f" .bim)
  echo "📂 Checking $name ..."
  awk '{print $2,$1,$4,$5,$6}' "$f" | sort -k1,1 > "$tmpdir/${name}.txt"

  join -1 1 -2 1 "$tmpdir/ref.txt" "$tmpdir/${name}.txt" > "$tmpdir/join_${name}.txt" || true

  total=$(wc -l < "$tmpdir/join_${name}.txt")
  diffpos=$(awk '$3!=$8 || $2!=$7' "$tmpdir/join_${name}.txt" | wc -l)
  diffallele=$(awk '($4$5 != $9$10) && !($4$5=="AT"&&$9$10=="TA") && !($4$5=="TA"&&$9$10=="AT") && !($4$5=="CG"&&$9$10=="GC") && !($4$5=="GC"&&$9$10=="CG")' "$tmpdir/join_${name}.txt" | wc -l)
  flips=$(awk '($4$5=="AT"&&$9$10=="TA")||($4$5=="TA"&&$9$10=="AT")||($4$5=="CG"&&$9$10=="GC")||($4$5=="GC"&&$9$10=="CG")' "$tmpdir/join_${name}.txt" | wc -l)

  echo "  ➤ Total common SNPs: $total"
  echo "  ⚠️  Different position or chromosome: $diffpos"
  echo "  ⚠️  Different alleles (non-complementary): $diffallele"
  echo "  🔄 Potential strand flips: $flips"

  if [ "$diffallele" -gt 0 ] || [ "$diffpos" -gt 0 ]; then
    echo "  ❌ Inconsistencies found. See $tmpdir/join_${name}.txt"
  else
    echo "  ✅ OK: alleles and positions consistent with $ref"
  fi
  echo ""
done

echo "📁 Detailed comparison files saved in: $tmpdir/"
