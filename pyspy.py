import json
import decimal
import boto3
from botocore.exceptions import ClientError


class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return int(o)
        return super().default(o)


def bad_request(reason: str) -> dict:
    return {
        'statusCode': 400,
        'body': reason
    }


def lambda_handler(event, _):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('pyspy-intel')

    # Ensure we got the correct parameters
    if 'queryStringParameters' not in event or 'character_id' not in event[
            'queryStringParameters']:
        return bad_request('Missing character_id')
    character_id = event['queryStringParameters']['character_id']

    # Check that the parameter is a positive intger
    if not character_id.isdigit():
        return bad_request('Non-numeric character id')

    # Check that the parameter is within sane ranges for character_ids
    if int(character_id) < 90000000 or int(character_id) > 10000000000:
        return bad_request('Character_id out of range')

    # Fetch the item from DynamoDB
    try:
        response = table.get_item(Key={'character_id': int(character_id)})
    except ClientError as err:
        if err.response['Error']['Code'] not in [
                "ProvisionedThroughputExceededException"]:
            raise err
        return {'statusCode': 429,
                'body': 'Excessive requests'
                }

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
