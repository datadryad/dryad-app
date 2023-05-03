import json
import time
from pprint import pprint
from frictionless import Detector, validate, validate_resource
from urllib.request import urlopen
import xml.etree.ElementTree as ET
import requests
import sys

# event json has these params passed in: download_url, callback_url, file_mime_type, token
def lambda_handler(event, context):
  ftype = event.get("file_mime_type", '')
  if "xml" in ftype:
    try:
      xmlfile = urlopen(event["download_url"])
      report = ET.parse(xmlfile)
    except ET.ParseError as err:
      # invalid XML
      update(token=event["token"], status='issues', report=json.dumps({'report': f'XML file is invalid: {err}'}), callback=event['callback_url'])
    # valid XML
    update(token=event["token"], status='noissues', report=json.dumps({'report': ''}), callback=event['callback_url'])
  if "json" in ftype:
    try:
      jsonfile = urlopen(event["download_url"])
      report = json.load(jsonfile)
    except ValueError as err:
      # invalid JSON
      update(token=event["token"], status='issues', report=json.dumps({'report': f'JSON file is invalid: {err}'}), callback=event['callback_url'])
    # valid JSON
    update(token=event["token"], status='noissues', report=json.dumps({'report': ''}), callback=event['callback_url'])
    return report
  else:
    detector = Detector(field_missing_values="na,n/a,.,none,NA,N/A,N.A.,n.a.,-,empty,blank".split(","))
    try:
      report = validate(event["download_url"], "resource", detector=detector, limit_errors=10)
    except Exception as e:
      update(token=event["token"], status='error', report=str(e), callback=event["callback_url"] )
      return {"status": 200, "message": "Error parsing file with Frictionless"}

    # these errors indicate a failure by Frictionless to operate on file and are not linting results
    if report["errors"]:
      update(token=event["token"], status='error', report=report, callback=event["callback_url"] )
      return {"status": 200, "message": "Error parsing file with Frictionless"}

    lint_status = "issues" if report["tasks"][0].get("errors") else 'noissues'
    poss_error_msg = ''
    if lint_status == 'issues':
      poss_error_msg = report["tasks"][0]["errors"][0].get("description", "")

    if poss_error_msg.startswith("Data reading error"):
      lint_status = "error"

    update(token=event["token"], status=lint_status, report=json.dumps({'report': report}), callback=event['callback_url'])

    return report

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


