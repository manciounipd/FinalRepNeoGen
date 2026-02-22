#!/bin/bash

cd  /mnt/user_data/enrico/Genotipi/Neogen100k/PlinkFromFinalRep/Breed

for i in $(ls)
do
    echo "------------------------------ "$i" ------------------------------"
    cd $i
    bash /home/enrico/Script/FixNeogen/merged.sh
    cd ..
done