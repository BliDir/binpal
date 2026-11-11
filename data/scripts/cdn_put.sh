#!/usr/bin/env bash
# Upload one file to the R2 bucket with the right cache headers.
#
# Usage: data/scripts/cdn_put.sh <local-file> <key> <immutable|short>
#
#   immutable  versioned files (bundles, boundaries): cached for a year.
#              The key must never be reused, so the upload is refused if
#              the key already exists.
#   short      files that change in place (manifest.json): cached 60 s.
#
# Needs: R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET.
set -euo pipefail

file=${1:?local file}
key=${2:?object key, e.g. bundles/14100/1.json}
class=${3:?immutable or short}

: "${R2_ACCOUNT_ID:?}" "${R2_ACCESS_KEY_ID:?}" "${R2_SECRET_ACCESS_KEY:?}" "${R2_BUCKET:?}"

case "$class" in
  immutable) cache_control="public, max-age=31536000, immutable" ;;
  short) cache_control="public, max-age=60" ;;
  *) echo "class must be immutable or short" >&2; exit 2 ;;
esac

case "$key" in
  *.json) content_type="application/json" ;;
  *.geojson) content_type="application/geo+json" ;;
  *) content_type="application/octet-stream" ;;
esac

export AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=auto
# R2 does not need the newer default checksum headers from aws-cli.
export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
# R2_ENDPOINT overrides the endpoint for local testing.
endpoint="${R2_ENDPOINT:-https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com}"

if [ "$class" = immutable ] &&
  aws s3api head-object --endpoint-url "$endpoint" --bucket "$R2_BUCKET" --key "$key" >/dev/null 2>&1; then
  echo "refusing to overwrite immutable object $key" >&2
  exit 1
fi

aws s3 cp "$file" "s3://${R2_BUCKET}/${key}" \
  --endpoint-url "$endpoint" \
  --cache-control "$cache_control" \
  --content-type "$content_type" \
  --only-show-errors

echo "uploaded $key ($class)"
