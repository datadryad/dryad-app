import json
from pprint import pprint
from frictionless import Detector, validate, validate_resource
import requests
import sys

def lambda_handler(event, context):
  detector = Detector(field_missing_values="na,n/a,.,none,NA,N/A,N.A.,n.a.,-,empty,blank".split(","))
  try:
    report = validate(event['download_url'], "resource", detector=detector)
  except Exception as exception:
    print(exception)

  headers = {'Authorization': f'Bearer {event["token"]}'}
  r = requests.put(event['callback_url'], headers=headers)
  pprint(r)

  return json.dumps({'status': r.status_code})