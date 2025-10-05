"""
Utility functions for Enhanced Contribution Classification System
"""

import re
import pandas as pd
import numpy as np
from typing import Dict, List, Tuple, Optional, Any
import logging
from collections import Counter
import json

logger = logging.getLogger(__name__)

class TextProcessor:
    """Text processing utilities"""
    
    @staticmethod
    def clean_text(text: str) -> str:
        """
        Clean and normalize text for analysis
        
        Args:
            text: Input text string
            
        Returns:
            Cleaned text string
        """
        if pd.isna(text) or text is None:
            return ""
        
        # Convert to string and uppercase
        text = str(text).upper().strip()
        
        # Remove extra whitespace and special characters
        text = re.sub(r'[^\w\s&\-\.]', ' ', text)
        text = re.sub(r'\s+', ' ', text)
        
        # Handle common abbreviations
        abbreviations = {
            'CORP': 'CORPORATION',
            'INC': 'INCORPORATED', 
            'LLC': 'LIMITED LIABILITY COMPANY',
            'LLP': 'LIMITED LIABILITY PARTNERSHIP',
            'CO': 'COMPANY',
            'ASSOC': 'ASSOCIATION',
            'DEPT': 'DEPARTMENT',
            'UNIV': 'UNIVERSITY'
        }
        
        for abbr, full in abbreviations.items():
            text = re.sub(rf'\b{abbr}\b', full, text)
        
        return text.strip()
    
    @staticmethod
    def extract_name_parts(full_name: str) -> Dict[str, str]:
        """
        Extract first and last name from full name
        
        Args:
            full_name: Full name string
            
        Returns:
            Dictionary with first_name and last_name
        """
        if pd.isna(full_name) or not full_name:
            return {'first_name': '', 'last_name': ''}
        
        name_parts = str(full_name).strip().split()
        if len(name_parts) == 0:
            return {'first_name': '', 'last_name': ''}
        elif len(name_parts) == 1:
            return {'first_name': name_parts[0], 'last_name': ''}
        else:
            return {'first_name': name_parts[0], 'last_name': ' '.join(name_parts[1:])}
    
    @staticmethod
    def contains_patterns(text: str, patterns: List[str]) -> bool:
        """
        Check if text contains any of the specified patterns
        
        Args:
            text: Text to search in
            patterns: List of patterns to search for
            
        Returns:
            True if any pattern is found
        """
        if not text or not patterns:
            return False
        
        text_upper = str(text).upper()
        return any(pattern.upper() in text_upper for pattern in patterns)
    
    @staticmethod
    def get_word_frequencies(texts: List[str], min_count: int = 2) -> Dict[str, int]:
        """
        Get word frequencies from list of texts
        
        Args:
            texts: List of text strings
            min_count: Minimum count to include word
            
        Returns:
            Dictionary of word frequencies
        """
        all_words = []
        for text in texts:
            if text:
                words = str(text).upper().split()
                all_words.extend(words)
        
        word_counts = Counter(all_words)
        return {word: count for word, count in word_counts.items() if count >= min_count}

