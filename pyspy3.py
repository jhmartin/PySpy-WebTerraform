"""AWS Lambda handler that looks up EVE Online character intel from DynamoDB by name."""
# pylint: disable=duplicate-code

import json
import decimal
import os
import re
import time
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['table'])

NAME_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9\-' ]*[A-Za-z0-9]$")

# This API is only meant to be consumed by a Python client, so these headers
# discourage browsers from rendering or embedding the response.
BROWSER_DISSUASION_HEADERS = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
    'Content-Disposition': 'attachment',
}

# A local, in-memory cache that persists across invocations on the same
# warm execution environment. Disable by setting the cache_enabled
# environment variable to "false".
CACHE_TTL_SECONDS = 30
CACHE_MAX_SIZE = 1000
CACHE_ENABLED = os.environ.get('cache_enabled', 'true').lower() != 'false'
_cache = {}


def get_cached_response(key):
    """Return a cached response for key, or None if absent/expired/disabled."""
    if not CACHE_ENABLED:
        return None
    cached = _cache.get(key)
    if cached is None:
        return None
    expires_at, response = cached
    if time.monotonic() >= expires_at:
        del _cache[key]
        return None
    return response


def set_cached_response(key, response):
    """Store a response in the local cache.

    Purges expired entries and enforces CACHE_MAX_SIZE so the cache does
    not grow unbounded across the lifetime of a warm execution environment.
    """
    if not CACHE_ENABLED:
        return
    now = time.monotonic()
    for cached_key, (expires_at, _) in list(_cache.items()):
        if expires_at <= now:
            del _cache[cached_key]
    if len(_cache) >= CACHE_MAX_SIZE:
        oldest_key = min(_cache, key=lambda k: _cache[k][0])
        del _cache[oldest_key]
    _cache[key] = (now + CACHE_TTL_SECONDS, response)


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder that converts Decimal values to int."""

    def default(self, o):
        if isinstance(o, decimal.Decimal):
            return int(o)
        return super().default(o)


def bad_request(reason: str) -> dict:
    """Build a 400 response body with the given reason."""
    return {
        'statusCode': 400,
        'body': reason,
        'headers': {
            **BROWSER_DISSUASION_HEADERS,
            'Cache-Control': 'max-age=31536000',
        },
    }


def validate_name(name: str) -> str:
    """Validate an EVE Online character name.

    Returns an error reason if the name is invalid, or an empty string if
    the name is valid.
    """
    if len(name) < 3:
        return 'Name must be at least 3 characters'
    if len(name) > 37:
        return 'Name cannot exceed 37 characters'
    if not NAME_PATTERN.fullmatch(name):
        return 'Name contains invalid characters'

    parts = name.rsplit(' ', 1)
    given_name = parts[0]
    family_name = parts[1] if len(parts) > 1 else ''

    if len(given_name) > 24:
        return 'Name cannot exceed 24 characters'
    if len(family_name) > 12:
        return 'Family name cannot exceed 12 characters'

    return ''


def lambda_handler(event, _):
    """Look up a character's intel record in DynamoDB by name."""
    # Ensure we got the correct parameters
    query_params = event.get('queryStringParameters') or {}
    if 'name' not in query_params:
        return bad_request('Missing name')
    name = query_params['name']

    # Check that the parameter is a valid character name
    invalid_reason = validate_name(name)
    if invalid_reason:
        return bad_request(invalid_reason)

    cached_response = get_cached_response(name)
    if cached_response is not None:
        return cached_response

    # Fetch the item from DynamoDB
    try:
        response = table.get_item(Key={'name': name})
    except ClientError as err:
        if err.response['Error']['Code'] not in [
                "ProvisionedThroughputExceededException"]:
            raise err
        return {'statusCode': 429,
                'body': 'Excessive requests',
                'headers': {
                    **BROWSER_DISSUASION_HEADERS,
                    'Cache-Control': 'max-age=300',
                },
                }

    result = {'name': name}
    item = response.get('Item', {})
    item = item | result

    response_payload = {
        'statusCode': 200,
        'body': json.dumps(item, cls=DecimalEncoder),
        'headers': {
            **BROWSER_DISSUASION_HEADERS,
            'Content-Type': 'application/json',
        },
    }
    set_cached_response(name, response_payload)
    return response_payload
