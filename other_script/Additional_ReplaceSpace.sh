#!/bin/bash
# First, rename directories (important: do this top-down)
find . -depth -type d -name "* *" -execdir rename 's/ /_/g' "{}" \;
# Then, rename files
find . -type f -name "* *" -execdir rename 's/ /_/g' "{}" \;




