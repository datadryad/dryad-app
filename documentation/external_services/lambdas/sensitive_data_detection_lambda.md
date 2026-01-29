The AWS sensitive data detection Lambda
===========================

The lambda for sensitive data detection uses a very simple model that doesn't maintain any internal
state from one run to another and doesn't access other AWS internal APIs except for
the default logging.
All specific state information it needs per processing request is passed into the Lambda 
and results are returned to the callback URL that is passed in.

INPUT json example:

```json
{
  "download_url": "https://dryad.s3.us-west-2.amazonaws.com/example.txt?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjED0aCXVzLXdlc3QtMiJGMEQCIAJfRUH3GxKiYuWowh67",
  "callback_url": "https://datadryad.org/api/v2/files/1/sensitiveDataReport",
  "token": "uQ_KnvRsDXHpC9G5Iq1rADVkXYiz41wszeYdxF-5HO4"
}
```

- Although the **download\_url** in this example looks like an S3 url, it is a *presigned url*
  which works the same as any HTTP url on the internet that responds to a GET request (during the time it is valid).
- The **callback\_url** is passed in for the current environment to access our own API for updates.
- The **token** is pre-calculated by our ruby code and passed in and will be valid for writing to our own API.

## The easy way to test the lambda locally witout any external server

- Copy the following code into the file called `lambda.py`
```python
def print_response(response):
  response = json.loads(response)
  print(f"Report finished: {response['finished']}")
  print(f"Run time: {response['run_time']} seconds")
  print(f"Valid: {response['valid']}")

  pattern_occurrences = response['issues']
  if pattern_occurrences:
    for issue in pattern_occurrences:
      print(f"Line {issue['line_number']}: {issue['pattern']} -> {issue['matches']}")

  if response['errors']:
    print(f"Errors: {response['errors']}")
  
  print('Report JSON:')
  print(response)
  
callback = "dummy_callback_url"
token = "uQ_KnvRsDXHpC9G5Iq1rADVkXYiz41wszeYdxF-5HO4"

# Example usage:
s3_file_path = "S3_presign_test_file_url"
event = {"download_url": s3_file_path, "callback_url": callback, "token": token}

response  = lambda_handler(event, context=None)
print_response(response)
```
- Replace the `S3_presign_test_file_url` with the actual AWS S3 presigned url of the file you want to test.
- Comment out the line from `lambda.py` that calls the callback API.  
- ```update(token=event["token"], status=report_status, report=json.dumps({'report': response.__dict__}), callback=event['callback_url'])```
- Make sure you have all the required Python libraries installed.
- Run the lambda using the command `python3 lambda.py`

This will print on the screen the list of issues found in your test file as long with the JSON report tat will be sent to the callback URL.
```aiignore
5aa89bb34863ad20115d7a337b479ab0 - parsing file: S3_presign_test_file_url
5aa89bb34863ad20115d7a337b479ab0 - callback_url: dummy_callback_url
5aa89bb34863ad20115d7a337b479ab0 - end parsing with status: issues
Report finished: False
Run time: 4.74 seconds
Valid: False
Line 3: ssns -> ['123-45-6789']
Line 24: addresses -> ['123 Main St, Springfield, IL 62704']
Line 35: emails -> ['support@example.com']
Line 38: emails -> ['sales@company.org', 'feedback+23@company.com.']
Line 46: urls -> ['http://example.com', 'https://www.example.org']
Line 71: ip -> 192.168.1.21
Line 75: ip -> fe80::1
Line 86: endangered_species -> ['Indotestudo forstenii']
Report JSON:
{'errors': [], 'valid': False, 'issues': [{'line_number': 3, 'matches': ['123-45-6789'], 'pattern': 'ssns'}, {'line_number': 24, 'matches': ['123 Main St, Springfield, IL 62704'], 'pattern': 'addresses'}, {'line_number': 35, 'matches': ['support@example.com'], 'pattern': 'emails'}, {'line_number': 38, 'matches': ['sales@company.org', 'feedback+23@company.com.'], 'pattern': 'emails'}, {'line_number': 46, 'matches': ['http://example.com', 'https://www.example.org'], 'pattern': 'urls'}, {'line_number': 71, 'matches': '192.168.1.21', 'pattern': 'ip'}, {'line_number': 75, 'matches': 'fe80::1', 'pattern': 'ip'}, {'line_number': 86, 'matches': ['Indotestudo forstenii'], 'pattern': 'endangered_species'}], 'run_time': 4.74, 'finished': False}
```

## Setting up a local development environment for lambda testing (Unix based OS)
- clone the repository ( https://github.com/CDLUC3/stash_engine.git
- create a python virtual environment using `python3 -m venv venv`
- activate the virtual environment using `source venv/bin/activate`
- install the required python libraries using `pip install library_name`
- got to the lambda script path `cd script/sensitive_data/`
- run lambda `python3 lambda.py`
