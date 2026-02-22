import os
import csv

BASE_DIR = "/mnt/user_data/enrico/Genotipi/Neogen100k/Scarichi"

os.chdir(BASE_DIR)

rows = []

# Loop su ciascuna directory dentro BASE_DIR
for main_name in sorted(os.listdir(".")):
    main_dir_path = os.path.join(BASE_DIR, main_name)

    if not os.path.isdir(main_dir_path):
        continue

    found_plink = False

    # Cerca tutte le cartelle che iniziano con "PLINK" dentro la sottodirectory
    for plink_name in sorted(os.listdir(main_dir_path)):
        plink_dir = os.path.join(main_dir_path, plink_name)

        if not (os.path.isdir(plink_dir) and plink_name.upper().startswith("PLINK")):
            continue

        found_plink = True
        ped_file = "missing"

        # Cerca file .ped nella cartella PLINK trovata
        for fname in os.listdir(plink_dir):
            if fname.lower().endswith(".ped"):
                ped_file = os.path.splitext(fname)[0]
                break  # assume uno per directory

        # salva riga per la tabella
        rows.append(
            {
                "main_name": main_name,
                "PLINK_dir": plink_name,
                "file_types": ped_file,
            }
        )

    # Se non c'è nessuna cartella PLINK, aggiungi riga "missing"
    if not found_plink:
        rows.append(
            {
                "main_name": main_name,
                "PLINK_dir": "missing",
                "file_types": "missing",
            }
        )

# Scrive la tabella su CSV accanto allo script
script_dir = os.path.dirname(os.path.abspath(__file__))
out_path = os.path.join(script_dir, "resume_plink_info.csv")

with open(out_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["main_name", "PLINK_dir", "file_types"])
    writer.writeheader()
    writer.writerows(rows)

print("don3 ==> resume_plink_info.csv")