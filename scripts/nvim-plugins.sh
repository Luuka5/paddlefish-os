#!/bin/sh
set -euo pipefail

# Vendor nvim plugins into the image, pinned by commit SHA.
#
# Plugins are installed system-wide under /usr/share/nvim/site/pack/<bucket>/
# start/<repo>, which nvim's built-in pack feature loads automatically - no
# plugin manager, no runtime network access. Updating a plugin means bumping
# its SHA in nvim-plugin-shas and rebuilding the image.

SHAS=/tmp/scripts/nvim-plugin-shas
PACKDIR=/usr/share/nvim/site/pack

[ -f "$SHAS" ] || { echo "missing $SHAS" >&2; exit 1; }
mkdir -p "$PACKDIR"

# name <sha> <url> per line
awk '$1 != "" && $1 !~ /^#/ { print }' "$SHAS" | while read -r name sha url; do
    dest="$PACKDIR/$name/start/$name"
    echo "vendoring $name @ $sha"

    # < /dev/null: git would otherwise consume the loop's stdin and abort early.
    git clone --quiet "$url" "$dest" < /dev/null
    git -C "$dest" checkout --quiet "$sha" < /dev/null

    got=$(git -C "$dest" rev-parse HEAD < /dev/null)
    if [ "$got" != "$sha" ]; then
        echo "SHA mismatch for $name: expected $sha, got $got" >&2
        exit 1
    fi

    rm -rf "$dest/.git"
    echo "  -> $dest @ $sha"
done

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5 /var/cache/ldconfig/aux-cache