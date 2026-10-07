# ASReview Usage Guidelines

## Getting Started

1. **Install ASReview**:
   ```bash
   pip install asreview
   ```

2. **Verify Installation**:
   ```bash
   asreview --version
   asreview --help
   ```

3. **Prepare Your Dataset**:
   - CSV format with columns: title, abstract, label
   - UTF-8 encoding
   - Properly formatted text data

## Dataset Format Requirements

### Required Columns
- `title` - Document titles
- `abstract` - Document abstracts
- `label` - Binary labels (0=excluded, 1=included)

### Example Dataset Structure
```csv
title,abstract,label
"Machine Learning in Healthcare","This paper explores...",1
"Data Privacy Issues","Research on...",0
```

## Common Workflows

### Workflow 1: Quick Simulation
```bash
# Simple simulation with default parameters
asreview simulate my_dataset.csv -o result.asreview
```

### Workflow 2: Parameter Tuning
```bash
# Test different algorithms
asreview simulate my_dataset.csv -c nb -o nb_result.asreview
asreview simulate my_dataset.csv -c svm -o svm_result.asreview
```

### Workflow 3: With Prior Knowledge
```bash
# Include prior knowledge for better results
asreview simulate my_dataset.csv \
  --n-prior-included 5 \
  --n-prior-excluded 10 \
  -o prior_result.asreview
```

## Performance Optimization

### Memory Management
- For large datasets, consider using `--n-stop` to limit iterations
- Monitor system resources during long-running simulations
- Use appropriate data types in your CSV files

### Reproducibility
- Always use `--seed` for consistent results
- Document all command-line parameters used
- Save simulation outputs for comparison

## Advanced Features

### Custom Querier Strategies
- `max`: Maximum uncertainty sampling
- `max_random`: Maximum with random tie-breaking
- `random`: Random sampling

### Classifier Options
- `nb`: Naive Bayes
- `svm`: Support Vector Machine
- `rf`: Random Forest
- `lr`: Logistic Regression

### Feature Extractors
- `tfidf`: Term Frequency-Inverse Document Frequency
- `word2vec`: Word embeddings
- `bert`: BERT embeddings (requires additional setup)