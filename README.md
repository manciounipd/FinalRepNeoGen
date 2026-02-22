# FixNeogen - Pipeline orchestrata da `MAIN.sh`

Questo repository contiene una pipeline (bash + R) per:

- convertire in PLINK
- Creare un unico panello per razza
- ricostruire `FinalReport`/`DNAReport` per razza per poi inviare alle varie associazioni

La sequenza completa e' orchestrata da `MAIN.sh`.

## Flusso (`MAIN.sh`)

`MAIN.sh` esegue in ordine:

1. `Step1_Rename_Extract_Rename.sh`
2. `Step2_check_final_report.R`
3. `Step3_nuovo.R`
4. `Step4_divided_in_Breed.R`
5. `Step5_mergia_all.sh`
6. `Step6_buono_Extract_breed_final_report.sh`

Percorsi hardcoded in `MAIN.sh`:

- script: `/home/enrico/Script/FixNeogen`
- working dir: `/mnt/user_data/enrico/Genotipi/Neogen100k`

## Prerequisiti

Sistema:

- `bash`
- `unzip`
- `GNU parallel` (usato nello step 1)
- `plink` disponibile nel `PATH`
- `wc`, `awk`, `find`, `join`, `sort`

R packages (almeno):

- `data.table`
- `tidyverse`
- `readxl`
- `purrr` (normalmente incluso in `tidyverse`, ma usato esplicitamente nello step 4)

## Struttura attesa delle cartelle

Working root: `/mnt/user_data/enrico/Genotipi/Neogen100k`

Input/servizi principali:

- `Scarichi/` (zip Neogen e sottocartelle estratte dal sito Neogen \bold{Non Modificarle} !)
- `file_addizionali/campioni_ANAGA.xlsx`: serve perche la Grigio Alpina non ha la matricola ma un id 
- `file_addizionali/campioni_ANAGA.csv`: questo è il primo converito con `convert_campioniANAGA_xls_to_csv.R`
- `file_addizionali/Matricole_valdo_PNRR_UNIMI.xlsx`, serve perche le Matricole di milano non ha la matricola ma un id


Output principali:
Files:
- `resume_finalreport_info.csv`:  è un file che per ogni bacth mi indica: il map file il file rep
- `PlinkFromFinalRep/`: converti tutti i bacth in PLINK
- `PlinkFromFinalRep/Breed/`: sottocartella ma qua diviso per razza e poi metto tutto assieme 
- `Breed_Final_Report/`: final report diviso per razza, serve per mandarlo nelle varia associazione

## Descrizione step-by-step

### 1) `Step1_Rename_Extract_Rename.sh`

Lavora in `.../Neogen100k/Scarichi` e:

- rinomina file/cartelle con spazi (` ` -> `_`)
- estrae gli zip di primo livello in cartelle omonime
- rimuove gli zip di primo livello (`rm *.zip`)
- entra in ogni sottocartella ed estrae eventuali zip interni
- ripete la rinomina spazi -> underscore

Note:

- usa `set -euo pipefail`
- richiede `parallel`
- rimuove gli zip top-level dopo estrazione

### 2) `Step2_check_final_report.R`

Scansiona ogni cartella in `Scarichi/` e costruisce un riepilogo dei file `FinalReport` e `SNP_Map`.

Cosa fa:

- cerca `FinalReport*.txt` o `FinalReport*.zip`
- se trova solo zip, prova a estrarre
- segnala stati tipo:
  - `OK_TXT_PRESENT`
  - `OK_EXTRACTED`
  - `MISSING_FINALREPORT`
  - errori multipli (`ERROR_*`)
- cerca anche un file mappa (`SNP_Map*.txt` o `.zip`)

Output:

- `resume_finalreport_info.csv`: E'L'input file per step3
- `resume_finalreport_info<DATA>.csv` (con data corrente)

### 3) `Step3_nuovo.R`

Converte i `FinalReport` in dataset PLINK (`.bed/.bim/.fam`) usando `helper/convert_to_ped.R`.

Cosa fa:

