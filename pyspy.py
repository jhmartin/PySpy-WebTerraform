import boto3
import json
import decimal

# Initialize a boto3 client for DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('pyspy-intel')

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return int(o)
        return super().default(o)

def lambda_handler(event, context):
    character_id = event['queryStringParameters']['character_id']
    
    # Fetch the item from DynamoDB
    response = table.get_item(
        Key={
            'character_id': int(character_id)
        }
     )
    
    item = response.get('Item', {})
    
    return {
        'statusCode': 200,
        'body': json.dumps(item, cls=DecimalEncoder),
        'headers': {
            'Content-Type': 'application/json'
        },
     }
