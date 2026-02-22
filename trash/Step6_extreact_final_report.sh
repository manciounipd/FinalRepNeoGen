#!/bin/bash
mkdir -p Reggiana_FinalReport

awk  '{print $2}' merged_plink/Reggiana.fam  > ids.txt
ID_FILE="ids.txt"

find . -type f -wholename "*/Univ*/*FinalReport.txt" | while read -r DATA_FILE; do

            BASE=$(basename $DATA_FILE)
            printf "%s,%s" "$breed" "$BASE"
            tmp="${BASE%"_FinalReport.txt"}"
            
            mkdir -p ${breed}
            OUTPUT_FILE_1="${breed}/"$tmp"FinalReport.txt"
            OUTPUT_FILE_2="${breed}/"$tmp"DNAReport.txt"
            # Count matches from line 6 to end
            MATCH_COUNT=$(tail -n +6 "$DATA_FILE" | grep -F -f ids.txt | awk '{print $2}' | uniq | sort | wc -l )
           # echo $MATCH_COUNT
    
            if [ "$MATCH_COUNT" -gt 0 ]; then
                OldDir="$(basename "$(dirname "$DATA_FILE")" )"
                # Extract first 7 lines
                head -n 10 "$DATA_FILE" > "$OUTPUT_FILE_1"
                # Append lines matching IDs from line 6 onwards
                tail -n +10 "$DATA_FILE" | grep -F -f ids.txt  >> "$OUTPUT_FILE_1"
                
                # anche dna report
                tmpx=$(echo $BASE | sed 's/FinalReport/DNAReport/')
                old=$(echo $tmpx | sed 's/txt/zip/')
                new=$(echo $tmpx | sed 's/txt/csv/')
                
                unzip -o "$OldDir""/""$old" -d "$OldDir/"
                find "$OldDir" -depth -name "* *" -exec bash -c 'f="$1"; mv "$f" "${f// /_}"' _ {} \;

                # Then process your new file
                head -n 3 "$OldDir/$new" >> "$OUTPUT_FILE_2"
                tail -n +4 "$OldDir/$new" | grep -F -f ids.txt >> "$OUTPUT_FILE_2"

            
                printf ",%s\n" "$MATCH_COUNT"
               # echo "Copia anche la mappa"
                cp  $OldDir"/SNP_Map.txt" "${breed}/"$tmp"_SnpMap.txt"
            else
                printf ",0\n"
            fi
    done
done 



rclone copy merged_plink "EnricoUnipd:Genotipi_Neogen_Reggiana" --include "Reggiana*"
#rclone copy "Reggiana_FinalReport" "EnricoUnipd:Genotipi_Neogen_Reggiana" --include "*_only_Regg_FinalReport.txt"
rclone copy  Reggiana_FinalReport EnricoUnipd/Genotipi_Neogen_Reggiana


##### Stessa cosa grey alpine ...

mkdir -p "GrigioAlpina_FinalReport"

awk  '$1=="Grey" {print $2}' merged_plink/merged.fam  > ids.txt
ID_FILE="ids.txt"
DATA_FILE="./University_of_Padova-Roberto_Mantovani_BOVG100V1_20250303/University_of_Padova-Roberto_Mantovani_BOVG100V1_20250303_FinalReport.txt"

# Loop through all *FinalReport.txt files recursively
find . -type f -name "*FinalReport.txt" | while read -r DATA_FILE; do
    echo "--->"
    
    BASE=$(basename $DATA_FILE)
    #echo $BASE
    tmp="${BASE%"_FinalReport.txt"}"
    OUTPUT_FILE="GrigioAlpina_FinalReport/"$tmp"_only_GrigioAlpina_FinalReport.txt"
    #echo $OUTPUT_FILE
    # Count matches from line 6 to end
    MATCH_COUNT=$(tail -n +6 "$DATA_FILE" | grep -F -f "$ID_FILE" | awk '{print $2}' | uniq | sort | wc -l )
    echo $MATCH_COUNT
    
    if [ "$MATCH_COUNT" -gt 0 ]; then
        dir_="$(basename "$(dirname "$DATA_FILE")" )"
        # Extract first 7 lines
        head -n 9 "$DATA_FILE" > "$OUTPUT_FILE"
        # Append lines matching IDs from line 6 onwards
        tail -n +10 "$DATA_FILE" | grep -F -f "$ID_FILE" >> "$OUTPUT_FILE"
        echo "Extracted $MATCH_COUNT matching lines from $BASE → $OUTPUT_FILE"
        echo "Copia anche la mappa"
        cp $dir_"/SNP_Map.txt" "GrigioAlpina_FinalReport/"$tmp"_SnpMap.txt"
    else
        echo "No matches found in $BASE, skipping."
    fi
done


#===========================================================================
### fai valdostante
#==========================================================================

awk  '{print $2}' File_Fix/Breed/Valdostana/*.fam  > ids.txt
ID_FILE="ids.txt"

mkdir ValdoFinalRep


# Loop through all *FinalReport.txt files recursively
find . -type f -name "*FinalReport.txt" | while read -r DATA_FILE; do
    echo "##################################################################"
    BASE=$(basename $DATA_FILE)
    #echo $BASE

    tmp="${BASE%"_FinalReport.txt"}"
    OUTPUT_FILE="ValdoFinalRep/"$tmp"_Valdo_FinalReport.txt"
    #echo $OUTPUT_FILE
    # Count matches from line 6 to end
    MATCH_COUNT=$(tail -n +6 "$DATA_FILE" | grep -F -f "$ID_FILE" | awk '{print $2}' | uniq | sort | wc -l )
    echo $MATCH_COUNT
    
    if [ "$MATCH_COUNT" -gt 0 ]; then
        # Extract first 7 lines
        head -n 9 "$DATA_FILE" > "$OUTPUT_FILE"
        # Append lines matching IDs from line 6 onwards
        tail -n +10 "$DATA_FILE" | grep -F -f "$ID_FILE" >> "$OUTPUT_FILE"
        echo "Extracted $MATCH_COUNT matching lines from $BASE → $OUTPUT_FILE"
    else
        echo "No matches found in $BASE, skipping."
    fi
done


rclone copy merged_plink "EnricoUnipd:Genotipi_Neogen_Reggiana" --include "Reggiana*"
#rclone copy "Reggiana_FinalReport" "EnricoUnipd:Genotipi_Neogen_Reggiana" --include "*_only_Regg_FinalReport.txt"
rclone copy  Reggiana_FinalReport EnricoUnipd/Genotipi_Neogen_Reggiana

