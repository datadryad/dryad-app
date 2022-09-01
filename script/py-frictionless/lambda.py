import json
from pprint import pprint
from frictionless import Detector, validate, validate_resource
import requests
import sys

def lambda_handler(event, context):
  detector = Detector(field_missing_values="na,n/a,.,none,NA,N/A,N.A.,n.a.,-,empty,blank".split(","))
  try:
    report = validate(event["download_url"], "resource", detector=detector)
  except Exception as e:
    update(token=event["token"], status='error', report=str(e), callback=event["callback_url"] )
    return {"status": 200, "message": "Error parsing file with Frictionless"}

  s = update(token=event["token"], status='issues', \
    report=json.dumps({'report': report}), callback=event['callback_url'])
  return {'status': s, 'Updated report in Dryad API'}

# tries to upload it to our API
def update(token, status, report, callback):
  headers = {'Authorization': f'Bearer {token}'}
  update = { 'status': status, 'report': report }
  r = requests.put(callback, headers=headers, json=update)
  return r.status_code

# handle these HTTP::Error for downloading file

# !result['errors'].empty? means there was an error while validating -->  @report.update(report: result_hash
# .to_json, status:  'error') -- it's an error parsing or doing the frictionless

# result[:report]['tasks'].first['errors'].empty? then 'noissues' else 'issues' -- this is the actual result