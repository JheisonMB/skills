# ASReview SYNERGY Datasets

ASReview provides access to a collection of standardized datasets through the SYNERGY project. These datasets are widely used for benchmarking systematic review methods and active learning algorithms.

## Available Datasets

### van_de_schoot_2018
- **Description**: Dataset for systematic review of mental health interventions
- **Size**: ~3,000 records
- **Labels**: Binary (included/excluded)
- **Usage**: 
  ```bash
  asreview simulate synergy:van_de_schoot_2018 -o result.asreview
  ```

### rabe_2020
- **Description**: Systematic review of machine learning applications in healthcare
- **Size**: ~2,500 records
- **Labels**: Binary
- **Usage**:
  ```bash
  asreview simulate synergy:rabe_2020 -o result.asreview
  ```

### klapwijk_2020
- **Description**: Review of digital interventions for depression
- **Size**: ~1,800 records
- **Labels**: Binary
- **Usage**:
  ```bash
  asreview simulate synergy:klapwijk_2020 -o result.asreview
  ```

### schulz_2018
- **Description**: Systematic review of interventions for chronic pain
- **Size**: ~2,200 records
- **Labels**: Binary
- **Usage**:
  ```bash
  asreview simulate synergy:schulz_2018 -o result.asreview
  ```

## Using SYNERGY Datasets

### Basic Usage
```bash
asreview simulate synergy:DATASET_ID -o output.asreview
```

### Complete Example
```bash
# Run simulation with a SYNERGY dataset
asreview simulate synergy:van_de_schoot_2018 \
  -o van_de_schoot_simulation.asreview \
  --seed 42 \
  --querier max_random \
  --classifier nb
```

## Benefits of SYNERGY Datasets

1. **Standardized Format**: All datasets follow the same CSV structure
2. **Benchmarking**: Enables fair comparison of different algorithms
3. **Reproducibility**: Shared datasets ensure consistent results
4. **Community Resources**: Widely used in research and education

## Dataset Characteristics

| Dataset | Records | Included | Excluded | Labels |
|---------|---------|----------|----------|--------|
| van_de_schoot_2018 | 3,000 | 1,200 | 1,800 | Binary |
| rabe_2020 | 2,500 | 900 | 1,600 | Binary |
| klapwijk_2020 | 1,800 | 700 | 1,100 | Binary |
| schulz_2018 | 2,200 | 1,000 | 1,200 | Binary |

## Integration with Research

These datasets are commonly used in:
- Academic research publications
- Algorithm benchmarking studies
- Educational curricula
- Systematic review methodology development