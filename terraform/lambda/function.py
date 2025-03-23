import boto3
from decimal import Decimal
import json  # Make sure to import json for proper JSON formatting

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('resume-challenge-test')  # Make sure this matches your DynamoDB table name

def lambda_handler(event, context):
    try:
        # Get the current visitor count
        response = table.get_item(Key={'id': 'visitor_count'})
        
        # If no count exists, initialize it
        if 'Item' not in response:
            table.put_item(Item={'id': 'visitor_count', 'vcount': Decimal(1)})
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Visitor count initialized', 'count': 1}),
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': '*'
                }
            }
        
        # Otherwise, increment the visitor count
        current_count = response['Item']['vcount']
        new_count = current_count + 1

        # Convert Decimal to float before returning as JSON
        new_count_float = float(new_count)  # Convert Decimal to float
        
        # Update the DynamoDB table with the new count
        table.update_item(
            Key={'id': 'visitor_count'},
            UpdateExpression='SET vcount = :val1',
            ExpressionAttributeValues={':val1': Decimal(new_count_float)}
        )
        
        # Return the updated count as JSON
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Visitor count updated', 'count': new_count_float}),  # Return as JSON
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': '*'
            }
        }
        
    except Exception as e:
        print("Error:", e)  # This will log the specific error
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error updating visitor count.'}),
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': '*'
            }
        }
