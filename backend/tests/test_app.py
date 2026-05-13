import json
import pytest
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'visitor_counter'))

with patch('boto3.resource') as mock_resource:
    mock_table = MagicMock()
    mock_resource.return_value.Table.return_value = mock_table
    import app

@pytest.fixture(autouse=True)
def setup_mock_table():
    app.table.update_item.return_value = {
        'Attributes': {
            'count': 11
        }
    }
    yield
    app.table.update_item.reset_mock()

def test_lambda_returns_200():
    response = app.lambda_handler({}, {})
    assert response['statusCode'] == 200

def test_lambda_returns_count():
    response = app.lambda_handler({}, {})
    body = json.loads(response['body'])
    assert body['count'] == 11

def test_lambda_returns_cors_header():
    response = app.lambda_handler({}, {})
    assert response['headers']['Access-Control-Allow-Origin'] == 'https://resume.bachelder.me'

def test_dynamodb_update_called():
    app.lambda_handler({}, {})
    app.table.update_item.assert_called_once()