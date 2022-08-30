import json
from pprint import pprint
from frictionless import Detector, validate, validate_resource
import requests
import sys

def lambda_handler(event, context):
  detector = Detector(field_missing_values="na,n/a,.,none,NA,N/A,N.A.,n.a.,-,empty,blank".split(","))
  try:
    report = validate(event["download_url"], "resource", detector=detector)
  except Exception as exception:
    update(token=event["token"], status='error', report='something', callback=event["callback_url"] )

  s = update(token=event["token"], status='issues', \
    report=json.dumps({'report': report}), callback=event['callback_url'])
  return json.dumps({'status': s})

# tries to upload it to our API
def update(token, status, report, callback):
  headers = {'Authorization': f'Bearer {token}'}
  update = { 'status': status, 'report': report }
  r = requests.put(callback, headers=headers, json=update)
  return r.status_code