class DataValidator:
    """Data validation utilities"""
    
    @staticmethod
    def validate_contribution_amount(amount: Any) -> float:
        """
        Validate and clean contribution amount
        
        Args:
            amount: Contribution amount (any type)
            
        Returns:
            Validated float amount
        """
        if pd.isna(amount) or amount is None:
            return 0.0
        
        try:
            amount_float = float(amount)
            # Reasonable bounds check
            if amount_float < 0:
                return 0.0
            elif amount_float > 1000000:  # $1M cap
                logger.warning(f"Unusually high contribution amount: ${amount_float:,.2f}")
            return amount_float
        except (ValueError, TypeError):
            logger.warning(f"Invalid contribution amount: {amount}")
            return 0.0
    
    @staticmethod
    def validate_date(date_value: Any) -> Optional[pd.Timestamp]:
        """
        Validate and parse date value
        
        Args:
            date_value: Date value (any type)
            
        Returns:
            Validated pandas Timestamp or None
        """
        if pd.isna(date_value) or date_value is None:
            return None
        
        try:
            return pd.to_datetime(date_value)
        except (ValueError, TypeError):
            logger.warning(f"Invalid date value: {date_value}")
            return None
    
    @staticmethod
    def check_data_quality(df: pd.DataFrame) -> Dict[str, Any]:
        """
        Check data quality of contribution DataFrame
        
        Args:
            df: Input DataFrame
            
        Returns:
            Data quality report
        """
        report = {
            'total_records': len(df),
            'missing_values': {},
            'duplicate_records': 0,
            'invalid_amounts': 0,
            'date_range': {},
            'quality_score': 0.0
        }
        
        # Check missing values
        for col in df.columns:
            missing_count = df[col].isna().sum()
            report['missing_values'][col] = {
                'count': int(missing_count),
                'percentage': float(missing_count / len(df) * 100)
            }
        
        # Check duplicates
        if 'contributor_name' in df.columns and 'contribution_amount' in df.columns:
            duplicates = df.duplicated(subset=['contributor_name', 'contribution_amount', 'contributor_employer'])
            report['duplicate_records'] = int(duplicates.sum())
        
        # Check invalid amounts
        if 'contribution_amount' in df.columns:
            invalid_amounts = df['contribution_amount'] < 0
            report['invalid_amounts'] = int(invalid_amounts.sum())
        
        # Check date range
        if 'contribution_date' in df.columns:
            valid_dates = pd.to_datetime(df['contribution_date'], errors='coerce')
            report['date_range'] = {
                'earliest': str(valid_dates.min()) if not valid_dates.isna().all() else 'N/A',
                'latest': str(valid_dates.max()) if not valid_dates.isna().all() else 'N/A'
            }
        
        # Calculate quality score (0-100)
        total_fields = len(df.columns) * len(df)
        total_missing = sum(info['count'] for info in report['missing_values'].values())
        completeness = 1 - (total_missing / total_fields) if total_fields > 0 else 0
        
        duplicate_penalty = report['duplicate_records'] / len(df) if len(df) > 0 else 0
        invalid_penalty = report['invalid_amounts'] / len(df) if len(df) > 0 else 0
        
        report['quality_score'] = max(0, (completeness - duplicate_penalty - invalid_penalty) * 100)
        
        return report

