# ASReview Skill

This is a skill for using the ASReview tool for systematic reviews and active learning. ASReview automates the screening of titles and abstracts in systematic reviews using active learning algorithms.

## Overview

ASReview is a powerful tool that helps researchers automate the systematic review process by using machine learning algorithms to identify relevant literature. This skill provides comprehensive guidance for using ASReview's command-line interface and simulation capabilities.

## Features

- **Simulation Mode**: Run automated systematic reviews with various algorithms
- **Command Line Interface**: Access to all ASReview functionality via CLI
- **Dataset Management**: Support for custom datasets and SYNERGY datasets
- **Algorithm Selection**: Multiple querier strategies, classifiers, and feature extractors
- **Reproducibility**: Seed-based randomization for consistent results

## Installation

This skill works with ASReview installed in your environment:

```bash
pip install asreview
```

## Usage

The skill activates when working with systematic reviews, active learning, or literature screening automation. It provides guidance on:

- Running simulations with different parameters
- Using SYNERGY datasets for benchmarking
- Managing prior knowledge in simulations
- Optimizing performance and reproducibility
- Integrating with other research workflows

## Skill Structure

```
asreview-skill/
├── SKILL.md              # Main skill documentation
├── README.md             # This file
├── references/           # Additional documentation
│   ├── USAGE_GUIDELINES.md  # Usage patterns and best practices
│   ├── SYNERGY_DATASETS.md  # Information about SYNERGY datasets
│   └── EXAMPLES.md        # Practical examples
└── assets/               # Example files
    └── example_dataset.csv # Sample dataset for testing
```

## When to Use

This skill should be activated when:
- Conducting systematic reviews with large datasets
- Automating literature screening processes
- Using active learning algorithms for systematic reviews
- Running simulations to evaluate review performance
- Working with text data for scientific literature screening

## Resources

- [ASReview Documentation](https://asreview.readthedocs.io/)
- [ASReview GitHub Repository](https://github.com/asreview/asreview)
- [SYNERGY Dataset Collection](https://github.com/asreview/synergy-datasets)