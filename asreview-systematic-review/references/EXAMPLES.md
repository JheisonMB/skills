# ASReview Usage Examples

## Basic Simulation Examples

### Simple Dataset Simulation
```bash
# Run basic simulation with default parameters
asreview simulate my_literature.csv -o simulation_result.asreview
```

### Simulation with Custom Parameters
```bash
# Run simulation with specific algorithm choices
asreview simulate my_literature.csv \
  -o optimized_simulation.asreview \
  -q max_random \
  -c svm \
  -e tfidf \
  --seed 12345
```

## Advanced Examples

### Using SYNERGY Dataset
```bash
# Benchmark different algorithms on a standard dataset
asreview simulate synergy:van_de_schoot_2018 \
  -o benchmark_result.asreview \
  --seed 42
```

### With Prior Knowledge
```bash
# Include 5 prior included and 10 prior excluded records
asreview simulate my_dataset.csv \
  --n-prior-included 5 \
  --n-prior-excluded 10 \
  -o prior_informed.asreview
```

### Performance Evaluation
```bash
# Run multiple simulations with different seeds for robustness
for seed in 1 2 3 4 5; do
  asreview simulate my_dataset.csv \
    -o simulation_${seed}.asreview \
    --seed $seed
done
```

## Workflow Examples

### Complete Review Process
```bash
#!/bin/bash
# 1. Initial simulation
asreview simulate my_dataset.csv \
  -o initial.asreview \
  --seed 42

# 2. Test different algorithms
asreview simulate my_dataset.csv \
  -o nb_simulation.asreview \
  -c nb

asreview simulate my_dataset.csv \
  -o svm_simulation.asreview \
  -c svm

# 3. Compare results
echo "Comparing algorithms:"
echo "Naive Bayes: $(asreview stats nb_simulation.asreview)"
echo "SVM: $(asreview stats svm_simulation.asreview)"
```

### Large Dataset Management
```bash
# For very large datasets, limit simulation length
asreview simulate large_dataset.csv \
  -o limited_simulation.asreview \
  --n-stop 100 \
  --seed 42
```

## Error Handling Examples

### Dataset Validation
```bash
# Check if dataset is valid before simulation
head -n 10 my_dataset.csv  # Preview dataset
# Ensure proper CSV format with title, abstract, label columns
```

### Reproducibility Check
```bash
# Run same simulation twice to verify reproducibility
asreview simulate my_dataset.csv -o run1.asreview --seed 42
asreview simulate my_dataset.csv -o run2.asreview --seed 42
# Results should be identical
```

## Integration Examples

### With Python Scripting
```python
import subprocess

def run_asreview_simulation(dataset_path, output_path, seed=42):
    cmd = [
        'asreview', 'simulate', dataset_path,
        '-o', output_path,
        '--seed', str(seed)
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode == 0

# Usage
success = run_asreview_simulation('my_data.csv', 'result.asreview')
```

### Batch Processing
```bash
#!/bin/bash
# Process multiple datasets
datasets=("dataset1.csv" "dataset2.csv" "dataset3.csv")

for dataset in "${datasets[@]}"; do
  echo "Processing $dataset..."
  asreview simulate "$dataset" -o "${dataset%.csv}_result.asreview" --seed 42
done
```

## Visualization and Analysis

### Extract Metrics
```bash
# Get simulation statistics
asreview stats my_simulation.asreview

# Export results for further analysis
asreview export my_simulation.asreview -o results.csv
```

## Best Practice Examples

### Proper Documentation
```bash
# Document your simulation parameters
asreview simulate my_dataset.csv \
  -o documented_simulation.asreview \
  --querier max_random \
  --classifier nb \
  --feature-extractor tfidf \
  --seed 42 \
  --n-prior-included 5 \
  --n-prior-excluded 10
```

### Version Control
```bash
# Keep track of ASReview versions
asreview --version

# Save command for reproducibility
echo "asreview simulate dataset.csv -o result.asreview --seed 42" > command_log.txt
```