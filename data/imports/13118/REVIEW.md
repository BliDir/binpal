# Arakawa import review

Checked by the coding agent on 12 November 2026. Prepared for review in the DAI-563 PR; not a claim of human approval or release readiness.

## Completed source and mapping checks

- Queried the official Tokyo CKAN API, selected the newer standard-format package (`…0014`), and verified its resource URL and CC-BY-4.0 licence. The older `…0002` catalog entry is a separate legacy dataset and is not imported.
- Downloaded the complete standard CSV: 223 distinct, nonempty IDs, all municipality code `131181` / 荒川区. The check digit is validated before converting to bundle municipality ID `13118`.
- Mapped the seven distinct published classifications explicitly. No published category is dropped or guessed; `その他` remains `other` rather than being assigned a normal collection day.
- Kept all original caution, fee type, fee value, fee notes and remarks in Japanese instructions. Numeric fee values are kept as published, without inferring units. English instructions include those fields, including size-dependent charges and unspecified fees.
- Prepared English item names, kana and aliases for every row; retained size/material distinctions in names. Reviewed the complete set of 88 distinct notes while preparing English instructions. The committed text is agent-authored and still requires human bilingual review.
- Checked dangerous-item translations specifically: gas cartridges and aerosols retain the prohibition on puncturing; needles retain pharmacy return instructions; batteries retain terminal insulation and separate collection routes; sharp objects retain wrapping and 危険 labels.
- Verified e-Stat area code and the three calendar patterns against the official collection page. Did not generalize block-specific recycling schedules to the whole chome.
- The importer validates the output using the existing schema and relationship validator. Tests cover other municipality codes, encodings, quoted multiline CSV, metadata drift, changed fees/notes, missing translations and preservation of reviewed output on refresh failure.

## Required before release

1. Human bilingual review of all 223 names/instructions and source classifications. Some source rows list battery-containing electronics under non-burnable waste while also mentioning special collection. Check the current ward guidance for embedded rechargeable batteries, phones and small appliances before promoting this snapshot; do not treat catalog conformance as a freshness guarantee.
2. Confirm fee freshness and the source website terms applicable to the separately transcribed collection-day facts.
3. Select actual rollout coverage. Resolve block/material-specific recycling schedules rather than inventing chome-wide calendars. Add other areas, holiday exceptions and the Tokyo boundary package as appropriate.
4. Confirm effective dates. Replace provisional `verified_at` dates only after the person check required by the bundle schema. Rebuild, validate and explicitly promote the reviewed candidate to `data/municipalities/13118/` when rollout is authorized.

The publisher only reads `data/municipalities/*/bundle.json`. This candidate stays in `data/imports/13118/`; it cannot be published accidentally by the existing workflow.
