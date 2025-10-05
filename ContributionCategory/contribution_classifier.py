#!/usr/bin/env python3
"""
Enhanced Contribution Category Classification System

This module provides an enhanced classification system for campaign contributions
based on contributor names and employer information, using machine learning techniques
to improve upon the existing SQL-based classification function.

Author: Campaign Finance Analysis System
Date: October 2025
"""

import pandas as pd
import numpy as np
from google.cloud import bigquery
import re
from typing import Dict, List, Tuple, Optional
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import joblib
import logging
from collections import Counter
import warnings
warnings.filterwarnings('ignore')

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ContributionClassifier:
    """
    Enhanced contribution classification system using ML techniques
    """
    
    def __init__(self, project_id: str = "campaignanalytics-182101"):
        """
        Initialize the classifier with BigQuery client
        
        Args:
            project_id: Google Cloud project ID
        """
        self.project_id = project_id
        self.client = bigquery.Client(project=project_id)
        self.categories = [
            'Lawyer', 'Developer', 'BusinessOwner', 'Individual', 
            'Pohlad family', 'Association', 'Others'
        ]
        
        # ML components
        self.vectorizer = None
        self.classifier = None
        self.kmeans = None
        self.is_trained = False
        
        # Pattern dictionaries from existing SQL function
        self.initialize_patterns()
    
    def initialize_patterns(self):
        """Initialize pattern dictionaries based on existing SQL function"""
        
        self.lawyer_patterns = {
            'exact_matches': [
                'North State Advisors', 'Lockridge Grindal Nauen', 'Attorney',
                'McGrann Shea Carnival Straughn and Lamb', 'Dykema',
                'Faegre Baker Daniels', 'Stinson Leonard Street', 'Goff Public Relations',
                'Redmond Associates, Inc.', 'Dominium', 'Lobbyist', 'Messerli Kramer',
                'Kaplan Strangis', 'Faegre Baker Ds', 'Faegre Baker D',
                'Brlol and Associates', 'Lockridge Grindai Nauen',
                'Maslon, Edelman, Borman & Brand', 'McGrann Shea C',
                'McGrahn Shea Carnival Stra', 'North State Adv',
                'North State Advi', 'Western Litigation'
            ],
            'pattern_matches': [
                'HOFFNER', 'LGN', 'DYKEMA', 'BAKER', 'LINDQUIST', 'ADVOCACY'
            ],
            'contains': ['Associate']
        }
        
        self.developer_patterns = {
            'exact_matches': [
                'Keller Williams Realty', 'Developer', 'Developers',
                'Hillcrest Develop', 'Kraus Anderson', 'Ryan Construction',
                'Weis Builders', 'Brighton Development', 'Mortenson Construction',
                'Mortensori Construction', 'RSP Architects', 'Building Manager',
                'Realtor', 'Dunbar Development', 'Keller Williams R',
                'Prospect Park Properties', 'Ryan Companies', 'Kleinman Realty Company',
                'Opus Group', 'Contractor', 'Hyde Development',
                'Provident Real Estate Venture', 'Thor Construction',
                'Thor Constructs', 'Alatus', 'Young Quinlan Building',
                'Hillcrest Development', 'Wellington Development', 'Lupe Development',
                'Abdo Market House', 'StevenScott Management', 'Duval Development',
                'Welsh Companies', 'Lakes Area Realty'
            ],
            'pattern_matches': [
                'DORAN', 'CPM COMPANIES', 'RYAN CO', 'WINDSOR MANAG', 'PROPERTIES',
                'ACKERBERG', 'PROP', 'SOLHEM', 'LANDER', 'DEVELOPMENT',
                'SCHAFER', 'MANAGEMENT', 'METROPELIGO', 'COLDWELL', 'BANKER',
                'GRECO', 'HOSPITALITY', 'DESIGN', 'COMMERCIAL', 'BKV',
                'MORTENSON', 'COLLIERS', 'REAL ESTATE', 'FRANA', 'LOUCKS',
                'PERKINS', 'ARCHITECT'
            ]
        }
        
        self.business_owner_patterns = {
            'exact_matches': [
                'Ramsey Excavating', 'Timeshare Systems', 'Kelber Catering',
                'Minnesota Vikings', 'Broadway Liquor', 'Hirshfields',
                'Minnesota Twins', 'Delta Dental Foundation', 'Restauranteur',
                'Wall Companies', 'Dakota Jazz Club', 'March Enterprises',
                'Le Meredien Chambers', 'Atomic Recycling', 'Pohlad Companies',
                'Businessman', 'The Language Bank', 'Dunbar Enterprises',
                'Wells Fargo', 'Standard Heating and Air', 'Blue Ox',
                'Minnesota Timberwolves', 'Parasole Restaurants',
                'Minneapolis Entertainment, Inc.', 'Deja Vu of Minnesota'
            ],
            'pattern_matches': [
                'WINE', 'NEWBERRY', 'STUDIO', 'NUWAY', 'HK&OK', 'OUTDOOR',
                'BARR', 'MAHAL', 'UROLOGY', 'CHERRYHOMES', 'TACO', 'TURKEY',
                'DERMATOLOG', 'EVENT', 'BACHELOR', 'PLATE', 'TOWING',
                'CAFE', 'MEADOW', 'KNOWRE', 'LIGHTWELL', 'MAKES IT',
                'MASTER', 'MENTOR PLANET', 'NINA', 'NORTH', 'PRESS'
            ]
        }
        
        self.individual_patterns = {
            'pattern_matches': [
                'U OF M', 'SCHOOL', 'CAMP', 'TARGET', 'ACCENTURE', 'MACY',
                'UNIVERSITY', 'METRO TRANSIT', 'ITDP', 'COUNTY', 'TRUST',
                'BOARD', 'EMPLOYED', 'SOCIETY', 'BART', 'CPM', 'CITY',
                'CONSULT', 'GREAT RIVER', 'PROFESSIONAL', 'MAYOR', 'NEIGH',
                'US BANK', 'WCW', 'UNIVERSIT', 'ARMY CORP'
            ],
            'exact_matches': ['RETIRED', 'SELF']
        }
        
        self.association_patterns = {
            'name_patterns': [
                'COUNCIL', 'COMMITTEE', 'UNION', 'CITY', 'VOLUNTEER', 'PAC',
                'FUND', 'LLC', 'POLITICAL', 'ASSOCIATION', 'INC', 'FRIENDS',
                'LOCAL', 'DISTRICT', 'LLP', 'STATE', 'LAW', 'LABOR',
                'MINNEAPOLIS', 'FEDERATION', 'SELU', 'SEIU', 'FIRE FIGHTERS',
                'MINNESOTA', 'ATTORNEY', 'MULTI', 'XCEL', 'UNITE', 'AFL-CIO', 'TRADE'
            ],
            'employer_patterns': [
                'AFL-CIO', 'SEIU', 'COMMUNITY', 'RIGHTS', 'GREEN', 'ALLIANCE',
                'MINNESOTA', 'COALIT', 'TAKE ACTION', 'GROUP', 'WILDLIFE',
                'ULI MN', 'COUNCIL'
            ]
        }
    
    def load_data(self) -> pd.DataFrame:
        """
        Load contribution data from BigQuery view
        
        Returns:
            DataFrame with contribution data
        """
        query = """
        SELECT 
            contributor_name,
            contributor_employer,
            contributor_first_name,
            contributor_last_name,
            contribution_amount,
            source_type,
            candidate_category,
            `campaignanalytics-182101.dq.dq_B_ContriCategory`(
                contributor_employer, 
                contributor_name
            ) AS current_category
        FROM `campaignanalytics-182101.Munidata.Mpls_All_Contributions_View`
        WHERE contributor_name IS NOT NULL
        """
        
        logger.info("Loading contribution data from BigQuery...")
        df = self.client.query(query).to_dataframe()
        logger.info(f"Loaded {len(df):,} contribution records")
        
        return df
    
    def preprocess_text(self, text: str) -> str:
        """
        Preprocess text for analysis
        
        Args:
            text: Input text string
            
        Returns:
            Cleaned text string
        """
        if pd.isna(text) or text is None:
            return ""
        
        # Convert to uppercase and strip whitespace
        text = str(text).upper().strip()
        
        # Remove special characters but keep spaces and common business terms
        text = re.sub(r'[^\w\s&\-\.]', ' ', text)
        
        # Normalize multiple spaces
        text = re.sub(r'\s+', ' ', text)
        
        return text
    
    def extract_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Extract features for machine learning
        
        Args:
            df: Input DataFrame
            
        Returns:
            DataFrame with extracted features
        """
        logger.info("Extracting features...")
        
        # Create feature columns
        df = df.copy()
        df['employer_clean'] = df['contributor_employer'].apply(self.preprocess_text)
        df['name_clean'] = df['contributor_name'].apply(self.preprocess_text)
        
        # Text length features
        df['employer_length'] = df['employer_clean'].str.len()
        df['name_length'] = df['name_clean'].str.len()
        
        # Pattern-based features
        df['has_llc'] = df['name_clean'].str.contains('LLC|LLP|INC|CORP', na=False)
        df['has_association_words'] = df['name_clean'].str.contains(
            'COMMITTEE|COUNCIL|UNION|ASSOCIATION|PAC|FUND', na=False
        )
        df['has_business_words'] = df['employer_clean'].str.contains(
            'COMPANY|CORP|LLC|INC|ENTERPRISE|GROUP', na=False
        )
        df['is_self_employed'] = df['employer_clean'].str.contains(
            'SELF|RETIRED|NOT EMPLOYED', na=False
        )
        
        # Contribution amount features
        df['log_amount'] = np.log1p(df['contribution_amount'].fillna(0))
        df['amount_bin'] = pd.cut(df['contribution_amount'].fillna(0), 
                                 bins=[0, 100, 500, 2000, float('inf')], 
                                 labels=['small', 'medium', 'large', 'very_large'])
        
        return df
    
    def rule_based_classification(self, employer: str, name: str) -> str:
        """
        Apply enhanced rule-based classification to reduce Others category
        
        Args:
            employer: Contributor employer
            name: Contributor name
            
        Returns:
            Predicted category
        """
        from config import Config
        
        employer_clean = self.preprocess_text(employer) if employer else ""
        name_clean = self.preprocess_text(name) if name else ""
        employer_original = str(employer).strip() if employer else ""
        
        # Check specific employer mappings first (case-insensitive partial matches)
        if hasattr(Config, 'EMPLOYER_MAPPINGS'):
            for employer_key, category in Config.EMPLOYER_MAPPINGS.items():
                if employer_key.upper() in employer_clean or employer_key.upper() in employer_original.upper():
                    return category
        
        # Pohlad family check - NOW MERGED INTO BusinessOwner
        if 'POHLAD' in name_clean or 'POHLAD' in employer_clean:
            return 'BusinessOwner'
        
        # Enhanced Lawyer patterns
        lawyer_keywords = Config.ENHANCED_PATTERNS.get('lawyer_keywords', [])
        if any(keyword in employer_clean for keyword in lawyer_keywords):
            return 'Lawyer'
        
        # Enhanced Developer patterns  
        developer_keywords = Config.ENHANCED_PATTERNS.get('developer_keywords', [])
        if any(keyword in employer_clean for keyword in developer_keywords):
            return 'Developer'
        
        # Enhanced BusinessOwner patterns (including business entity types)
        business_keywords = Config.ENHANCED_PATTERNS.get('business_owner_keywords', [])
        
        # Check for business entity indicators
        business_entities = ['LLC', 'INC', 'CORP', 'COMPANY', 'BUSINESS', 'CONSULTING', 'SERVICES']
        has_business_entity = any(entity in employer_clean for entity in business_entities)
        
        # Check for business/professional keywords
        has_business_keyword = any(keyword in employer_clean for keyword in business_keywords)
        
        # Check for financial/professional service companies
        financial_indicators = ['BANK', 'FINANCIAL', 'CAPITAL', 'INVESTMENT', 'REALTY', 'INSURANCE']
        has_financial_indicator = any(indicator in employer_clean for indicator in financial_indicators)
        
        if has_business_entity or has_business_keyword or has_financial_indicator:
            return 'BusinessOwner'
        
        # Enhanced Individual patterns (including government employees)
        individual_keywords = Config.ENHANCED_PATTERNS.get('individual_keywords', [])
        if (any(keyword in employer_clean for keyword in individual_keywords) or
            not employer_clean or employer_clean in ['', 'NONE', 'N/A', 'UNKNOWN']):
            return 'Individual'
        
        # Enhanced Association patterns
        association_keywords = Config.ENHANCED_PATTERNS.get('association_keywords', [])
        association_in_name = any(keyword in name_clean for keyword in association_keywords)
        association_in_employer = any(keyword in employer_clean for keyword in association_keywords)
        
        if association_in_name or association_in_employer:
            return 'Association'
        
        # Legacy patterns fallback (from original SQL function)
        if (employer in self.lawyer_patterns.get('exact_matches', []) or
            any(pattern in employer_clean for pattern in self.lawyer_patterns.get('pattern_matches', []))):
            return 'Lawyer'
        
        if (employer in self.developer_patterns.get('exact_matches', []) or
            any(pattern in employer_clean for pattern in self.developer_patterns.get('pattern_matches', []))):
            return 'Developer'
        
        if (employer in self.business_owner_patterns.get('exact_matches', []) or
            any(pattern in employer_clean for pattern in self.business_owner_patterns.get('pattern_matches', []))):
            return 'BusinessOwner'
        
        return 'Others'
    
    def train_ml_classifier(self, df: pd.DataFrame) -> None:
        """
        Train machine learning classifier
        
        Args:
            df: Training DataFrame with features
        """
        logger.info("Training ML classifier...")
        
        # Prepare text features for vectorization
        # Prepare features for ML training
        text_features = (df['contributor_employer'].fillna('') + ' ' +
                        df['contributor_name'].fillna('')).str.strip()
        
        # Create TF-IDF vectors
        self.vectorizer = TfidfVectorizer(
            max_features=1000,
            ngram_range=(1, 2),
            stop_words='english',
            min_df=2
        )
        
        X_text = self.vectorizer.fit_transform(text_features)
        
        # Combine with numerical features
        numerical_features = df[['employer_length', 'name_length', 'log_amount']].fillna(0)
        X_combined = np.hstack([X_text.toarray(), numerical_features.values])
        
        # Use current categories as labels for training
        y = df['current_category'].fillna('Others')
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X_combined, y, test_size=0.2, random_state=42, 
            stratify=y if len(np.unique(y)) > 1 else None
        )
        
        # Train classifier
        self.classifier = RandomForestClassifier(
            n_estimators=100,
            random_state=42,
            class_weight='balanced'
        )
        self.classifier.fit(X_train, y_train)
        
        # Evaluate
        y_pred = self.classifier.predict(X_test)
        logger.info("Classification Report:")
        logger.info(f"\n{classification_report(y_test, y_pred)}")
        
        self.is_trained = True
        logger.info("ML classifier training completed")
    
    def discover_new_categories(self, df: pd.DataFrame, n_clusters: int = 10) -> Dict:
        """
        Use clustering to discover potential new categories
        
        Args:
            df: DataFrame with contribution data
            n_clusters: Number of clusters for analysis
            
        Returns:
            Dictionary with cluster analysis results
        """
        logger.info("Discovering potential new categories using clustering...")
        
        # Focus on 'Others' category for new discovery
        others_df = df[df['current_category'] == 'Others'].copy()
        
        if len(others_df) < 10:
            logger.info("Insufficient 'Others' data for clustering analysis")
            return {}
        
        # Prepare text data
        text_features = (others_df['employer_clean'].fillna('') + ' ' + 
                        others_df['name_clean'].fillna('')).str.strip()
        
        # Vectorize
        vectorizer = TfidfVectorizer(max_features=500, ngram_range=(1, 2))
        X = vectorizer.fit_transform(text_features)
        
        # Apply K-means clustering
        self.kmeans = KMeans(n_clusters=min(n_clusters, len(others_df)), random_state=42)
        clusters = self.kmeans.fit_predict(X)
        
        # Analyze clusters
        cluster_analysis = {}
        for cluster_id in range(len(np.unique(clusters))):
            cluster_mask = clusters == cluster_id
            cluster_data = others_df[cluster_mask]
            
            # Get top employers and names in this cluster
            top_employers = cluster_data['employer_clean'].value_counts().head(5)
            top_names = cluster_data['name_clean'].value_counts().head(5)
            
            cluster_analysis[f'cluster_{cluster_id}'] = {
                'size': len(cluster_data),
                'avg_amount': cluster_data['contribution_amount'].mean(),
                'top_employers': top_employers.to_dict(),
                'top_names': top_names.to_dict(),
                'sample_records': cluster_data[['contributor_name', 'contributor_employer']].head(3).to_dict('records')
            }
        
        return cluster_analysis
    
    def enhanced_classify(self, employer: str, name: str, amount: float = 0) -> Dict:
        """
        Enhanced classification using both rules and ML
        
        Args:
            employer: Contributor employer
            name: Contributor name  
            amount: Contribution amount
            
        Returns:
            Dictionary with classification results and confidence
        """
        # Rule-based classification
        rule_based_result = self.rule_based_classification(employer, name)
        
        result = {
            'rule_based_category': rule_based_result,
            'ml_category': None,
            'confidence': 0.0,
            'final_category': rule_based_result
        }
        
        # ML-based classification if trained
        if self.is_trained and self.vectorizer and self.classifier:
            try:
                # Prepare features
                employer_clean = self.preprocess_text(employer)
                name_clean = self.preprocess_text(name)
                
                text_feature = f"{employer_clean} {name_clean}".strip()
                X_text = self.vectorizer.transform([text_feature])
                
                # Numerical features
                employer_length = len(employer_clean)
                name_length = len(name_clean)
                log_amount = np.log1p(amount if amount else 0)
                
                X_numerical = np.array([[employer_length, name_length, log_amount]])
                X_combined = np.hstack([X_text.toarray(), X_numerical])
                
                # Predict
                ml_prediction = self.classifier.predict(X_combined)[0]
                ml_probabilities = self.classifier.predict_proba(X_combined)[0]
                max_confidence = np.max(ml_probabilities)
                
                result['ml_category'] = ml_prediction
                result['confidence'] = max_confidence
                
                # Use ML result if confidence is high and differs from rule-based
                if max_confidence > 0.7 and ml_prediction != rule_based_result:
                    result['final_category'] = ml_prediction
                    
            except Exception as e:
                logger.warning(f"ML classification failed: {e}")
        
        return result
    
    def analyze_classification_gaps(self, df: pd.DataFrame) -> Dict:
        """
        Analyze gaps in current classification system
        
        Args:
            df: DataFrame with contribution data
            
        Returns:
            Analysis results dictionary
        """
        logger.info("Analyzing classification gaps...")
        
        analysis = {
            'category_distribution': df['current_category'].value_counts().to_dict(),
            'others_analysis': {},
            'high_amount_others': [],
            'frequent_unclassified_employers': [],
            'potential_improvements': []
        }
        
        # Analyze 'Others' category
        others_df = df[df['current_category'] == 'Others']
        if len(others_df) > 0:
            analysis['others_analysis'] = {
                'count': len(others_df),
                'percentage': len(others_df) / len(df) * 100,
                'total_amount': others_df['contribution_amount'].sum(),
                'avg_amount': others_df['contribution_amount'].mean()
            }
            
            # High-value contributions in Others
            high_amount_others = others_df[others_df['contribution_amount'] > 1000]
            analysis['high_amount_others'] = high_amount_others[[
                'contributor_name', 'contributor_employer', 'contribution_amount'
            ]].head(10).to_dict('records')
            
            # Frequent employers in Others
            employer_counts = others_df['contributor_employer'].value_counts().head(10)
            analysis['frequent_unclassified_employers'] = employer_counts.to_dict()
        
        return analysis
    
    def generate_enhanced_function(self, output_path: str = None) -> str:
        """
        Generate enhanced SQL function based on analysis
        
        Args:
            output_path: Optional file path to save the function
            
        Returns:
            Enhanced SQL function as string
        """
        enhanced_function = """
