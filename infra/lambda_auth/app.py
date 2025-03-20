
import json
import os
import boto3
from google.oauth2 import id_token
from google.auth.transport import requests

client = boto3.client('dynamodb')

def google_validate_token(token):
    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), os.environ['GOOGLE_CLIENT_ID'])
        print(idinfo)

        # If the token is valid, return the user's email.
        return idinfo['email']
    except ValueError:
        # If the token is invalid, return None.
        return None
    
def dynamodb_validade_email(email):
    try:
        response = client.get_item(
            TableName='users',
            Key={
                'email': {
                    'S': email
                }
            }
        )
        if 'Item' in response:
            return True
        else:
            return False
    except Exception as e:
        print(f"Error validating email: {e}")
        return False
    

def validade_token_and_email(token):
    email = google_validate_token(token)
    if email:
        return dynamodb_validade_email(email)
    else:
        return False


def lambda_handler(event, context):
    print(event)

    # Retrieve request parameters from the Lambda function input:
    headers = event['headers']

    # Parse the input for the parameter values
    tmp = event['methodArn'].split(':')
    apiGatewayArnTmp = tmp[5].split('/')
    resource = '/'

    if (apiGatewayArnTmp[3]):
        resource += apiGatewayArnTmp[3]

    # Perform authorization to return the Allow policy for correct parameters
    # and the 'Unauthorized' error, otherwise.

    token = headers.get('Authorization', headers.get('authorization'))

    if (validade_token_and_email(token)):
        response = generateAllow('me', event['methodArn'])
        print('authorized')
        return response
    else:
        print('unauthorized')
        raise Exception('Unauthorized') # Return a 401 Unauthorized response

    # Help function to generate IAM policy


def generatePolicy(principalId, effect, resource):
    authResponse = {}
    authResponse['principalId'] = principalId
    if (effect and resource):
        policyDocument = {}
        policyDocument['Version'] = '2012-10-17'
        policyDocument['Statement'] = []
        statementOne = {}
        statementOne['Action'] = 'execute-api:Invoke'
        statementOne['Effect'] = effect
        statementOne['Resource'] = resource
        policyDocument['Statement'] = [statementOne]
        authResponse['policyDocument'] = policyDocument

    authResponse['context'] = {
        "stringKey": "stringval",
        "numberKey": 123,
        "booleanKey": True
    }

    print(authResponse)

    return authResponse


def generateAllow(principalId, resource):
    return generatePolicy(principalId, 'Allow', resource)


def generateDeny(principalId, resource):
    return generatePolicy(principalId, 'Deny', resource)