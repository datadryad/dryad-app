import re
import json
import time
import pandas as pd
import requests
from document_scanner import DocumentScanner

# event json has these params passed in: download_url, callback_url, file_mime_type, token
def lambda_handler(event, context):
  file_path = event["download_url"]
  ftype = event.get("file_mime_type", '')

  xml_doublecheck = ftype == 'text/plain' and event["download_url"].endswith('.xml')
  json_doublecheck = ftype == 'text/plain' and event["download_url"].endswith('.json')
  file_path = event["download_url"]


  if ftype.endswith('/xml') or xml_doublecheck:
    scanner = DocumentScanner(file_path)
  elif ftype.endswith('/xlsx'):
    scanner = XlsxScanner(file_path)
  else:
    scanner = DocumentScanner(file_path)

  response = scanner.scan()
  response.process_data()

  report_status = "noissues"
  if not response.valid:
    if response.has_errors():
      print(f"Errors: {response.errors}")
      report_status = "error"
    else:
      report_status = "issues"

  update(token=event["token"], status=report_status, report=json.dumps({'report': response.__dict__}), callback=event['callback_url'])

  json_report = json.dumps(response.__dict__)
  return json_report

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


def print_response(response):
  response = json.loads(response)
  for pattern in response:
    pattern_occurrences = response[pattern]
    if pattern_occurrences:
      print(f"{pattern} issues")
      for issue in pattern_occurrences:
        print(f"Line {issue['line_number']}: {issue['matches']}")



# Example usage:
file_path = "./example.txt"  # Path to the file
event = {"download_url": file_path, "callback_url": "http://localhost:3000/api/v2/files/39/piiScanReport", "file_mime_type": "text/plain", "token": "_4qxQn4D0ROVKJ93geZro2dSq49Mn-7C5w_GDFvrxxs"}
# print(file_path, event)
response  = lambda_handler(event, context=None)
# print_response(response)


# file_path = "./example.csv"  # Path to the file
# event = {"download_url": file_path, "callback_url": "https://api.example.com/callback", "file_mime_type": "text/plain", "token": "my_secret_token"}
#
# response  = lambda_handler(event, context=None)
# print_response(response)



# file_path = "./example.xlsx"  # Path to the file
# event = {"download_url": file_path, "callback_url": "https://api.example.com/callback", "file_mime_type": "text/plain", "token": "my_secret_token"}
#
# response  = lambda_handler(event, context=None)
# print_response(response)


def check_extension(file_name):
  _, file_extension = os.path.splitext(self.file_path)
  file_extension = file_extension.lower()

  if file_extension in ['.xls', '.xlsx']:
    print(f"'{self.file_path}' is an Excel file.")
  elif file_extension == '.csv':
    print(f"'{self.file_path}' is a CSV file.")
  elif file_extension in ['.txt', '.log']:
    print(f"'{self.file_path}' is a text file.")
  else:
    print(f"'{self.file_path}' has an unrecognized file type.")
