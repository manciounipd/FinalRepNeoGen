#!/bin/bash
LOCAL="/mnt/user_data/enrico/Genotipi/Scarico_Neogen/Scarichi/Breed/Reggiana"
REMOTE="drive:backup/data"

rclone copy -P "$LOCAL" "$REMOTE"

