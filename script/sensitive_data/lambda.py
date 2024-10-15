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



callback = "http://localhost:3000/api/v2/files/42/piiScanReport"
token = "uQ_KnvRsDXHpC9G5Iq1rADVkXYiz41wszeYdxF-5HO4"

# Example usage:
file_path_txt = "https://dryad-alin-test.s3.us-west-2.amazonaws.com/example.txt?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJb%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJGMEQCIGaYRSstou7RxHW0t78xkAlw8xGUR35ln4H1UAwXhvtkAiAejj18d%2BbntasxTXk5dbSEurRxM4keljhzYVV4cYhzGSqEAwjv%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAQaDDcwODk3NDE5NDUwNSIMAhzvjWjtfnLFmMlmKtgC6FzI50Ht%2BkbhnDf2VTZOz80QwaYOv9%2F2RszQOlzJ8YOEiRTsmAnnxxPnv%2Bk5q40Fx3uky%2FDKP4Vqbh61yTjQJnmBhEztlQ8WZ77KcaaojuZvlnhB7BHKAXEdLoERU0Y1KoRSdTmS7WNL8uYxSQU23krop7JFfnBJfR8uK09vVf07uKWKJnabpr8CXNXw5rCumZBJsHYKKd%2FlivOOV1weB3EqXflfiBSbwQ32%2Bew8F3c7rZ4xJKdRISQwWTmyW85IC%2FGhhQ4%2BZOdop2iBwwDgh0MAhK9rGz%2FdbEHwzag1litCt9j7EnNImCVk7JrUgI8%2Bqg2FpnDIRdXVS0cvk6uX2oFS%2FFX%2B5Na6KFM36VmcGnDGyXE0OIheP%2F8TTfUfiqWQe9woCPH9%2FB99gGPmyqMAqI9XxbhyLdYIy7lGTvK4sUdkUu4yLnIRUJWsAORGbVfWwHth%2Fd4PQ2sw7sG5uAY6tAKdi7V2I2r9LJvY7in%2B8nYlOOLLetbFPQvqilCBDYV0RYZS7bLdyuP%2FzMBjwTvphEpXDHYeRe7ZbDTXfAFw3Rj7RfHJAXaQ3Vb%2FMkdUZeaj%2FxJKw4Awuv4%2FmptBALwt5UfgX8PDWDI7vTG09%2FokkfFN1%2B%2F2A0OwAqvghJ54zG%2FVhFktPeG%2Bw%2BCXCeQ1hTKHEydXGvHNWJ2k2a0QKd3nI97WX%2B0L%2BvWCdazp8%2BlkgvaIpDbC%2FzketrXka6poTWJJasOWf2652QgM24eblYw2RhKZnsErt1oYLejfaGOX6cdA9oNmd0nLG3fKoFD0fIdoXVCZYd%2BebM8EXa8fHgQD9KtcdfcRNuHLJmvsDKpX9%2B8dOItg7f1wrUdLXtlYXHE0a1iyDigfalsoyAxg1maMrWni79E%2FNg%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20241015T135132Z&X-Amz-SignedHeaders=host&X-Amz-Expires=36000&X-Amz-Credential=ASIA2KERHV5EY5W4QTQ5%2F20241015%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Signature=8b45281fed16c0f1162f4a63689c59c378d40431505f1e1db6df37d90c99ad7e"
file_path_csv = "https://dryad-alin-test.s3.us-west-2.amazonaws.com/example.csv?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJb%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJGMEQCIGaYRSstou7RxHW0t78xkAlw8xGUR35ln4H1UAwXhvtkAiAejj18d%2BbntasxTXk5dbSEurRxM4keljhzYVV4cYhzGSqEAwjv%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAQaDDcwODk3NDE5NDUwNSIMAhzvjWjtfnLFmMlmKtgC6FzI50Ht%2BkbhnDf2VTZOz80QwaYOv9%2F2RszQOlzJ8YOEiRTsmAnnxxPnv%2Bk5q40Fx3uky%2FDKP4Vqbh61yTjQJnmBhEztlQ8WZ77KcaaojuZvlnhB7BHKAXEdLoERU0Y1KoRSdTmS7WNL8uYxSQU23krop7JFfnBJfR8uK09vVf07uKWKJnabpr8CXNXw5rCumZBJsHYKKd%2FlivOOV1weB3EqXflfiBSbwQ32%2Bew8F3c7rZ4xJKdRISQwWTmyW85IC%2FGhhQ4%2BZOdop2iBwwDgh0MAhK9rGz%2FdbEHwzag1litCt9j7EnNImCVk7JrUgI8%2Bqg2FpnDIRdXVS0cvk6uX2oFS%2FFX%2B5Na6KFM36VmcGnDGyXE0OIheP%2F8TTfUfiqWQe9woCPH9%2FB99gGPmyqMAqI9XxbhyLdYIy7lGTvK4sUdkUu4yLnIRUJWsAORGbVfWwHth%2Fd4PQ2sw7sG5uAY6tAKdi7V2I2r9LJvY7in%2B8nYlOOLLetbFPQvqilCBDYV0RYZS7bLdyuP%2FzMBjwTvphEpXDHYeRe7ZbDTXfAFw3Rj7RfHJAXaQ3Vb%2FMkdUZeaj%2FxJKw4Awuv4%2FmptBALwt5UfgX8PDWDI7vTG09%2FokkfFN1%2B%2F2A0OwAqvghJ54zG%2FVhFktPeG%2Bw%2BCXCeQ1hTKHEydXGvHNWJ2k2a0QKd3nI97WX%2B0L%2BvWCdazp8%2BlkgvaIpDbC%2FzketrXka6poTWJJasOWf2652QgM24eblYw2RhKZnsErt1oYLejfaGOX6cdA9oNmd0nLG3fKoFD0fIdoXVCZYd%2BebM8EXa8fHgQD9KtcdfcRNuHLJmvsDKpX9%2B8dOItg7f1wrUdLXtlYXHE0a1iyDigfalsoyAxg1maMrWni79E%2FNg%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20241015T142614Z&X-Amz-SignedHeaders=host&X-Amz-Expires=43200&X-Amz-Credential=ASIA2KERHV5EY5W4QTQ5%2F20241015%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Signature=f80f8f8c7ba7bf93b683ef679556c913a4501669142123d5054b706f627cbe87"
file_path_xlsx = "https://dryad-alin-test.s3.us-west-2.amazonaws.com/example.xlsx?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJb%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJGMEQCIGaYRSstou7RxHW0t78xkAlw8xGUR35ln4H1UAwXhvtkAiAejj18d%2BbntasxTXk5dbSEurRxM4keljhzYVV4cYhzGSqEAwjv%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAQaDDcwODk3NDE5NDUwNSIMAhzvjWjtfnLFmMlmKtgC6FzI50Ht%2BkbhnDf2VTZOz80QwaYOv9%2F2RszQOlzJ8YOEiRTsmAnnxxPnv%2Bk5q40Fx3uky%2FDKP4Vqbh61yTjQJnmBhEztlQ8WZ77KcaaojuZvlnhB7BHKAXEdLoERU0Y1KoRSdTmS7WNL8uYxSQU23krop7JFfnBJfR8uK09vVf07uKWKJnabpr8CXNXw5rCumZBJsHYKKd%2FlivOOV1weB3EqXflfiBSbwQ32%2Bew8F3c7rZ4xJKdRISQwWTmyW85IC%2FGhhQ4%2BZOdop2iBwwDgh0MAhK9rGz%2FdbEHwzag1litCt9j7EnNImCVk7JrUgI8%2Bqg2FpnDIRdXVS0cvk6uX2oFS%2FFX%2B5Na6KFM36VmcGnDGyXE0OIheP%2F8TTfUfiqWQe9woCPH9%2FB99gGPmyqMAqI9XxbhyLdYIy7lGTvK4sUdkUu4yLnIRUJWsAORGbVfWwHth%2Fd4PQ2sw7sG5uAY6tAKdi7V2I2r9LJvY7in%2B8nYlOOLLetbFPQvqilCBDYV0RYZS7bLdyuP%2FzMBjwTvphEpXDHYeRe7ZbDTXfAFw3Rj7RfHJAXaQ3Vb%2FMkdUZeaj%2FxJKw4Awuv4%2FmptBALwt5UfgX8PDWDI7vTG09%2FokkfFN1%2B%2F2A0OwAqvghJ54zG%2FVhFktPeG%2Bw%2BCXCeQ1hTKHEydXGvHNWJ2k2a0QKd3nI97WX%2B0L%2BvWCdazp8%2BlkgvaIpDbC%2FzketrXka6poTWJJasOWf2652QgM24eblYw2RhKZnsErt1oYLejfaGOX6cdA9oNmd0nLG3fKoFD0fIdoXVCZYd%2BebM8EXa8fHgQD9KtcdfcRNuHLJmvsDKpX9%2B8dOItg7f1wrUdLXtlYXHE0a1iyDigfalsoyAxg1maMrWni79E%2FNg%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20241015T144712Z&X-Amz-SignedHeaders=host&X-Amz-Expires=43200&X-Amz-Credential=ASIA2KERHV5EY5W4QTQ5%2F20241015%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Signature=a920a6f6bfeb78ebb9cccd7a0a50428b76436737214e87a9ac518d3ba14beca0"

event = {"download_url": file_path_txt, "callback_url": callback, "file_mime_type": "text/plain", "token": token}

response  = lambda_handler(event, context=None)
print_response(response)