- legge `../resume_finalreport_info.csv`
- per ogni batch:
  - converte `FinalReport + SNP_Map` in PLINK (`finaltoplink(...)`)
  - crea formato binario PLINK con `plink --make-bed`
  - aggiorna il `.fam` assegnando la razza (`FID`) in base a:
    - prefisso ID (`07`, `06`, `10`, `IT`)
    - file Excel ANAGA / UNIMI
- salva i file finali in `PlinkFromFinalRep/<batch>.bed|.bim|.fam`

Dipendenze dati aggiuntivi:

- `../file_addizionali/campioni_ANAGA.xlsx`
- `../file_addizionali/Matricole_valdo_PNRR_UNIMI.xlsx`
Questi perchè questo i campioni di questi gruppi non hanno le matricole ma hanno invece l'id.
Note:

- lo script termina con `quit()` subito dopo la pulizia dei temporanei
- usa `plink` piu' volte

### 4) `Step4_divided_in_Breed.R`

Lavora in `PlinkFromFinalRep/` e divide tutti i dataset per razza (`FID` del `.fam`).

Cosa fa:

- legge tutti i `.fam`
- crea `Breed/<razza>/`
- per ogni razza, genera un subset PLINK di ogni batch con `plink --keep`
- scrive un riepilogo:
  - `recap_fam.tsv`

Output:

- `PlinkFromFinalRep/Breed/<Razza>/*.{bed,bim,fam}`

Note importanti:

- lancia i comandi `plink` in background (`&`), quindi su dataset grandi conviene verificare che i processi siano terminati prima dello step 5

### 5) `Step5_mergia_all.sh` + `merged.sh`

Per ogni cartella razza in `PlinkFromFinalRep/Breed/`:

- entra nella cartella della razza
- esegue `merged.sh`

`merged.sh`:

- prende tutti i prefix dei dataset (`*.bim`)
- usa il primo come base
- crea `merge_list.txt`
- esegue merge PLINK:
  - output in `merged/final.{bed,bim,fam}`

Output:

- `PlinkFromFinalRep/Breed/<Razza>/merged/final.*`

### 6) `Step6_buono_Extract_breed_final_report.sh`

Ricostruisce i report originali filtrati per razza a partire dagli ID presenti nei `.fam` merged.

Cosa fa (per ogni razza):

- legge gli ID dagli `.fam` in `PlinkFromFinalRep/Breed/<Razza>/`
- per `Grigio` converte gli ID con `campioni_ANAGA.csv`
- scorre tutti i `Scarichi/Univ*/*FinalReport.txt`
- se trova animali della razza:
  - crea `Breed_Final_Report/<Razza>/<batch>FinalReport.txt`
  - crea `Breed_Final_Report/<Razza>/<batch>DNAReport.csv`
  - copia `SNP_Map.txt` come `<batch>_SnpMap.txt`
- se `DNAReport.zip` o `SNP_Map.zip` esistono ma i `.txt/.csv` mancano, prova a estrarli

Output:

- `Breed_Final_Report/<Razza>/...`

## Esecuzione

Eseguire la pipeline completa:

```bash
bash MAIN.sh
```

## Check consigliati dopo esecuzione

- Controllare merge per razza:

```bash
wc -l /mnt/user_data/enrico/Genotipi/Neogen100k/PlinkFromFinalRep/Breed/*/merged/*.fam
```

- Verificare presenza output finale:
  - `/mnt/user_data/enrico/Genotipi/Neogen100k/Breed_Final_Report/`
  - `/mnt/user_data/enrico/Genotipi/Neogen100k/resume_finalreport_info.csv`

## Limitazioni / note tecniche

- Molti percorsi sono hardcoded (sia in bash sia in R).
- La pipeline assume naming Neogen relativamente stabile (`FinalReport`, `DNAReport`, `SNP_Map`).
- `Step4_divided_in_Breed.R` avvia job `plink` in background: se il sistema e' lento, `Step5` potrebbe partire troppo presto.
- `MAIN.sh` contiene un commento iniziale (`@ next step do a reas me`) che non e' sintassi bash valida su sistemi rigorosi: se crea errore, trasformarlo in commento (`# ...`).

