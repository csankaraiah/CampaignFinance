#!/usr/bin/env python3
"""
Test the enhanced classification rules
"""

import pandas as pd
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from contribution_classifier import ContributionClassifier
from config import Config

def test_enhanced_classification():
    """Test the enhanced classification rules"""
    
    print('=== TESTING ENHANCED CLASSIFICATION RULES ===')
    print()
    
    # Initialize classifier
    classifier = ContributionClassifier()
    
    # Test cases based on our analysis
    test_cases = [
        # Should be BusinessOwner (was Others)
        ('Conrad LLC', 'John Smith', 'BusinessOwner'),
        ('Business Owner', 'Jane Doe', 'BusinessOwner'), 
        ('Best Buy', 'Employee Name', 'BusinessOwner'),
        ('TCF Bank', 'Bank Employee', 'BusinessOwner'),
        ('Winthrop & Weinstine', 'Attorney Name', 'Lawyer'),
        ('Edina Realty', 'Agent Name', 'BusinessOwner'),
        
        # Pohlad family - should now be BusinessOwner
        ('Not employed', 'Sara Pohlad', 'BusinessOwner'),
        ('Pohlad Family Foundation', 'Jim Pohlad', 'BusinessOwner'),
        
        # Government employees - should be Individual
        ('State of MN', 'Government Worker', 'Individual'),
        ('MPS', 'Teacher Name', 'Individual'),
        
        # Business entities - should be BusinessOwner
        ('ABC LLC', 'Owner Name', 'BusinessOwner'),
        ('XYZ Inc', 'CEO Name', 'BusinessOwner'),
        ('Consulting Services', 'Consultant Name', 'BusinessOwner'),
        
        # Legal professionals - should be Lawyer
        ('Law Firm Partners', 'Attorney Name', 'Lawyer'),
        ('Legal Services', 'Lawyer Name', 'Lawyer'),
        
        # Test existing categories still work
        ('Retired', 'Retiree Name', 'Individual'),
        ('Real Estate Development', 'Developer Name', 'Developer'),
    ]
    
    print('Testing classification rules:')
    print(f'{"Employer":<30} {"Name":<20} {"Expected":<15} {"Actual":<15} {"Status"}')
    print('-' * 100)
    
    correct = 0
    total = len(test_cases)
    
    for employer, name, expected in test_cases:
        actual = classifier.rule_based_classification(employer, name)
        status = '✅ PASS' if actual == expected else '❌ FAIL'
        if actual == expected:
            correct += 1
            
        print(f'{employer:<30} {name:<20} {expected:<15} {actual:<15} {status}')
    
    accuracy = (correct / total) * 100
    print(f'\nTest Results: {correct}/{total} correct ({accuracy:.1f}% accuracy)')
    
    if accuracy < 80:
        print('⚠️  Low accuracy - Rules need adjustment')
    else:
        print('✅ Good accuracy - Rules working well')
    
    print()
    
    # Test with actual data sample
    print('=== TESTING WITH ACTUAL DATA SAMPLE ===')
    
    # Load a small sample of Others category data
    df = pd.read_csv('/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory/outputs/enhanced_classification_20251005_065918.csv')
    others_sample = df[df['enhanced_category'] == 'Others'].head(20)
    
    print('Reclassifying Others sample:')
    print(f'{"Original Employer":<40} {"Enhanced":<15} {"New":<15}')
    print('-' * 70)
    
    improvements = 0
    for _, row in others_sample.iterrows():
        employer = row['contributor_employer']
        name = row['contributor_name']
        original = row['enhanced_category']
        new_category = classifier.rule_based_classification(employer, name)
        
        if new_category != 'Others':
            improvements += 1
            status = '⬆️ IMPROVED'
        else:
            status = '➡️ SAME'
            
        employer_display = str(employer)[:39] if pd.notna(employer) else 'N/A'
        print(f'{employer_display:<40} {original:<15} {new_category:<15} {status}')
    
    improvement_rate = (improvements / len(others_sample)) * 100
    print(f'\nImprovement Rate: {improvements}/{len(others_sample)} ({improvement_rate:.1f}%)')
    
    return accuracy, improvement_rate

if __name__ == "__main__":
    test_accuracy, improvement_rate = test_enhanced_classification()
