# Enhanced Contribution Classification System

A comprehensive Python-based system for classifying campaign finance contributions using hybrid rule-based and machine learning approaches.

## Overview

This system enhances the existing contribution classification by:
- **Hybrid Classification**: Combines rule-based logic with machine learning
- **Gap Analysis**: Identifies unclassified contributions and improvement opportunities  
- **Category Discovery**: Uses clustering to discover new contribution patterns
- **Enhanced SQL Generation**: Creates improved classification functions for BigQuery
- **Comprehensive Reporting**: Generates detailed analysis reports and recommendations

## Project Structure

```
ContributionCategory/
├── main.py                          # Main execution script
├── contribution_classifier.py       # Core classification logic
├── config.py                       # Configuration settings
├── utils.py                        # Utility functions
├── requirements.txt                 # Python dependencies
├── README.md                       # This file
├── outputs/                        # Generated results
├── reports/                        # Analysis reports
└── models/                         # Saved ML models
```

## Installation

1. **Clone the repository and navigate to the ContributionCategory folder:**
   ```bash
   cd /Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure Google Cloud authentication:**
   ```bash
   # Set up authentication for BigQuery
   gcloud auth application-default login
   ```

4. **Update configuration (if needed):**
   - Edit `config.py` to adjust BigQuery settings, file paths, or classification parameters

## Usage

### Basic Usage

Run the complete analysis pipeline:
```bash
python main.py
```

### Advanced Options

Setup directories only:
```bash
python main.py --setup-only
```

Validate configuration:
```bash
python main.py --validate-config
```

### Using Individual Components

You can also use the classification system programmatically:

```python
from contribution_classifier import ContributionClassifier
from config import Config

# Initialize classifier
classifier = ContributionClassifier()

# Load data
data = classifier.load_data()

# Run classification
classified_data = classifier.classify_contributions(data)

# Analyze gaps
gap_analysis = classifier.analyze_gaps(classified_data)

# Train ML model
classifier.train_ml_classifier(classified_data)

# Generate enhanced classification
enhanced_data = classifier.enhanced_classify(classified_data)
```

## Output Files

The system generates several output files:

### 1. Enhanced Classification Results
- **File**: `outputs/enhanced_classification_YYYYMMDD_HHMMSS.csv`
- **Content**: Complete dataset with enhanced classifications
- **Columns**: All original data plus `enhanced_category`, `ml_category`, `confidence_score`

### 2. Analysis Reports
- **JSON Report**: `reports/analysis_report_YYYYMMDD_HHMMSS.json`
  - Detailed analysis results, data quality metrics, gap analysis
- **HTML Report**: `reports/classification_report_YYYYMMDD_HHMMSS.html`
  - User-friendly visual report with charts and recommendations

### 3. Enhanced SQL Function
- **File**: `outputs/enhanced_classification_function_YYYYMMDD_HHMMSS.sql`
- **Content**: Updated BigQuery SQL function with improved classification rules

### 4. Log File
- **File**: `classification_analysis.log`
- **Content**: Detailed execution logs for debugging and monitoring

## Configuration

### Key Configuration Options (config.py)

```python
# BigQuery Settings
BIGQUERY_PROJECT_ID = "campaignanalytics-182101"
BIGQUERY_DATASET = "MNHenMplsMayorJacobF"
BIGQUERY_TABLE = "All_Contributions_View"

# ML Model Settings
ML_MIN_SAMPLES_FOR_TRAINING = 50
ML_TEST_SIZE = 0.2
ML_RANDOM_STATE = 42

# Classification Thresholds
HIGH_AMOUNT_THRESHOLD = 1000
FREQUENT_CONTRIBUTOR_THRESHOLD = 3
CONFIDENCE_THRESHOLD = 0.7

