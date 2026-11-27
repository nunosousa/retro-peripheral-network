#!/usr/bin/env bash
# Builds the PDF editions of the RPN specifications into docs/pdf/: one PDF per
# specification plus RPN-specification-set.pdf, which binds them together with
# the cross-document links resolved inside the volume.
#
# Requires pandoc and typst (tested with pandoc 3.7 and typst 0.15).
# Usage: tools/pdf/build-pdf.sh
set -euo pipefail

tools_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$tools_dir/../.." && pwd)"
cd "$root"

docs=(docs/SRS.md docs/ICD.md docs/SAD.md docs/PS.md docs/AFS.md)
set_name=RPN-specification-set
out_dir=docs/pdf
work_dir=build/pdf

for tool in pandoc typst; do
  if ! command -v "$tool" >/dev/null; then
    echo "error: $tool is not installed or not in PATH" >&2
    exit 1
  fi
done

# Links to repository files that are not published as PDFs point to GitHub.
remote="$(git remote get-url origin 2>/dev/null || true)"
branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)"
case "$remote" in
  git@github.com:*) repo="https://github.com/${remote#git@github.com:}" ;;
  https://github.com/*) repo="$remote" ;;
  *) repo="" ;;
esac
export RPN_REPO_URL="${repo:+${repo%.git}/blob/${branch#origin/}}"
export RPN_PDF_DOCS="${docs[*]}"

mkdir -p "$out_dir" "$work_dir"

build() {
  local name="$1"
  shift
  pandoc --from "$tools_dir/rpn-reader.lua" --to typst --standalone \
    --template "$tools_dir/rpn-template.typst" \
    --output "$work_dir/$name.typ" "$@"
  typst compile --root "$root" --ignore-system-fonts \
    "$work_dir/$name.typ" "$out_dir/$name.pdf"
  echo "  $out_dir/$name.pdf"
}

echo "Building PDFs with $(pandoc --version | head -n 1) and $(typst --version)"
for doc in "${docs[@]}"; do
  build "$(basename "$doc" .md)" "$doc"
done
build "$set_name" "${docs[@]}"
