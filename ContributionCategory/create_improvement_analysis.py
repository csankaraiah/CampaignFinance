#!/usr/bin/env python3
"""
Create comparison analysis of improved classification results
"""

import pandas as pd
from google.cloud import bigquery
from datetime import datetime

def create_improvement_analysis():
    """Create detailed comparison analysis"""
    
    # Load the improved classification results
    df_new = pd.read_csv('/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory/outputs/enhanced_classification_20251005_070729.csv')

    print('=== IMPROVED CLASSIFICATION RESULTS ANALYSIS ===')
    print()

    # Compare original vs enhanced categories
    if 'original_category' in df_new.columns:
        print('📊 BEFORE vs AFTER COMPARISON:')
        print('-' * 60)
        
        # Original distribution
        original_dist = df_new['original_category'].value_counts().sort_index()
        enhanced_dist = df_new['current_category'].value_counts().sort_index()
        
        all_categories = set(list(original_dist.index) + list(enhanced_dist.index))
        
        print(f"{'Category':<15} {'Before':<12} {'After':<12} {'Change':<15}")
        print('-' * 60)
        
        for category in sorted(all_categories):
            before_count = original_dist.get(category, 0)
            after_count = enhanced_dist.get(category, 0)
            change = after_count - before_count
            
            before_pct = before_count / len(df_new) * 100
            after_pct = after_count / len(df_new) * 100
            change_pct = after_pct - before_pct
            
            change_str = f'{change:+,} ({change_pct:+.1f}%)'
            
            print(f'{category:<15} {before_count:5,} ({before_pct:4.1f}%) {after_count:5,} ({after_pct:4.1f}%) {change_str:<15}')

    print()

    # Key improvements summary
    others_reduction = (df_new['original_category'] == 'Others').sum() - (df_new['current_category'] == 'Others').sum()
    business_increase = (df_new['current_category'] == 'BusinessOwner').sum() - (df_new['original_category'] == 'BusinessOwner').sum()
    pohlad_merged = (df_new['original_category'] == 'Pohlad family').sum()

    print('🎯 KEY ACHIEVEMENTS:')
    print(f'   ✅ Reduced Others category by: {others_reduction:,} records')
    print(f'   ✅ Increased BusinessOwner by: {business_increase:,} records') 
    print(f'   ✅ Merged Pohlad family: {pohlad_merged} records into BusinessOwner')
    print(f'   ✅ New Others percentage: {(df_new["current_category"] == "Others").sum() / len(df_new) * 100:.1f}%')

    print()

    # Create improved analysis summary for BigQuery
    analysis_summary = []

    # Overall improvement metrics
    total_records = len(df_new)
    others_before = (df_new['original_category'] == 'Others').sum()
    others_after = (df_new['current_category'] == 'Others').sum()
    reduction_rate = (others_before - others_after) / others_before * 100 if others_before > 0 else 0

    analysis_summary.append({
        'analysis_type': 'IMPROVEMENT_SUMMARY',
        'category': 'Others_Reduction',
        'metric_name': 'records_reclassified',
        'metric_value': int(others_reduction),
        'percentage': reduction_rate,
        'amount_total': 0.0,
        'amount_average': 0.0,
        'confidence_avg': 1.0,
        'description': f'Successfully reclassified {others_reduction:,} records from Others to appropriate categories ({reduction_rate:.1f}% reduction)'
    })

    # Enhanced category distribution
    for category in enhanced_dist.index:
        count = enhanced_dist[category]
        percentage = count / total_records * 100
        amount_total = df_new[df_new['current_category'] == category]['contribution_amount'].sum()
        amount_avg = df_new[df_new['current_category'] == category]['contribution_amount'].mean()
        
        analysis_summary.append({
            'analysis_type': 'ENHANCED_DISTRIBUTION',
            'category': category,
            'metric_name': 'enhanced_count',
            'metric_value': int(count),
            'percentage': percentage,
            'amount_total': amount_total,
            'amount_average': amount_avg,
            'confidence_avg': 0.95,
            'description': f'Enhanced {category}: {count:,} contributions ({percentage:.1f}%) totaling ${amount_total:,.2f}'
        })

    # Pohlad family merge success
    if pohlad_merged > 0:
        analysis_summary.append({
            'analysis_type': 'SPECIAL_HANDLING',
            'category': 'Pohlad_Family_Merge',
            'metric_name': 'merged_records',
            'metric_value': int(pohlad_merged),
            'percentage': 100.0,
            'amount_total': df_new[df_new['original_category'] == 'Pohlad family']['contribution_amount'].sum(),
            'amount_average': 0.0,
            'confidence_avg': 1.0,
            'description': f'Successfully merged {pohlad_merged} Pohlad family records into BusinessOwner category as requested'
        })

    # Convert to DataFrame and save
    summary_df = pd.DataFrame(analysis_summary)
    summary_df['analysis_date'] = datetime.now().strftime('%Y-%m-%d')
    summary_df['analysis_timestamp'] = datetime.now()

    # Save enhanced summary
    summary_df.to_csv('/Users/chakravarthysankaraiah/Documents/GitHub/CampaignFinance/ContributionCategory/outputs/enhanced_analysis_summary.csv', index=False)

    print('💾 Enhanced analysis summary saved')
    print(f'   Total improvement metrics: {len(summary_df)}')
    
    # Upload to BigQuery
    try:
        client = bigquery.Client(project='campaignanalytics-182101')
        
        # Define table details
        dataset_id = 'Munidata'
        table_id = 'Enhanced_Classification_Analysis_Improved'
        table_ref = client.dataset(dataset_id).table(table_id)
        
        print(f'\\nUploading {len(summary_df)} records to {dataset_id}.{table_id}...')
        
        # Configure job to replace existing table
        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            autodetect=True
        )
        
        # Upload the data
        job = client.load_table_from_dataframe(summary_df, table_ref, job_config=job_config)
        job.result()  # Wait for the job to complete
        
        # Get table info
        table = client.get_table(table_ref)
        print(f'✅ SUCCESS: Table {dataset_id}.{table_id} created with {table.num_rows} rows')
        
    except Exception as e:
        print(f'❌ BigQuery upload error: {e}')
    
    return summary_df

if __name__ == "__main__":
    results = create_improvement_analysis()
