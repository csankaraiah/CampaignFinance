#!/usr/bin/env python3
"""
Main execution script for Enhanced Contribution Classification System
Run with: python main.py
"""

import os
import sys
import logging
import argparse
import numpy as np
from datetime import datetime
from pathlib import Path

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from contribution_classifier import ContributionClassifier
from config import Config
from utils import DataValidator, AnalysisReporter

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('classification_analysis.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

def setup_directories():
    """Create necessary output directories"""
    directories = [
        Config.OUTPUT_DIR,
        Config.REPORTS_DIR,
        Config.MODELS_DIR
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        logger.info(f"Created directory: {directory}")

def analyze_classification_gaps(df):
    """Simple gap analysis function"""
    gap_analysis = {}
    
    # Category distribution
    category_dist = df['current_category'].value_counts().to_dict()
    gap_analysis['category_distribution'] = category_dist
    
    # Others analysis
    others_count = category_dist.get('Others', 0)
    others_percentage = (others_count / len(df)) * 100 if len(df) > 0 else 0
    gap_analysis['others_analysis'] = {
        'count': others_count,
        'percentage': others_percentage
    }
    
    # High-value others
    if 'contribution_amount' in df.columns:
        high_value_others = df[
            (df['current_category'] == 'Others') & 
            (df['contribution_amount'] > 1000)
        ]
        gap_analysis['high_amount_others'] = high_value_others.to_dict('records')
    else:
        gap_analysis['high_amount_others'] = []
    
    # Frequent unclassified employers
    if 'contributor_employer' in df.columns:
        others_employers = df[df['current_category'] == 'Others']['contributor_employer'].value_counts()
        frequent_unclassified = others_employers[others_employers >= 3].to_dict()
        gap_analysis['frequent_unclassified_employers'] = frequent_unclassified
    else:
        gap_analysis['frequent_unclassified_employers'] = {}
    
    return gap_analysis

def generate_enhanced_sql_function(df, new_categories):
    """Generate enhanced SQL classification function"""
    
    # Get category statistics
    category_stats = df['enhanced_category'].value_counts()
    
    sql_template = """
CREATE OR REPLACE FUNCTION `{project}.{dataset}.enhanced_classify_contribution`(
    contributor_name STRING,
    contributor_employer STRING,
    contribution_amount FLOAT64
) RETURNS STRING AS (
    CASE
        -- Enhanced classification rules based on analysis
        WHEN UPPER(contributor_employer) LIKE '%LAW%' 
            OR UPPER(contributor_employer) LIKE '%ATTORNEY%' 
            OR UPPER(contributor_employer) LIKE '%LEGAL%' 
        THEN 'Lawyer'
        
        WHEN UPPER(contributor_employer) LIKE '%DEVELOP%' 
            OR UPPER(contributor_employer) LIKE '%CONSTRUCTION%' 
            OR UPPER(contributor_employer) LIKE '%REAL ESTATE%'
        THEN 'Developer'
        
        WHEN UPPER(contributor_employer) LIKE '%POHLAD%'
            OR UPPER(contributor_name) LIKE '%POHLAD%'
        THEN 'Pohlad'
        
        WHEN UPPER(contributor_employer) LIKE '%ASSOCIATION%'
            OR UPPER(contributor_employer) LIKE '%UNION%'
            OR UPPER(contributor_employer) LIKE '%PAC%'
        THEN 'Association'
        
        WHEN contributor_employer IS NULL 
            OR TRIM(contributor_employer) = ''
            OR UPPER(contributor_employer) = 'RETIRED'
            OR UPPER(contributor_employer) = 'SELF'
        THEN 'Individual'
        
        WHEN UPPER(contributor_employer) LIKE '%CEO%'
            OR UPPER(contributor_employer) LIKE '%PRESIDENT%'
            OR UPPER(contributor_employer) LIKE '%OWNER%'
            OR UPPER(contributor_employer) LIKE '%FOUNDER%'
        THEN 'BusinessOwner'
        
        ELSE 'Others'
    END
);

-- Enhanced classification analysis summary:
-- Total records analyzed: {total_records:,}
-- Category distribution:
{category_distribution}
-- Generated on: {timestamp}
""".format(
        project=Config.PROJECT_ID,
        dataset=Config.FUNCTION_DATASET,
        total_records=len(df),
        category_distribution='\n'.join([f'-- {cat}: {count:,} ({count/len(df)*100:.1f}%)' 
                                       for cat, count in category_stats.items()]),
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )
    
    return sql_template

def run_full_analysis():
    """Run the complete classification analysis pipeline"""
    logger.info("Starting Enhanced Contribution Classification Analysis")
    
    try:
        # Initialize classifier
        classifier = ContributionClassifier()
        
        # Load data
        logger.info("Loading contribution data from BigQuery...")
        data = classifier.load_data()
        
        if data is None or len(data) == 0:
            logger.error("No data loaded. Check your BigQuery connection and query.")
            return False
        
        logger.info(f"Loaded {len(data)} contribution records")
        
        # Validate data quality
        logger.info("Validating data quality...")
        data_quality = DataValidator.check_data_quality(data)
        logger.info(f"Data quality score: {data_quality['quality_score']:.1f}/100")
        
        # Generate initial classification
        logger.info("Applying initial rule-based classification...")
        classified_data = data.copy()
        
        # Create features first
        logger.info("Extracting features for analysis...")
        classified_data = classifier.extract_features(classified_data)
        
        # Always re-apply enhanced rule-based classification to get improvements
        logger.info("Applying enhanced classification rules...")
        classified_data['enhanced_current_category'] = classified_data.apply(
            lambda row: classifier.rule_based_classification(
                row.get('contributor_employer', ''), 
                row.get('contributor_name', '')
            ), axis=1
        )
        
        # Keep original for comparison but use enhanced for analysis
        classified_data['original_category'] = classified_data['current_category']
        classified_data['current_category'] = classified_data['enhanced_current_category']
        
        # Analyze gaps
        logger.info("Analyzing classification gaps...")
        gap_analysis = analyze_classification_gaps(classified_data)
        
        # Train ML model
        logger.info("Training machine learning model...")
        success = classifier.train_ml_classifier(classified_data)
        
        if success:
            logger.info("ML model trained successfully")
            
            # Discover new categories
            logger.info("Discovering potential new categories...")
            new_categories = classifier.discover_new_categories(
                classified_data, 
                n_clusters=5
            )
            
            if new_categories:
                logger.info(f"Discovered {len(new_categories)} potential new categories")
                for category_name, info in new_categories.items():
                    logger.info(f"  - {category_name}: {info['size']} contributors")
        
        # Generate enhanced classification
        logger.info("Generating enhanced classification...")
        enhanced_data = classified_data.copy()
        
        # Use existing current_category as enhanced_category initially
        enhanced_data['enhanced_category'] = enhanced_data['current_category']
        enhanced_data['confidence_score'] = 0.8  # Default confidence for rule-based
        
        # If ML training was successful, add ML predictions
        if success:
            logger.info("Adding ML predictions to classification...")
            try:
                # Get ML predictions for all records
                text_features = (enhanced_data['contributor_employer'].fillna('') + ' ' +
                               enhanced_data['contributor_name'].fillna('')).str.strip()
                
                if hasattr(classifier, 'vectorizer') and classifier.vectorizer is not None:
                    X_text = classifier.vectorizer.transform(text_features)
                    numerical_features = enhanced_data[['employer_length', 'name_length', 'log_amount']].fillna(0)
                    X_combined = np.hstack([X_text.toarray(), numerical_features.values])
                    
                    ml_predictions = classifier.classifier.predict(X_combined)
                    ml_probabilities = classifier.classifier.predict_proba(X_combined).max(axis=1)
                    
                    # Use ML prediction if confidence is high and different from rule-based
                    high_confidence_mask = ml_probabilities > 0.7
                    enhanced_data.loc[high_confidence_mask, 'enhanced_category'] = ml_predictions[high_confidence_mask]
                    enhanced_data.loc[high_confidence_mask, 'confidence_score'] = ml_probabilities[high_confidence_mask]
                    
                    logger.info(f"Applied ML predictions to {high_confidence_mask.sum()} records")
            except Exception as e:
                logger.warning(f"Could not apply ML predictions: {e}")
        
        # Add ML category column for comparison
        enhanced_data['ml_category'] = enhanced_data['enhanced_category']
        
        # Generate comprehensive analysis
        logger.info("Generating analysis reports...")
        analysis_results = {
            'data_summary': {
                'total_records': len(enhanced_data),
                'unique_contributors': enhanced_data['contributor_name'].nunique(),
                'unique_employers': enhanced_data['contributor_employer'].nunique(),
                'total_amount': enhanced_data['contribution_amount'].sum()
            },
            'data_quality': data_quality,
            'gap_analysis': gap_analysis,
            'ml_training_success': success,
            'discovered_categories': new_categories if success else {},
            'recommendations': generate_recommendations(gap_analysis, new_categories if success else {})
        }
        
        # Save results
        output_file = os.path.join(Config.OUTPUT_DIR, f"enhanced_classification_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")
        enhanced_data.to_csv(output_file, index=False)
        logger.info(f"Enhanced classification results saved to: {output_file}")
        
        # Generate reports
        summary_stats = AnalysisReporter.generate_summary_stats(enhanced_data)
        
        # Save detailed analysis report
        report_file = os.path.join(Config.REPORTS_DIR, f"analysis_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
        import json
        with open(report_file, 'w') as f:
            json.dump({**analysis_results, 'summary_statistics': summary_stats}, f, indent=2, default=str)
        
        # Generate HTML report
        html_report_file = os.path.join(Config.REPORTS_DIR, f"classification_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html")
        AnalysisReporter.create_html_report(analysis_results, html_report_file)
        
        # Generate enhanced SQL function
        logger.info("Generating enhanced SQL classification function...")
        sql_function = generate_enhanced_sql_function(enhanced_data, new_categories if success else {})
        
        sql_file = os.path.join(Config.OUTPUT_DIR, f"enhanced_classification_function_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql")
        with open(sql_file, 'w') as f:
            f.write(sql_function)
        
        logger.info(f"Enhanced SQL function saved to: {sql_file}")
        
        # Print summary
        print("\n" + "="*60)
        print("ENHANCED CONTRIBUTION CLASSIFICATION ANALYSIS - COMPLETE")
        print("="*60)
        print(f"Total Records Processed: {len(enhanced_data):,}")
        print(f"Unique Contributors: {enhanced_data['contributor_name'].nunique():,}")
        print(f"Unique Employers: {enhanced_data['contributor_employer'].nunique():,}")
        print(f"Total Contribution Amount: ${enhanced_data['contribution_amount'].sum():,.2f}")
        print(f"Data Quality Score: {data_quality['quality_score']:.1f}/100")
        
        # Category distribution
        category_dist = enhanced_data['enhanced_category'].value_counts()
        print(f"\nCategory Distribution:")
        for category, count in category_dist.head(10).items():
            percentage = (count / len(enhanced_data)) * 100
            print(f"  {category}: {count:,} ({percentage:.1f}%)")
        
        if success and new_categories:
            print(f"\nDiscovered {len(new_categories)} potential new categories")
        
        print(f"\nOutput Files:")
        print(f"  Classification Results: {output_file}")
        print(f"  Analysis Report: {report_file}")
        print(f"  HTML Report: {html_report_file}")
        print(f"  Enhanced SQL Function: {sql_file}")
        
        return True
        
    except Exception as e:
        logger.error(f"Analysis failed: {str(e)}", exc_info=True)
        return False

def generate_recommendations(gap_analysis, discovered_categories):
    """Generate actionable recommendations based on analysis"""
    recommendations = []
    
    # Others category analysis
    others_info = gap_analysis.get('others_analysis', {})
    if others_info.get('percentage', 0) > 30:
        recommendations.append(
            f"High 'Others' classification rate ({others_info.get('percentage', 0):.1f}%) suggests need for additional categories"
        )
    
    # High-value unclassified
    high_value_others = gap_analysis.get('high_amount_others', [])
    if len(high_value_others) > 10:
        recommendations.append(
            f"Review {len(high_value_others)} high-value contributions in 'Others' category for manual classification"
        )
    
    # Frequent employers
    frequent_employers = gap_analysis.get('frequent_unclassified_employers', {})
    if len(frequent_employers) > 5:
        recommendations.append(
            f"Add classification rules for {len(frequent_employers)} frequent employers currently unclassified"
        )
    
    # Discovered categories
    if discovered_categories:
        recommendations.append(
            f"Consider creating {len(discovered_categories)} new categories based on clustering analysis"
        )
    
    # Data quality recommendations
    recommendations.extend([
        "Implement employer name standardization to improve classification accuracy",
        "Consider adding industry codes to contribution data for better categorization",
        "Regular review and update of classification rules based on new contribution patterns"
    ])
    
    return recommendations

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Enhanced Contribution Classification System')
    parser.add_argument('--setup-only', action='store_true', help='Only setup directories without running analysis')
    parser.add_argument('--validate-config', action='store_true', help='Validate configuration and exit')
    
    args = parser.parse_args()
    
    # Setup directories
    setup_directories()
    
    if args.setup_only:
        logger.info("Directory setup complete. Exiting.")
        return
    
    if args.validate_config:
        logger.info("Validating configuration...")
        # Basic config validation
        required_vars = ['BIGQUERY_PROJECT_ID', 'BIGQUERY_DATASET', 'BIGQUERY_TABLE']
        for var in required_vars:
            if not hasattr(Config, var):
                logger.error(f"Missing required config: {var}")
                return
        logger.info("Configuration validation passed.")
        return
    
    # Run full analysis
    success = run_full_analysis()
    
    if success:
        logger.info("Analysis completed successfully!")
        sys.exit(0)
    else:
        logger.error("Analysis failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
