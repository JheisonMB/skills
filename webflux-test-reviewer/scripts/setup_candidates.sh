#!/bin/bash
# Setup candidate directories from GitHub repo URLs
# Usage: ./setup_candidates.sh <url1> <url2> <url3> ...
# Example: ./setup_candidates.sh https://github.com/user1/repo https://github.com/user2/repo

if [ $# -eq 0 ]; then
    echo "Usage: $0 <github-url-1> <github-url-2> ..."
    echo "Example: $0 https://github.com/juseruhe/franchises https://github.com/HamiltonDiaz/prueba-tecnica"
    exit 1
fi

for url in "$@"; do
    user=$(echo "$url" | cut -d'/' -f4)
    repo=$(basename "$url")
    echo "Setting up candidate: $user"
    mkdir -p "$user" && git clone "$url" "$user/$repo"
done

echo ""
echo "Done. Candidate directories created:"
ls -d */ 2>/dev/null | grep -v statement
