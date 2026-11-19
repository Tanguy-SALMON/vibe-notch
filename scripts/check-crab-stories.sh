#!/bin/bash
# Checks that every crab story file is registered in CrabStoryCatalog.all (and vice versa).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRAB_DIR="$(dirname "$SCRIPT_DIR")/Notchd/UI/Crab"

# `static let name = CrabStory(` in the story files
declared=$(grep -rhoE 'static let [A-Za-z0-9_]+ = CrabStory\(' "$CRAB_DIR/Stories" | awk '{print $3}' | sort)
# `.name,` lines in the catalogue
listed=$(grep -oE '^[[:space:]]+\.[A-Za-z0-9_]+,' "$CRAB_DIR/Core/CrabStoryCatalog.swift" | tr -d ' .,' | sort)
files=$(find "$CRAB_DIR/Stories" -name 'Story*.swift' | wc -l | tr -d ' ')

missing=$(comm -23 <(echo "$declared") <(echo "$listed"))
unknown=$(comm -13 <(echo "$declared") <(echo "$listed"))

status=0
if [ -n "$missing" ]; then
    echo "Not listed in CrabStoryCatalog.all:"
    echo "$missing" | sed 's/^/  ./'
    status=1
fi
if [ -n "$unknown" ]; then
    echo "Listed in CrabStoryCatalog.all but not declared in Stories/:"
    echo "$unknown" | sed 's/^/  ./'
    status=1
fi
if [ "$files" != "$(echo "$declared" | grep -c .)" ]; then
    echo "Story files ($files) and story declarations ($(echo "$declared" | grep -c .)) differ: one story per file."
    status=1
fi

[ $status -eq 0 ] && echo "OK: $files story files, all listed in CrabStoryCatalog.all"
exit $status