class AnalysisReporter:
    """Generate analysis reports"""
    
    @staticmethod
    def generate_summary_stats(df: pd.DataFrame) -> Dict[str, Any]:
        """
        Generate summary statistics for contribution data
        
        Args:
            df: Input DataFrame
            
        Returns:
            Summary statistics dictionary
        """
        stats = {
            'overview': {
                'total_records': len(df),
                'unique_contributors': df['contributor_name'].nunique() if 'contributor_name' in df.columns else 0,
                'unique_employers': df['contributor_employer'].nunique() if 'contributor_employer' in df.columns else 0,
                'total_amount': float(df['contribution_amount'].sum()) if 'contribution_amount' in df.columns else 0
            },
            'amount_statistics': {},
            'temporal_analysis': {},
            'category_distribution': {}
        }
        
        # Amount statistics
        if 'contribution_amount' in df.columns:
            amounts = df['contribution_amount'].dropna()
            stats['amount_statistics'] = {
                'mean': float(amounts.mean()),
                'median': float(amounts.median()),
                'std': float(amounts.std()),
                'min': float(amounts.min()),
                'max': float(amounts.max()),
                'q25': float(amounts.quantile(0.25)),
                'q75': float(amounts.quantile(0.75))
            }
        
        # Category distribution
        if 'current_category' in df.columns:
            category_counts = df['current_category'].value_counts()
            stats['category_distribution'] = {
                'counts': category_counts.to_dict(),
                'percentages': (category_counts / len(df) * 100).to_dict()
            }
        
        # Temporal analysis
        if 'contribution_date' in df.columns:
            df_copy = df.copy()
            df_copy['contribution_date'] = pd.to_datetime(df_copy['contribution_date'], errors='coerce')
            df_copy = df_copy.dropna(subset=['contribution_date'])
            
            if len(df_copy) > 0:
                df_copy['year'] = df_copy['contribution_date'].dt.year
                df_copy['month'] = df_copy['contribution_date'].dt.month
                
                yearly_stats = df_copy.groupby('year').agg({
                    'contribution_amount': ['count', 'sum', 'mean']
                }).round(2)
                
                stats['temporal_analysis'] = {
                    'by_year': yearly_stats.to_dict() if len(yearly_stats) > 0 else {},
                    'date_range': {
                        'start': str(df_copy['contribution_date'].min()),
                        'end': str(df_copy['contribution_date'].max())
                    }
                }
        
        return stats
    
    @staticmethod
    def create_html_report(analysis_results: Dict, output_path: str) -> None:
        """
        Create HTML report from analysis results
        
        Args:
            analysis_results: Analysis results dictionary
            output_path: Path to save HTML report
        """
        html_template = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Contribution Classification Analysis Report</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; }}
                .header {{ background-color: #f0f8ff; padding: 20px; border-radius: 5px; }}
                .section {{ margin: 20px 0; padding: 15px; border-left: 4px solid #007acc; }}
                .metric {{ display: inline-block; margin: 10px; padding: 10px; background-color: #f9f9f9; border-radius: 3px; }}
                .recommendations {{ background-color: #fff8dc; padding: 15px; border-radius: 5px; }}
                table {{ border-collapse: collapse; width: 100%; }}
                th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Enhanced Contribution Classification Analysis</h1>
                <p>Generated on: {timestamp}</p>
            </div>
            
            <div class="section">
                <h2>Executive Summary</h2>
                <div class="metric">
                    <strong>Total Records:</strong> {total_records:,}
                </div>
                <div class="metric">
                    <strong>Unique Contributors:</strong> {unique_contributors:,}
                </div>
                <div class="metric">
                    <strong>Unique Employers:</strong> {unique_employers:,}
                </div>
                <div class="metric">
                    <strong>Others Category:</strong> {others_percentage:.1f}%
                </div>
            </div>
            
            <div class="section">
                <h2>Category Distribution</h2>
                {category_table}
            </div>
            
            <div class="section">
                <h2>Gap Analysis</h2>
                <p><strong>High-value unclassified contributions:</strong> {high_value_others}</p>
                <p><strong>Frequent unclassified employers:</strong> {frequent_employers}</p>
            </div>
            
            <div class="recommendations">
                <h2>Recommendations</h2>
                <ul>
                {recommendations_list}
                </ul>
            </div>
        </body>
        </html>
        """
        
        # Extract data for template
        data_summary = analysis_results.get('data_summary', {})
        gap_analysis = analysis_results.get('gap_analysis', {})
        recommendations = analysis_results.get('recommendations', [])
        
        # Create category distribution table
        category_dist = gap_analysis.get('category_distribution', {})
        category_table = "<table><tr><th>Category</th><th>Count</th><th>Percentage</th></tr>"
        total_records = sum(category_dist.values()) if category_dist else 1
        
        for category, count in category_dist.items():
            percentage = (count / total_records) * 100
            category_table += f"<tr><td>{category}</td><td>{count:,}</td><td>{percentage:.1f}%</td></tr>"
        category_table += "</table>"
        
        # Format recommendations
        recommendations_list = "\n".join([f"<li>{rec}</li>" for rec in recommendations])
        
        # Fill template
        html_content = html_template.format(
            timestamp=pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S"),
            total_records=data_summary.get('total_records', 0),
            unique_contributors=data_summary.get('unique_contributors', 0),
            unique_employers=data_summary.get('unique_employers', 0),
            others_percentage=gap_analysis.get('others_analysis', {}).get('percentage', 0),
            category_table=category_table,
            high_value_others=len(gap_analysis.get('high_amount_others', [])),
            frequent_employers=len(gap_analysis.get('frequent_unclassified_employers', {})),
            recommendations_list=recommendations_list
        )
        
        with open(output_path, 'w') as f:
            f.write(html_content)
        
        logger.info(f"HTML report saved to {output_path}")

class ModelPersistence:
    """Model saving and loading utilities"""
    
    @staticmethod
    def save_model_artifacts(classifier_obj, file_path: str) -> None:
        """
        Save trained model artifacts
        
        Args:
            classifier_obj: ContributionClassifier instance
            file_path: Path to save model
        """
        import joblib
        
        artifacts = {
            'classifier': classifier_obj.classifier,
            'vectorizer': classifier_obj.vectorizer,
            'categories': classifier_obj.categories,
            'is_trained': classifier_obj.is_trained,
            'training_timestamp': pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        joblib.dump(artifacts, file_path)
        logger.info(f"Model artifacts saved to {file_path}")
    
    @staticmethod
    def load_model_artifacts(file_path: str) -> Dict:
        """
        Load trained model artifacts
        
        Args:
            file_path: Path to load model from
            
        Returns:
            Dictionary with model artifacts
        """
        import joblib
        
        artifacts = joblib.load(file_path)
        logger.info(f"Model artifacts loaded from {file_path}")
        return artifacts
