import re
import json
from document_scanner import DocumentScanner
import pandas as pd
import magic


# event json has these params passed in: download_url, callback_url, file_mime_type, token
def lambda_handler(event, context):
  print(event)
  file_path = event["download_url"]
  ftype = event.get("file_mime_type", '')

  xml_doublecheck = ftype == 'text/plain' and event["download_url"].endswith('.xml')
  json_doublecheck = ftype == 'text/plain' and event["download_url"].endswith('.json')
  file_path = event["download_url"]
  print(' ')
  mime_type = magic.from_file(file_path, mime=True)
  print(mime_type)
  print(ftype)
  print(' ')


  if ftype.endswith('/xml') or xml_doublecheck:
    scanner = DocumentScanner(file_path)
  elif ftype.endswith('/xlsx'):
    scanner = XlsxScanner(file_path)
  else:
    scanner = DocumentScanner(file_path)

  print(scanner)
  response = scanner.scan()
  print(response)
  return response

#   update(token=event["token"], status=True, report=json.dumps({'report': report.to_dict()}), callback=event['callback_url'])

#   return report.to_dict()

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
  for pattern_name, pattern_occurrences in response.__dict__.items():
    if pattern_occurrences:
      print(f"{pattern_name.capitalize()} found in the file:")
      for line_number, matches in pattern_occurrences:
        print(f"Line {line_number}: {matches}")




# Example usage:
file_path = "/Users/alin/work/dryad-app/script/sensitive_data/example.txt"  # Path to the file
event = {"download_url": file_path, "callback_url": "https://api.example.com/callback", "file_mime_type": "text/plain", "token": "my_secret_token"}

response  = lambda_handler(event, context=None)
print_response(response)


file_path = "/Users/alin/work/dryad-app/script/sensitive_data/example.csv"  # Path to the file
event = {"download_url": file_path, "callback_url": "https://api.example.com/callback", "file_mime_type": "text/plain", "token": "my_secret_token"}

response  = lambda_handler(event, context=None)
print_response(response)



file_path = "/Users/alin/work/dryad-app/script/sensitive_data/example.xlsx"  # Path to the file
event = {"download_url": file_path, "callback_url": "https://api.example.com/callback", "file_mime_type": "text/plain", "token": "my_secret_token"}

response  = lambda_handler(event, context=None)
print_response(response)

# scanner = Scanner(file_path)
# response = scanner.scan()
#
# scanner.check_extension
#
# for pattern_name, pattern_occurrences in response.__dict__.items():
#   if pattern_occurrences:
#     print(f"{pattern_name.capitalize()} found in the file:")
#     for line_number, matches in pattern_occurrences:
#       print(f"Line {line_number}: {matches}")
#
# # print(f"SSNs: {response.ssns}")
# print(f"Addresses: {response.addresses}")
# # print(f"Emails: {response.emails}")
# # print(f"URLs: {response.urls}")