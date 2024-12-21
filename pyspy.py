import boto3
import json

def lambda_handler(event, context):
    # Extract the character_id from the event that triggered the lambda
    character_id = event['character_id']
    
    # Initialize a boto3 client for DynamoDB
    dynamodb = boto3.resource('dynamodb')
    
    # Specify the DynamoDB table
    table = dynamodb.Table('pyspy-intel')
    
    # Fetch the item from DynamoDB
    response = table.get_item(
        Key={
            'character_id': character_id
        }
    )
    
    # Extract the item from the response
    item = response.get('Item', {})
    
    # Return the item as JSON
    return {
        'statusCode': 200,
        'body': json.dumps(item),
        'headers': {
            'Content-Type': 'application/json'
        },
    }

