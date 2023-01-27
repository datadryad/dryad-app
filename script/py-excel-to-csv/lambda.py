import json
import time
import pandas
import requests
from pathlib import Path
from datetime import datetime
import re
from urllib.parse import urlparse, quote

# event json has these params passed in: download_url, filename, callback_url, token, doi, processor_obj
# the filename is tricky to parse out of http request (sometimes in content-disposition and sometimes not), so just pass it from our DB
def lambda_handler(event, context):
  # update_processor_results(event['processor_obj'], event['callback_url'], event['token'])
  # TODO: validation of correct events passed in
  set1 = set(event.keys())
  if len(set1.intersection({'download_url', 'callback_url', 'processor_obj', 'doi', 'token', 'filename'})) != 6:
    print('Incorrect elements passed into lambda for ExcelToCsv')
    return

  e2c = ExcelToCsv(event['download_url'], event['filename'], event['callback_url'], event['token'], event['doi'], event['processor_obj'])
  e2c.update_processor_start()

  mypath = e2c.download_excel()
  if(mypath is None): return

  new_files = e2c.extract_worksheets(mypath)
  if(new_files is None): return

  e2c.upload_new_files(new_files)

# standalone methods not part of the ExcelToCsv object
def update_processor_results(processor_obj, callback_url, token):
  headers = {'Authorization': f'Bearer {token}'}

  for i in range(0,5):
    r = requests.put(callback_url, headers=headers, json=processor_obj)
    if r.status_code < 400:
      break
    else:
      print(f'Error from server: code {r.status_code}, try {i}')
      time.sleep(5)

  return r.status_code

def fix_fn(fn):
  return re.sub(r'[^-a-zA-Z0-9_.()]+', '_', fn)

class ExcelToCsv:
  def __init__(self, download_url, filename, callback_url, token, doi, processor_obj):
    self.download_url = download_url
    self.filename = fix_fn(filename)
    self.callback_url = callback_url
    self.token = token
    self.doi = doi
    self.processor_obj = processor_obj

  # updates the processor results in our API, convenience method
  def update_processor(self, state, message, struct_info):
    update = self.processor_obj.copy()
    update['completion_state'] = state
    update['message'] = message
    update['structured_info'] = struct_info
    update_processor_results(update, self.callback_url, self.token)

  # set processor message as started in our API
  def update_processor_start(self):
    self.update_processor('processing', f'started lambda at {datetime.now().isoformat()}', '')
    print(f'Started processing at {datetime.now().isoformat()}')

  # set processor as completed successfully in our API
  def update_processor_success(self, filenames):
    json_out = json.dumps({ "csv_files": filenames })
    self.update_processor('success', f'ended processing lambda at {datetime.now().isoformat()}', json_out)
    print(f'Finished processing at {datetime.now().isoformat()}')

  # set a processor error in our API
  def update_processor_error(self, message):
    self.update_processor('error', f'error lambda at {datetime.now().isoformat()} with message: {message}', '')
    print(f'Finished processing at {datetime.now().isoformat()}')

  # attempt downloading the Excel file
  def download_excel(self):
    # ext = Path(self.filename).suffix
    for i in range(0,5):
      r = requests.get(self.download_url, allow_redirects=True)
      if r.status_code < 400:
        open(f'/tmp/{self.filename}', 'wb').write(r.content)
        print(f'saved to /tmp/{self.filename}')
        return f'/tmp/{self.filename}'
      else:
        print(f'Error from server: code {r.status_code} downloading {self.filename}, try {i}')
        time.sleep(5)

      update = self.processor_obj.copy()
      update['completion_state'] = 'error'
      update['message'] = f'unable to download {self.filename} at {self.download_url} after 5 attempts'
      update_processor_results(update, self.callback_url, self.token)
      return None

  def extract_worksheets(self, mypath):
    try:
      data_frames = pandas.read_excel(mypath, sheet_name=None)
    except ValueError as inst:
      print(f'File {mypath} could not be parsed as an Excel file.  Is the format correct?')
      self.update_processor_error(f'File {mypath} could not be parsed as an Excel file.  Is the format correct?')
      return None

    new_files = []
    for x in data_frames.keys():
      new_fn = f'{Path(mypath).stem}_{fix_fn(x)}.csv'
      data_frames[x].to_csv(f'/tmp/{new_fn}', index=None, header=True)
      print(f'    Created new csv file {new_fn}')
      new_files.append(new_fn)

    return new_files

  def upload_new_files(self, new_files):
    domain = urlparse(self.callback_url).netloc
    headers = {'Authorization': f'Bearer {self.token}', 'Content-Type': 'text/csv'}
    for new_file in new_files:
      url = f'https://{domain}/api/v2/datasets/{quote(self.doi, safe="")}/files/{quote(new_file, safe="")}'

      for i in range(0,5):
        r = requests.put(url, headers=headers, data=open(f'/tmp/{new_file}', 'rb'))
        if r.status_code < 400:
          break
        else:
          print(f'Error from server while uploading {new_file}: code {r.status_code}, try {i}')
          if i == 4:
            print(f'File {new_file} could not be uploaded to the Dryad API with status code: {r.status_code}')
            self.update_processor_error(f'File {new_file} could not be uploaded to the Dryad API with status code: {r.status_code}')
            return None
          time.sleep(5)

    # got through all the uploads of CSVs to our API, now write success
    self.update_processor_success(new_files)
    return



