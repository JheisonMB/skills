# Changelog

## [2.1.0] - 2026-04-06

### Added
- **Harzing Publish or Perish integration**: Convert PoPCites.csv exports to ASReview format
- CSV conversion script (convert_popcites_to_asreview.py) with auto-column detection
- Workflow example: Export → Convert → Screen
- Improved troubleshooting section with conversion errors
- Direct links to ASReview (asreview.nl) and Harzing sites

### Improved
- Consolidated skill name: `asreview` (removed verbose "systematic-review" suffix)
- Better organization of CLI commands and flags
- Enhanced classifier recipes with use-case scenarios
- Clearer troubleshooting matrix
- Added key concepts section (Prior, AL Cycle, Feature Extractor, Classifier, Querier)

### Changed
- Renamed directory: asreview-systematic-review → asreview
- Updated all metadata and references

## [2.0.0] - 2026-04-03

### Added
- Core active learning framework documentation
- Key flags reference table
- CSV format specification
- Four typical workflows (simulate, lab, metrics, benchmarks)
- Classifier recipes (NB+TF-IDF, SVM+TF-IDF, RF+undersample, BERT+domain)
- Comprehensive troubleshooting guide
- Tips for reproducibility and optimization

### Improved
- Consolidated documentation (removed verbose descriptions)
- Better command structure and examples
- Enhanced error handling guidance

## [1.1.0] - 2026-03-31

### Added
- Initial Spanish documentation
- Usage guidelines for systematic reviews
- SYNERGY dataset reference

### Improved
- Enhanced examples with practical use cases

## [1.0.0] - 2026-03-14

### Added
- Initial ASReview skill implementation
- Command-line interface documentation
- Simulation mode guidance
- SYNERGY dataset information
- Example dataset for testing
- README and CHANGELOG