# Output Directories
OUTPUT_DIR = "outputs"
REPORTS_DIR = "reports"
MODELS_DIR = "models"
```

### Classification Categories

The system recognizes these main categories:
- **Lawyer**: Legal professionals and law firms
- **Developer**: Real estate developers and development companies
- **BusinessOwner**: Business owners and executives
- **Individual**: Individual contributors without business affiliation
- **Association**: Political associations and organizations
- **Pohlad**: Pohlad family and related entities
- **Others**: Unclassified contributions

## Enhanced Features

### 1. Machine Learning Classification
- Uses TF-IDF vectorization for text analysis
- Random Forest classifier for category prediction
- Confidence scoring for classification reliability

### 2. Category Discovery
- K-means clustering to identify new contribution patterns
- Automatic detection of potential new categories
- Statistical analysis of clustering results

### 3. Gap Analysis
- Identifies high-value unclassified contributions
- Finds frequent employers needing classification rules
- Analyzes "Others" category for improvement opportunities

### 4. Data Quality Assessment
- Comprehensive data validation and quality scoring
- Missing value analysis and reporting
- Duplicate detection and invalid data identification

## Analysis Workflow

1. **Data Loading**: Extracts contribution data from BigQuery view
2. **Initial Classification**: Applies existing rule-based classification
3. **ML Training**: Trains machine learning model on classified data
4. **Category Discovery**: Uses clustering to find new patterns
5. **Enhanced Classification**: Combines rules, ML predictions, and discovered categories
6. **Gap Analysis**: Identifies classification gaps and opportunities
7. **Report Generation**: Creates comprehensive analysis reports
8. **SQL Function Update**: Generates enhanced classification function

## Monitoring and Debugging

### Log Levels
- **INFO**: General progress and results
- **WARNING**: Potential issues and data quality concerns
- **ERROR**: Failures and exceptions

### Common Issues

1. **BigQuery Connection Issues**
   - Verify Google Cloud authentication
   - Check project ID and dataset names in config

2. **Insufficient Training Data**
   - System requires minimum sample sizes for ML training
   - Check `ML_MIN_SAMPLES_FOR_TRAINING` in config

3. **Memory Issues with Large Datasets**
   - Consider processing data in chunks
   - Adjust clustering parameters for large datasets

## Performance Considerations

- **Data Size**: System handles datasets up to ~100K records efficiently
- **ML Training**: Training time scales with data size and feature complexity
- **Memory Usage**: Peak memory usage ~2-4GB for typical datasets
- **Execution Time**: Complete analysis typically takes 10-30 minutes

## Integration with Existing SQL

The enhanced SQL function can be used to replace the existing `ContriCategoryFunction.sql`:

```sql
-- Replace existing function calls with enhanced version
SELECT 
    *,
    enhanced_classify_contribution(contributor_name, contributor_employer, contribution_amount) as category
FROM All_Contributions_View
```

## Customization

### Adding New Categories
1. Update category definitions in `config.py`
2. Add keyword patterns for new categories
3. Update industry mappings if applicable
4. Retrain ML model with new category examples

### Modifying Classification Rules
1. Edit patterns in `Config.ENHANCED_PATTERNS`
2. Adjust confidence thresholds
3. Update priority rankings for category conflicts

### Custom Analysis
1. Extend `ContributionClassifier` class methods
2. Add custom analysis functions to `utils.py`
3. Modify report generation in `AnalysisReporter`

## Troubleshooting

### Check System Status
```bash
python main.py --validate-config
```

### Review Logs
```bash
tail -f classification_analysis.log
```

### Test Individual Components
```python
# Test data loading
from contribution_classifier import ContributionClassifier
classifier = ContributionClassifier()
data = classifier.load_data()
print(f"Loaded {len(data)} records")
```

## Contributing

To extend the system:
1. Follow existing code patterns and documentation
2. Add unit tests for new functionality
3. Update configuration and README as needed
4. Test with representative data samples

## License

This project is part of the Campaign Finance Analysis system developed for Minneapolis municipal campaign finance analysis.

---

For questions or support, please refer to the analysis logs or contact the development team.
