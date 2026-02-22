#!/bin/bash
set -euo pipefail
DIR="/mnt/user_data/enrico/Genotipi/Neogen100k/Scarichi"

find "$DIR" -depth -name "* *" -print0 |
     parallel -0 -j 2 mv {} {= s: :_:g =}


cd $DIR

for f in *.zip; do
    # Rimuove solo l'ultimo .zip, anche se ci sono spazi
    folder="${f%.zip}"

    echo "----------------------------------------"
    echo "Processing: \"$f\""
    echo "Extracting into: \"$folder\""

    # Estrae solo se la cartella non esiste
    if [ ! -d "$folder" ]; then
        unzip "$f" -d "$folder"
    else
        echo "Skipping extraction — folder \"$folder\" already exists."
    fi

    # Mostra il contenuto
    echo "Contents of \"$folder\":"
    ls -al "$folder"
    echo "----------------------------------------"
    echo
done

rm *.zip


# Loop through all items in the current directory and list their names
for f in *; do
    [ -e "$f" ] || continue
    echo "$f"
    cd $f
    for ff in *.zip; do
        [ -e "$ff" ] || continue
        unzip -n "$ff"
    done
    cd ..
done



find "$DIR" -depth -name "* *" -print0 |
     parallel -0 -j 2 mv {} {= s: :_:g =}


