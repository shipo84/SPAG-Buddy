#!/usr/bin/env bash
# Uploads the app's content JSON to the public "content" storage bucket under the current content version,
# so iPads can download question updates without an App Store release.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
content="$here/../../SPAG Buddy/Resources/Content"
version="$(node -e "console.log(require(process.argv[1]).contentVersion)" "$content/manifest.json")"

for file in "$content"/*.json; do
  supabase storage cp "$file" "ss:///content/$version/$(basename "$file")" --experimental
done
echo "Uploaded content $version. Set CONTENT_BASE_URL to https://<project-ref>.supabase.co/storage/v1/object/public/content"
