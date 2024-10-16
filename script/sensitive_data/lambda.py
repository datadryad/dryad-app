import re
import json
import time
import pandas as pd
import requests
import os
from urllib.parse import urlparse
from document_scanner import DocumentScanner
from response import Response

# event json has these params passed in: download_url, callback_url, file_mime_type, token
def lambda_handler(event, context):
  download_url = event['download_url']
  file_extension = get_file_extension(download_url)

  if file_extension in ['.txt', '.log', '.csv']:
    scanner = DocumentScanner(download_url)
    response = scanner.scan()
    response.process_data()

    report_status = "noissues"
    if not response.valid:
      if response.has_errors():
        report_status = "error"
      else:
        report_status = "issues"
  else:
    response = file_not_supported_response()
    report_status = "noissues"

  # Send report to callback_url
  update(token=event["token"], status=report_status, report=json.dumps({'report': response.__dict__}), callback=event['callback_url'])

  json_report = json.dumps(response.__dict__)
  return json_report

def get_file_extension(url):
  parsed_url = urlparse(url)
  file_path = parsed_url.path
  return os.path.splitext(file_path)[1]

def file_not_supported_response():
  response = Response()
  response.errors = ['File type not supported']
  return response

# Print readable response
# For debugging purposes
def print_response(response):
  response = json.loads(response)
  print(f"Valid: {response['valid']}")

  pattern_occurrences = response['issues']
  if pattern_occurrences:
    for issue in pattern_occurrences:
      print(f"Line {issue['line_number']}: {issue['pattern']} -> {issue['matches']}")

  if response['errors']:
    print(f"Errors: {response['errors']}")

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
