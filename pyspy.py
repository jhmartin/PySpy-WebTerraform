import json
import decimal
import boto3


class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return int(o)
        return super().default(o)


def lambda_handler(event, _):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('pyspy-intel')

    character_id = event['queryStringParameters']['character_id']

    # Fetch the item from DynamoDB
    response = table.get_item(
        Key={
            'character_id': int(character_id)
        }
    )

    result = {'character_id': int(character_id)}
    item = response.get('Item', {})
    item = item | result

    return {
        'statusCode': 200,
        'body': json.dumps(item, cls=DecimalEncoder),
        'headers': {
            'Content-Type': 'application/json'
        },
    }