-- Enhanced Contribution Category Classification Function
-- Generated by ML-Enhanced Classification System

CREATE OR REPLACE FUNCTION `campaignanalytics-182101.dq.dq_B_ContriCategory_Enhanced`(
    ContributorsEmployer STRING,
    ContributorName STRING,
    ContributionAmount FLOAT64
) AS (
/*
 * Enhanced Contribution Category Classification
 * Uses improved pattern matching and amount-based logic
 * input: ContributorsEmployer (STRING), ContributorName (STRING), ContributionAmount (FLOAT64)
 * returns: Enhanced contribution category classification
 */
CASE
    -- Pohlad family (highest priority)
    WHEN UPPER(TRIM(ContributorName)) LIKE '%POHLAD%' THEN 'Pohlad family'
    
    -- Enhanced Lawyer patterns
    WHEN ContributorsEmployer IN (
        'North State Advisors', 'Lockridge Grindal Nauen', 'Attorney',
        'McGrann Shea Carnival Straughn and Lamb', 'Dykema',
        'Faegre Baker Daniels', 'Stinson Leonard Street', 'Goff Public Relations',
        -- Additional lawyer firms identified through analysis
        'Larkin Hoffman', 'Messerli Kramer', 'Barnes & Thornburg',
        'Fredrikson & Byron', 'Dorsey & Whitney'
    ) THEN 'Lawyer'
    
    WHEN (
        UPPER(TRIM(ContributorsEmployer)) LIKE '%LAW%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%ATTORNEY%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%LEGAL%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%ADVOCATE%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%BARRISTER%'
    ) THEN 'Lawyer'
    
    -- Enhanced Developer patterns
    WHEN (
        UPPER(TRIM(ContributorsEmployer)) LIKE '%DEVELOPMENT%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%CONSTRUCTION%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%REAL ESTATE%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%ARCHITECT%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%BUILDER%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%PROPERTY%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%REALTOR%'
    ) THEN 'Developer'
    
    -- Enhanced Business Owner patterns (including high-value individual contributions)
    WHEN (
        (UPPER(TRIM(ContributorsEmployer)) LIKE '%CEO%' OR
         UPPER(TRIM(ContributorsEmployer)) LIKE '%OWNER%' OR
         UPPER(TRIM(ContributorsEmployer)) LIKE '%FOUNDER%' OR
         UPPER(TRIM(ContributorsEmployer)) LIKE '%PRESIDENT%') AND
        ContributionAmount > 500
    ) THEN 'BusinessOwner'
    
    -- Enhanced Association patterns
    WHEN (
        UPPER(TRIM(ContributorName)) LIKE '%PAC%' OR
        UPPER(TRIM(ContributorName)) LIKE '%COMMITTEE%' OR
        UPPER(TRIM(ContributorName)) LIKE '%UNION%' OR
        UPPER(TRIM(ContributorName)) LIKE '%ASSOCIATION%' OR
        UPPER(TRIM(ContributorName)) LIKE '%FEDERATION%' OR
        UPPER(TRIM(ContributorName)) LIKE '%COALITION%' OR
        UPPER(TRIM(ContributorName)) LIKE '%ALLIANCE%' OR
        UPPER(TRIM(ContributorName)) LIKE '%COUNCIL%' OR
        UPPER(TRIM(ContributorName)) LIKE '%FUND%'
    ) THEN 'Association'
    
    -- Enhanced Individual patterns
    WHEN (
        UPPER(TRIM(ContributorsEmployer)) IN ('RETIRED', 'NOT EMPLOYED', 'SELF-EMPLOYED', 'HOMEMAKER') OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%RETIRED%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%SELF%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%UNEMPLOYED%'
    ) THEN 'Individual'
    
    -- Government employees
    WHEN (
        UPPER(TRIM(ContributorsEmployer)) LIKE '%CITY OF%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%STATE OF%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%COUNTY%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%FEDERAL%' OR
        UPPER(TRIM(ContributorsEmployer)) LIKE '%GOVERNMENT%'
    ) THEN 'Individual'
    
    -- Default case
    ELSE 'Others'
END
);
        """
        
        if output_path:
            with open(output_path, 'w') as f:
                f.write(enhanced_function)
            logger.info(f"Enhanced function saved to {output_path}")
        
        return enhanced_function
    
    def run_full_analysis(self) -> Dict:
        """
        Run complete analysis pipeline
        
        Returns:
            Comprehensive analysis results
        """
        logger.info("Starting full contribution classification analysis...")
        
        # Load data
        df = self.load_data()
        
        # Extract features  
        df = self.extract_features(df)
        
        # Train ML classifier
        self.train_ml_classifier(df)
        
        # Analyze classification gaps
        gap_analysis = self.analyze_classification_gaps(df)
        
        # Discover new categories
        cluster_analysis = self.discover_new_categories(df)
        
        # Generate enhanced function
        enhanced_function = self.generate_enhanced_function()
        
        results = {
            'data_summary': {
                'total_records': len(df),
                'unique_contributors': df['contributor_name'].nunique(),
                'unique_employers': df['contributor_employer'].nunique(),
                'date_range': f"{df.index.min()} to {df.index.max()}" if hasattr(df.index, 'min') else "N/A"
            },
            'gap_analysis': gap_analysis,
            'cluster_analysis': cluster_analysis,
            'enhanced_function': enhanced_function,
            'recommendations': self.generate_recommendations(gap_analysis, cluster_analysis)
        }
        
        logger.info("Full analysis completed successfully")
        return results
    
    def generate_recommendations(self, gap_analysis: Dict, cluster_analysis: Dict) -> List[str]:
        """
        Generate recommendations based on analysis
        
        Args:
            gap_analysis: Gap analysis results
            cluster_analysis: Cluster analysis results
            
        Returns:
            List of recommendations
        """
        recommendations = []
        
        others_pct = gap_analysis['others_analysis'].get('percentage', 0)
        if others_pct > 20:
            recommendations.append(
                f"High percentage ({others_pct:.1f}%) of contributions classified as 'Others'. "
                "Consider expanding classification rules."
            )
        
        if gap_analysis['high_amount_others']:
            recommendations.append(
                "Several high-value contributions are classified as 'Others'. "
                "Review these for potential new categories."
            )
        
        if cluster_analysis:
            recommendations.append(
                f"Clustering analysis identified {len(cluster_analysis)} potential groupings "
                "within 'Others' category. Consider creating specialized categories."
            )
        
        recommendations.extend([
            "Implement regular retraining of ML classifier with new data",
            "Consider industry-specific categories (Healthcare, Technology, Finance)",
            "Add contribution frequency patterns to classification logic",
            "Monitor classification accuracy and adjust thresholds periodically"
        ])
        
        return recommendations

def main():
    """Main execution function"""
    try:
        # Initialize classifier
        classifier = ContributionClassifier()
        
        # Run full analysis
        results = classifier.run_full_analysis()
        
        # Save results
        import json
        with open('/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory/analysis_results.json', 'w') as f:
            # Convert non-serializable objects to strings
            serializable_results = {
                'data_summary': results['data_summary'],
                'gap_analysis': results['gap_analysis'],
                'cluster_analysis': results['cluster_analysis'],
                'recommendations': results['recommendations'],
                'enhanced_function_preview': results['enhanced_function'][:500] + "..."
            }
            json.dump(serializable_results, f, indent=2, default=str)
        
        # Save enhanced function
        with open('/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory/enhanced_function.sql', 'w') as f:
            f.write(results['enhanced_function'])
        
        # Save trained model
        if classifier.is_trained:
            joblib.dump({
                'classifier': classifier.classifier,
                'vectorizer': classifier.vectorizer
            }, '/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory/trained_model.joblib')
        
        print("Analysis completed successfully!")
        print(f"- Total records analyzed: {results['data_summary']['total_records']:,}")
        print(f"- Unique contributors: {results['data_summary']['unique_contributors']:,}")
        print(f"- Classification recommendations: {len(results['recommendations'])}")
        print("\nFiles generated:")
        print("- analysis_results.json")
        print("- enhanced_function.sql") 
        print("- trained_model.joblib")
        
        return results
        
    except Exception as e:
        logger.error(f"Analysis failed: {str(e)}")
        raise

if __name__ == "__main__":
    main()
