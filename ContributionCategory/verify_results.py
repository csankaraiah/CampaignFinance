#!/usr/bin/env python3
"""
Verify BigQuery table and create summary report
"""

from google.cloud import bigquery
import pandas as pd

def main():
    # Initialize BigQuery client
    client = bigquery.Client(project='campaignanalytics-182101')
    
    # Query the uploaded table
    query = """
    SELECT 
        analysis_type,
        category,
        metric_name,
        metric_value,
        percentage,
        ROUND(amount_total, 2) as amount_total,
        description
    FROM `campaignanalytics-182101.Munidata.Enhanced_Classification_Analysis_Summary`
    ORDER BY 
        CASE analysis_type 
            WHEN 'OVERALL_SUMMARY' THEN 1
            WHEN 'CATEGORY_DISTRIBUTION' THEN 2  
            WHEN 'HIGH_VALUE_ANALYSIS' THEN 3
            WHEN 'ML_PERFORMANCE' THEN 4
            ELSE 5
        END,
        metric_value DESC
    """
    
    try:
        results = client.query(query).to_dataframe()
        print('=== ENHANCED CLASSIFICATION ANALYSIS SUMMARY TABLE ===')
        print(f'Total records in table: {len(results)}')
        print()
        
        # Print results in a formatted table
        print(f"{'Analysis Type':<25} {'Category':<15} {'Metric Value':<12} {'Percentage':<10} {'Amount Total':<15}")
        print("-" * 80)
        
        for _, row in results.iterrows():
            analysis_type = row['analysis_type'][:24]
            category = row['category'][:14] 
            metric_value = f"{row['metric_value']:,}"
            percentage = f"{row['percentage']:.1f}%" if row['percentage'] > 0 else "-"
            amount_total = f"${row['amount_total']:,.0f}" if row['amount_total'] > 0 else "-"
            
            print(f"{analysis_type:<25} {category:<15} {metric_value:<12} {percentage:<10} {amount_total:<15}")
        
        print()
        print('=== KEY INSIGHTS ===')
        
        # Extract key insights
        overall_records = results[results['analysis_type'] == 'OVERALL_SUMMARY']['metric_value'].iloc[0]
        print(f"📈 Total Records Analyzed: {overall_records:,}")
        
        # Category distribution insights
        category_data = results[results['analysis_type'] == 'CATEGORY_DISTRIBUTION'].copy()
        category_data = category_data.sort_values('percentage', ascending=False)
        
        print(f"📊 Top Categories by Volume:")
        for _, row in category_data.head(3).iterrows():
            print(f"   • {row['category']}: {row['metric_value']:,} ({row['percentage']:.1f}%)")
        
        # High-value analysis
        high_value_data = results[results['analysis_type'] == 'HIGH_VALUE_ANALYSIS']
        if len(high_value_data) > 0:
            total_high_value = high_value_data['metric_value'].sum()
            total_high_value_amount = high_value_data['amount_total'].sum()
            print(f"💰 High-Value Contributions (>$1000): {total_high_value:,} totaling ${total_high_value_amount:,.0f}")
        
        # ML Performance
        ml_data = results[results['analysis_type'] == 'ML_PERFORMANCE']
        if len(ml_data) > 0:
            accuracy = ml_data['percentage'].iloc[0]
            print(f"🤖 ML Model Accuracy: {accuracy:.0f}%")
        
        print()
        print('✅ CLASSIFICATION ANALYSIS COMPLETE')
        print('   Table Location: campaignanalytics-182101.Munidata.Enhanced_Classification_Analysis_Summary')
        
    except Exception as e:
        print(f'❌ Error querying table: {e}')

if __name__ == "__main__":
    main()
