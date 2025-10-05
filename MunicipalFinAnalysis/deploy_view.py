from google.cloud import bigquery
import os

client = bigquery.Client(project='campaignanalytics-182101')

# Read the SQL file
with open('All_Contributions_View.sql', 'r') as f:
    view_sql = f.read()

print('🚀 Deploying Enhanced All_Contributions_View with Classification...')
print()

try:
    # Execute the view creation
    job = client.query(view_sql)
    job.result()  # Wait for completion
    
    print('✅ View deployed successfully!')
    print('📍 Location: campaignanalytics-182101.Munidata.Mpls_All_Contributions_View')
    print()
    
    # Test the view with a sample of data
    test_query = '''
    SELECT 
        contributor_name,
        contributor_employer,
        contributor_classification,
        contribution_amount,
        candidate_name,
        source_type
    FROM `campaignanalytics-182101.Munidata.Mpls_All_Contributions_View`
    ORDER BY contribution_amount DESC
    LIMIT 10
    '''
    
    print('🧪 Testing view with top 10 contributions...')
    results = client.query(test_query).to_dataframe()
    
    print('✅ Sample Results:')
    print('Name                     Employer             Classification  Amount     Candidate')
    print('-' * 100)
    
    for _, row in results.iterrows():
        name = str(row['contributor_name'])[:24] if row['contributor_name'] else 'Unknown'
        employer = str(row['contributor_employer'])[:19] if row['contributor_employer'] else 'None'
        classification = str(row['contributor_classification'])
        amount = f"${row['contribution_amount']:,.0f}" if row['contribution_amount'] else '$0'
        candidate = str(row['candidate_name'])[:14] if row['candidate_name'] else 'Unknown'
        print(f'{name:<25} {employer:<20} {classification:<15} {amount:<10} {candidate:<15}')
    
    print()
    
    # Get classification distribution
    dist_query = '''
    SELECT 
        contributor_classification,
        COUNT(*) as count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage,
        ROUND(SUM(contribution_amount), 2) as total_amount
    FROM `campaignanalytics-182101.Munidata.Mpls_All_Contributions_View`
    GROUP BY contributor_classification
    ORDER BY count DESC
    '''
    
    print('📊 Getting classification distribution...')
    dist_results = client.query(dist_query).to_dataframe()
    
    print('✅ Classification Distribution:')
    print('Category         Count    Percentage Total Amount')
    print('-' * 50)
    
    for _, row in dist_results.iterrows():
        category = str(row['contributor_classification'])
        count = f"{row['count']:,}"
        percentage = f"{row['percentage']}%"
        total = f"${row['total_amount']:,.0f}"
        print(f'{category:<15} {count:<8} {percentage:<10} {total:<15}')
    
    print()
    print('🎯 Enhanced View Features:')
    print('   ✅ Automatic classification for all contributions')
    print('   ✅ Pohlad family merged into BusinessOwner category')
    print('   ✅ Enhanced business entity detection (LLC, Inc, Corp)')
    print('   ✅ Comprehensive employer pattern matching')
    print('   ✅ Ready for analysis and reporting')
    print()
    print('🚀 Enhanced All_Contributions_View is ready for production use!')
    
except Exception as e:
    print(f'❌ Error deploying view: {e}')
