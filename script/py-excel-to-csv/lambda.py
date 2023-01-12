import json
import pandas as pd
import requests

# event json has these params passed in: download_url, filename, callback_url, token, processor_obj
# the filename is tricky to parse out of http request (sometimes in content-disposition and sometimes not), so just pass it from our DB
def lambda_handler(event, context):
  update_processor_results(event['processor_obj'], event['callback_url'], event['token'])
  return {
    'statusCode': 200,
    'body': event
  }

def update_processor_results(processor_obj, callback_url, token):
  headers = {'Authorization': f'Bearer {token}'}
  update = processor_obj.copy()
  # the following setting are just for testing
  update['completion_state'] = 'processing'
  update['message'] = 'This is a new message'
  update['structured_info'] = processor_obj

  for i in range(0,5):
    r = requests.put(callback_url, headers=headers, json=update)
    if r.status_code < 400:
      break
    else:
      time.sleep(5)

  return r.status_code



class ExcelToCsv:
  def __init__(self, download_url, filename, callback_url, token, processor_object):
    self.download_url = download_url
    self.filename = filename
    self.callback_url = callback_url
    self.token = token

  def download_excel():
    r = requests.get(url, allow_redirects=True)

  # tries to upload it to our API, TODO: needs to be fixed
  def update_status(token, status, report, callback):
    headers = {'Authorization': f'Bearer {token}'}
    update = { 'status': status, 'report': report }
    for i in range(0,5):
      r = requests.put(callback, headers=headers, json=update)
      if r.status_code < 400:
        break
      else:
        time.sleep(5)

    return r.status_code