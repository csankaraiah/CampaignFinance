"""
Configuration settings for Enhanced Contribution Classification System
"""

import os
from typing import Dict, List

class Config:
    """Configuration class for the classification system"""
    
    # BigQuery settings
    PROJECT_ID = "campaignanalytics-182101"
    DATASET_ID = "MNHenMplsMayorJacobF"
    VIEW_NAME = "All_Contributions_View"
    FUNCTION_DATASET = "MNHenMplsMayorJacobF"
    
    # Data processing settings
    MIN_CONTRIBUTION_AMOUNT = 0
    MAX_CONTRIBUTION_AMOUNT = 100000
    
    # Machine Learning settings
    ML_RANDOM_STATE = 42
    TEST_SIZE = 0.2
    N_ESTIMATORS = 100
    MAX_FEATURES_TFIDF = 1000
    MIN_DF_TFIDF = 2
    NGRAM_RANGE = (1, 2)
    
    # Clustering settings
    N_CLUSTERS = 10
    MIN_CLUSTER_SIZE = 5
    
    # Classification thresholds
    HIGH_CONFIDENCE_THRESHOLD = 0.7
    MEDIUM_CONFIDENCE_THRESHOLD = 0.5
    HIGH_VALUE_CONTRIBUTION = 1000
    
    # File paths
    BASE_DIR = "/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory"
    OUTPUT_DIR = os.path.join(BASE_DIR, "outputs")
    REPORTS_DIR = os.path.join(BASE_DIR, "reports")
    MODELS_DIR = os.path.join(BASE_DIR, "models")
    MODEL_DIR = os.path.join(BASE_DIR, "models")  # Backward compatibility
    
    # Output files
    ANALYSIS_RESULTS_FILE = os.path.join(OUTPUT_DIR, "analysis_results.json")
    ENHANCED_FUNCTION_FILE = os.path.join(OUTPUT_DIR, "enhanced_function.sql")
    TRAINED_MODEL_FILE = os.path.join(MODEL_DIR, "trained_model.joblib")
    CLASSIFICATION_REPORT_FILE = os.path.join(OUTPUT_DIR, "classification_report.html")
    
    # Logging settings
    LOG_LEVEL = "INFO"
    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Category definitions with priorities (higher number = higher priority)
    CATEGORIES = {
        'Pohlad family': 10,
        'Lawyer': 8,
        'Developer': 7,
        'BusinessOwner': 6,
        'Association': 5,
        'Individual': 4,
        'Others': 1
    }
    
    # Enhanced pattern matching rules (updated to reduce Others category)
    ENHANCED_PATTERNS = {
        'lawyer_keywords': [
            'LAW', 'ATTORNEY', 'LEGAL', 'ADVOCATE', 'COUNSEL', 'BARRISTER',
            'SOLICITOR', 'LITIGATION', 'LAW FIRM', 'COUNSELOR', 'PARALEGAL'
        ],
        
        'developer_keywords': [
            'DEVELOPMENT', 'CONSTRUCTION', 'REAL ESTATE', 'ARCHITECT', 
            'BUILDER', 'PROPERTY', 'REALTOR', 'CONTRACTOR', 'ENGINEERING',
            'DESIGN', 'PLANNING', 'URBAN', 'RESIDENTIAL', 'COMMERCIAL'
        ],
        
        'business_owner_keywords': [
            # Leadership titles
            'CEO', 'OWNER', 'FOUNDER', 'PRESIDENT', 'PRINCIPAL', 'PARTNER',
            'EXECUTIVE', 'DIRECTOR', 'MANAGER', 'ENTREPRENEUR', 'CONSULTANT',
            # Business entity types (strong indicators of business ownership)
            'LLC', 'INC', 'CORP', 'COMPANY', 'BUSINESS', 'ENTERPRISES', 'GROUP',
            'CONSULTING', 'SERVICES', 'SOLUTIONS', 'PARTNERS', 'CAPITAL',
            'INVESTMENTS', 'MANAGEMENT', 'HOLDINGS', 'VENTURES',
            # Professional services
            'ACCOUNTANT', 'CPA', 'ACCOUNTING', 'FINANCIAL', 'ADVISOR',
            'ENGINEERING', 'MEDICAL', 'DOCTOR', 'CONSULTANT',
            # Pohlad family (merged into BusinessOwner)
            'POHLAD'
        ],
        
        'association_keywords': [
            'PAC', 'COMMITTEE', 'UNION', 'ASSOCIATION', 'FEDERATION', 
            'COALITION', 'ALLIANCE', 'COUNCIL', 'FUND', 'FOUNDATION',
            'SOCIETY', 'ORGANIZATION', 'INSTITUTE', 'LEAGUE'
        ],
        
        'individual_keywords': [
            'RETIRED', 'NOT EMPLOYED', 'SELF-EMPLOYED', 'HOMEMAKER',
            'STUDENT', 'UNEMPLOYED', 'VOLUNTEER', 'FREELANCE',
            # Government/public sector employees
            'CITY OF', 'STATE OF', 'COUNTY', 'FEDERAL', 'GOVERNMENT',
            'PUBLIC', 'MUNICIPAL', 'DEPARTMENT', 'AGENCY', 'BUREAU',
            'SCHOOL DISTRICT', 'UNIVERSITY', 'COLLEGE'
        ]
    }
    
    # Specific employer name mappings for common misclassifications
    EMPLOYER_MAPPINGS = {
        # High-volume Others that should be BusinessOwner
        'BUSINESS OWNER': 'BusinessOwner',
        'CONRAD LLC': 'BusinessOwner', 
        'WINTHROP & WEINSTINE': 'Lawyer',
        'EDINA REALTY': 'BusinessOwner',
        'TCF BANK': 'BusinessOwner',
        'AMERIPRISE FINANCIAL': 'BusinessOwner',
        'THOMSON REUTERS': 'BusinessOwner',
        'BEST BUY': 'BusinessOwner',
        'MEDICA': 'BusinessOwner',
        'ALLINA HEALTH': 'BusinessOwner',
        # Government employees
        'STATE OF MN': 'Individual',
        'MPS': 'Individual',  # Minneapolis Public Schools
        # Common retirement patterns
        'RETIRED / RETIRED': 'Individual',
        'BOTH RETIRED': 'Individual'
    }
    
    # Industry-specific classifications
    INDUSTRY_MAPPING = {
        'Healthcare': [
            'HOSPITAL', 'MEDICAL', 'HEALTH', 'CLINIC', 'PHYSICIAN',
            'DOCTOR', 'NURSE', 'HEALTHCARE', 'PHARMACY', 'DENTAL'
        ],
        'Technology': [
            'TECH', 'SOFTWARE', 'COMPUTER', 'IT', 'DIGITAL', 'DATA',
            'CYBER', 'INTERNET', 'WEB', 'CLOUD', 'AI', 'MACHINE LEARNING'
        ],
        'Finance': [
            'BANK', 'FINANCIAL', 'INVESTMENT', 'CAPITAL', 'FUND',
            'CREDIT', 'INSURANCE', 'SECURITIES', 'MORTGAGE', 'WEALTH'
        ],
        'Education': [
            'SCHOOL', 'UNIVERSITY', 'COLLEGE', 'EDUCATION', 'ACADEMIC',
            'TEACHER', 'PROFESSOR', 'STUDENT', 'LEARNING', 'RESEARCH'
        ],
        'Non-Profit': [
            'FOUNDATION', 'CHARITY', 'NON-PROFIT', 'NONPROFIT', 'NGO',
            'COMMUNITY', 'SOCIAL', 'HUMANITARIAN', 'ADVOCACY', 'RELIEF'
        ]
    }
    
    @classmethod
    def ensure_directories(cls):
        """Ensure all required directories exist"""
        os.makedirs(cls.OUTPUT_DIR, exist_ok=True)
        os.makedirs(cls.MODEL_DIR, exist_ok=True)
    
    @classmethod
    def get_bigquery_view_path(cls) -> str:
        """Get full BigQuery view path"""
        return f"{cls.PROJECT_ID}.{cls.DATASET_ID}.{cls.VIEW_NAME}"
    
    @classmethod
    def get_function_path(cls, function_name: str) -> str:
        """Get full BigQuery function path"""
        return f"{cls.PROJECT_ID}.{cls.FUNCTION_DATASET}.{function_name}"
