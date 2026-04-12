# External Data Policy — BirdCLEF 2026

Date: 2026-04-05

## Allowed Strategic Sources

- Xeno-Canto
- prior BirdCLEF editions if the competition rules allow their use
- iNaturalist-derived audio only if explicitly permitted by the competition rules

## Required Logging

Every external-data experiment must log:

- exact source dataset
- acquisition date
- license or rule basis for use
- filtering logic
- class mapping logic
- whether the data was used for pretraining, finetuning, pseudo-labeling, or calibration

## Guardrails

- Do not mix external data into the main training pool without a separate ablation.
- Do not claim an external-data gain until there is at least one no-external-data baseline under the same backbone family.
- If a source has weak label quality, treat it as pseudo-label-grade evidence, not clean supervision.

## Minimum Comparison

For every external-data claim, compare:

1. in-domain only
2. in-domain + external
3. in-domain + filtered external

If the filtered version wins, the result is interpreted as a data-quality gain, not only a scale gain.
