# Data CDN (Cloudflare R2)

The manifest, bundles and (later) boundary data are public, read-only files in an R2 bucket, served through Cloudflare's CDN on a custom domain. The app only ever reads from this domain; the publisher only ever writes to the bucket.

## Layout

```
https://<cdn-domain>/manifest.json                      short cache
https://<cdn-domain>/bundles/{municipality_id}/{n}.json  long cache, never overwritten
https://<cdn-domain>/boundaries/{prefecture}/{n}.json    long cache, never overwritten
https://<cdn-domain>/_smoke/...                          smoke-test files, safe to delete
```

## Cache policy

Caching follows the `Cache-Control` header stored on each object. `data/scripts/cdn_put.sh` sets it on upload:

| Class | Used for | Cache-Control | Effect |
| -- | -- | -- | -- |
| `immutable` | versioned bundles and boundaries | `public, max-age=31536000, immutable` | cached for a year at the edge and on the device |
| `short` | `manifest.json` | `public, max-age=60` | a new manifest is visible within about a minute |

Versioned files are cached forever, so the script refuses to overwrite an `immutable` key: a changed bundle always gets a new `bundle_version` and a new path.

Cloudflare doesn't cache `.json` by default, so the cache rule in step 5 below makes the CDN domain cacheable and tells it to follow the stored header.

## Setup (owner steps)

These need the Cloudflare account and the domain, so they're done once in the Cloudflare dashboard and on GitHub.

1. **Domain on Cloudflare.** The domain must be a zone in the same Cloudflare account (its nameservers point at Cloudflare). Choose a subdomain for data, for example `data.<your-domain>`.
2. **Enable R2.** R2 → Purchase/Enable. It asks for a payment method; usage stays inside the free tier (10 GB storage, 1M writes and 10M reads a month, no egress fees).
3. **Create the bucket.** R2 → Create bucket → name `binpal-data`, location hint **Asia-Pacific**. Leave public access through `r2.dev` **disabled**.
4. **Connect the custom domain.** Bucket → Settings → Custom Domains → Connect domain → `data.<your-domain>`. Cloudflare adds the DNS record and HTTPS certificate; wait until it shows Active.
5. **Cache rule.** Your domain → Caching → Cache Rules → Create rule:
   * Name: `BinPal data`
   * When: Hostname equals `data.<your-domain>`
   * Cache eligibility: **Eligible for cache**
   * Edge TTL: **Use cache-control header if present, bypass cache if not**
   * Browser TTL: **Respect origin TTL**
   * Deploy.
6. **Optional clean-up rule.** Bucket → Settings → Object lifecycle rules → Add: prefix `_smoke/`, delete objects after 1 day.
7. **Scoped API token for CI.** R2 → Manage API tokens → Create API token:
   * Permissions: **Object Read & Write**
   * Specify bucket: **binpal-data only**
   * TTL: forever
   * Create, then copy the **Access Key ID** and **Secret Access Key** (shown once). The **Account ID** is in the R2 overview sidebar.
8. **GitHub secrets and variables.** From the repo root (each `secret set` prompts for the value, so it doesn't end up in your shell history):

   ```sh
   gh secret set R2_ACCOUNT_ID
   gh secret set R2_ACCESS_KEY_ID
   gh secret set R2_SECRET_ACCESS_KEY
   gh variable set R2_BUCKET --body binpal-data
   gh variable set CDN_BASE_URL --body https://data.<your-domain>
   ```

## Smoke test

`.github/workflows/cdn-smoke.yml` runs only when started by hand (no quota used otherwise). It:

1. uploads the example bundle to `_smoke/bundles/14100/<run>.json` and fetches it twice over HTTPS through the CDN, checking the checksum, the `immutable` header and that the second request is a cache `HIT`;
2. uploads a manifest, warms the cache, uploads a new version and polls until the CDN serves it, failing after 5 minutes.

```sh
gh workflow run cdn-smoke.yml
gh run watch
```

The workflow must be on `main` before it can be started. Results are in the run summary.

## Uploading by hand

```sh
export R2_ACCOUNT_ID=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... R2_BUCKET=binpal-data
data/scripts/cdn_put.sh data/schema/examples/manifest.json manifest.json short
```
