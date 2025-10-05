#!/usr/bin/env python3
"""
Analyze Others category and Pohlad family for reclassification improvements
"""

import pandas as pd
from collections import Counter
import numpy as np

def analyze_others_category():
    """Analyze the Others category to identify improvement opportunities"""
    
    # Load the enhanced classification results
    df = pd.read_csv('/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory/outputs/enhanced_classification_20251005_065918.csv')

    print('=== ANALYZING OTHERS CATEGORY FOR IMPROVEMENT ===')
    print()

    # Focus on Others category
    others_df = df[df['enhanced_category'] == 'Others'].copy()
    print(f'Total Others records: {len(others_df):,} ({len(others_df)/len(df)*100:.1f}%)')
    print(f'Others contribution amount: ${others_df["contribution_amount"].sum():,.2f}')
    print()

    # Analyze employer patterns in Others category
    print('=== TOP EMPLOYERS IN OTHERS CATEGORY ===')
    employer_counts = others_df['contributor_employer'].value_counts().head(20)
    for employer, count in employer_counts.items():
        if pd.notna(employer) and str(employer).strip():
            amount = others_df[others_df['contributor_employer'] == employer]['contribution_amount'].sum()
            print(f'{str(employer)[:60]:<60} | {count:4d} contributions | ${amount:>10,.2f}')

    print()

    # Analyze common patterns that could be reclassified
    print('=== POTENTIAL RECLASSIFICATION PATTERNS ===')

    # Look for business-related terms
    business_patterns = [
        'LLC', 'INC', 'CORP', 'COMPANY', 'BUSINESS', 'ENTERPRISES', 'GROUP',
        'CONSULTING', 'SERVICES', 'SOLUTIONS', 'PARTNERS', 'CAPITAL',
        'INVESTMENTS', 'MANAGEMENT', 'HOLDINGS', 'VENTURES'
    ]

    business_reclassifications = []
    for pattern in business_patterns:
        matches = others_df[others_df['contributor_employer'].str.contains(pattern, case=False, na=False)]
        if len(matches) > 5:  # Only show patterns with significant volume
            total_amount = matches['contribution_amount'].sum()
            print(f'{pattern:15} | {len(matches):4d} records | ${total_amount:>10,.2f} | Suggest: BusinessOwner')
            business_reclassifications.extend(matches.index.tolist())

    print()

    # Look for professional services
    professional_patterns = [
        ('ATTORNEY', 'Lawyer'), ('LAW FIRM', 'Lawyer'), ('LEGAL', 'Lawyer'), 
        ('COUNSELOR', 'Lawyer'), ('BARRISTER', 'Lawyer'),
        ('ACCOUNTANT', 'BusinessOwner'), ('CPA', 'BusinessOwner'), ('ACCOUNTING', 'BusinessOwner'), 
        ('FINANCIAL', 'BusinessOwner'), ('ADVISOR', 'BusinessOwner'),
        ('CONSULTANT', 'BusinessOwner'), ('ENGINEERING', 'BusinessOwner'), 
        ('ARCHITECT', 'BusinessOwner'), ('MEDICAL', 'BusinessOwner'), ('DOCTOR', 'BusinessOwner')
    ]

    lawyer_reclassifications = []
    professional_reclassifications = []
    
    for pattern, suggested_category in professional_patterns:
        matches = others_df[others_df['contributor_employer'].str.contains(pattern, case=False, na=False)]
        if len(matches) > 3:
            total_amount = matches['contribution_amount'].sum()
            print(f'{pattern:15} | {len(matches):4d} records | ${total_amount:>10,.2f} | Suggest: {suggested_category}')
            if suggested_category == 'Lawyer':
                lawyer_reclassifications.extend(matches.index.tolist())
            else:
                professional_reclassifications.extend(matches.index.tolist())

    print()

    # Look for government/public sector
    government_patterns = [
        'CITY OF', 'COUNTY', 'STATE OF', 'GOVERNMENT', 'PUBLIC', 'MUNICIPAL',
        'SCHOOL DISTRICT', 'UNIVERSITY', 'COLLEGE', 'DEPARTMENT OF'
    ]

    individual_reclassifications = []
    for pattern in government_patterns:
        matches = others_df[others_df['contributor_employer'].str.contains(pattern, case=False, na=False)]
        if len(matches) > 2:
            total_amount = matches['contribution_amount'].sum()
            print(f'{pattern:15} | {len(matches):4d} records | ${total_amount:>10,.2f} | Suggest: Individual')
            individual_reclassifications.extend(matches.index.tolist())

    print()

    # High-value Others that need manual review
    print('=== HIGH-VALUE OTHERS NEEDING REVIEW ===')
    high_value_others = others_df[others_df['contribution_amount'] > 1000].sort_values('contribution_amount', ascending=False)
    print(f'High-value Others (>$1000): {len(high_value_others)} records totaling ${high_value_others["contribution_amount"].sum():,.2f}')
    print()
    print('Top 10 high-value Others:')
    for _, row in high_value_others.head(10).iterrows():
        employer_str = str(row['contributor_employer']) if pd.notna(row['contributor_employer']) else 'N/A'
        print(f'${row["contribution_amount"]:>8,.2f} | {row["contributor_name"][:40]:<40} | {employer_str[:40]}')

    print()

    # Current Pohlad family analysis
    print('=== CURRENT POHLAD FAMILY CLASSIFICATION ===')
    pohlad_df = df[df['enhanced_category'] == 'Pohlad family']
    print(f'Current Pohlad family records: {len(pohlad_df)}')
    print(f'Pohlad family total amount: ${pohlad_df["contribution_amount"].sum():,.2f}')

    # Also check for Pohlad in Others and Individual categories
    pohlad_in_others = df[(df['contributor_name'].str.contains('POHLAD', case=False, na=False)) & 
                         (df['enhanced_category'] != 'Pohlad family')]
    if len(pohlad_in_others) > 0:
        print(f'Pohlad family members in other categories: {len(pohlad_in_others)}')
        pohlad_category_dist = pohlad_in_others['enhanced_category'].value_counts()
        for category, count in pohlad_category_dist.items():
            print(f'  {category}: {count} records')

    print()
    
    # Summary of potential improvements
    total_potential_reclassifications = len(set(
        business_reclassifications + lawyer_reclassifications + 
        professional_reclassifications + individual_reclassifications
    ))
    
    print('=== IMPROVEMENT POTENTIAL SUMMARY ===')
    print(f'Total Others records that could be reclassified: {total_potential_reclassifications:,}')
    print(f'Potential reduction in Others category: {total_potential_reclassifications/len(others_df)*100:.1f}%')
    print(f'New Others percentage would be: {(len(others_df)-total_potential_reclassifications)/len(df)*100:.1f}%')
    
    return {
        'business_patterns': business_reclassifications,
        'lawyer_patterns': lawyer_reclassifications, 
        'professional_patterns': professional_reclassifications,
        'individual_patterns': individual_reclassifications,
        'total_reclassifications': total_potential_reclassifications
    }

if __name__ == "__main__":
    results = analyze_others_category()
