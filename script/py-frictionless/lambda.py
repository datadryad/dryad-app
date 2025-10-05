import json
import time
from frictionless import Detector, validate
from urllib.request import urlopen
import xml.etree.ElementTree as ET
import defusedxml.ElementTree as DefusedET
import requests
import sys

# event json has these params passed in: download_url, callback_url, file_mime_type, token
def lambda_handler(event, context):
  print(event)
  ftype = event.get("file_mime_type", '')
  xml_doublecheck = ftype == 'text/plain' and event["download_url"].endswith('.xml')
  json_doublecheck = ftype == 'text/plain' and event["download_url"].endswith('.json')
  if ftype.endswith('/xml') or xml_doublecheck:
    try:
      xmlfile = urlopen(event["download_url"])
      report = DefusedET.parse(xmlfile)
    except ET.ParseError as err:
      # invalid XML
      report=json.dumps({'report': f'XML file is invalid: {err}'})
      update(token=event["token"], status='issues', report=report, callback=event['callback_url'])
      return report
    # valid XML
    update(token=event["token"], status='noissues', report=json.dumps({'report': ''}), callback=event['callback_url'])
    return report
  if ftype.endswith('/json') or json_doublecheck:
    try:
      jsonfile = urlopen(event["download_url"])
      report = json.load(jsonfile)
    except ValueError as err:
      # invalid JSON
      report=json.dumps({'report': f'JSON file is invalid: {err}'})
      update(token=event["token"], status='issues', report=report, callback=event['callback_url'])
      return report
    # valid JSON
    update(token=event["token"], status='noissues', report=json.dumps({'report': ''}), callback=event['callback_url'])
    return report
  else:
    detector = Detector(field_missing_values=", ,na,n/a,.,none,NA,N/A,N.A.,n.a.,-,empty,blank".split(","))
    try:
      report = validate(event["download_url"], limit_errors=10, detector=detector)
    except Exception as e:
      update(token=event["token"], status='error', report=str(e), callback=event["callback_url"] )
      return {"status": 200, "message": "Error parsing file with Frictionless"}

    # these errors indicate a failure by Frictionless to operate on file and are not linting results
    if report.errors:
      update(token=event["token"], status='error', report=json.dumps({'report': report.to_dict()}), callback=event["callback_url"] )
      return {"status": 200, "message": "Error parsing file with Frictionless"}

    lint_status = "noissues" if report.valid else 'issues'
    poss_error_msg = ''
    if lint_status == 'issues':
      poss_error_msg = report.tasks[0].errors[0].description

    if poss_error_msg.startswith("Data reading error"):
      lint_status = "error"

    update(token=event["token"], status=lint_status, report=json.dumps({'report': report.to_dict()}), callback=event['callback_url'])

    return report.to_dict()

# tries to upload it to our API
def update(token, status, report, callback):
  headers = {'Authorization': f'Bearer {token}'}
  update = { 'status': status, 'report': report }
  for i in range(0,5):
    r = requests.put(callback, headers=headers, json=update)
    if r.status_code < 400:
      break
    else:
      time.sleep(5)

  return r.status_code


# see terry's info about invoking a lambda
# https://github.com/CDLUC3/mrt-cron/blob/main/consistency-driver/action_caller.rb


