import re
from response import Response
import constants as const
import requests

class DocumentScanner:
  def __init__(self, file_path):
    self.file_path = file_path
    self.response = Response()
    self.file_contents = self.read_file()

  def patterns(self):
    return {
      "ssns": const.SSN_PATTERN,
      "addresses": const.ADDRESS_PATTERN,
      "emails": const.EMAIL_PATTERN,
      "urls": const.URL_PATTERN,
      "coordinates": const.COORD_PATTERN
    }

  def read_file(self):
    try:
      response = requests.get(self.file_path)

      # Check if the request was successful
      if response.status_code == 200:
        # Decode the content to a string (assuming it's text)
        return response.text
      else:
        print(f"Failed to retrieve the file. Status code: {response.status_code}")
        return None

    except FileNotFoundError:
      self.response.errors.append(f"File not found: {self.file_path}")
    except Exception as e:
      self.response.errors.append(f"An error occurred: {e}")

  def scan_for_pattern(self, pattern, pattern_name):
    if self.file_contents is None:
      print("File content is empty.")
      return False

    line_number = 0
    occurrences = []

    # Loop through each line in the file
    for line in self.file_contents.splitlines():
      line_number += 1
      # Search for for matches in the current line
      matches = re.findall(pattern, line)

      if matches:
        # Store the line number and matches for each occurrence
        occurrences.append({"line_number": line_number, "matches": matches, "pattern": pattern_name})

    return occurrences

  def scan(self):
    if not self.response.errors:
      for pattern_name, pattern in self.patterns().items():
        issues = self.scan_for_pattern(pattern, pattern_name)
        if issues:
          self.response.issues.extend(issues)
    return self.response