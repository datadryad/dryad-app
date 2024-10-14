import re
from response import Response
import constants as const

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
      with open(self.file_path, 'r') as file:
        return file.read()

    except FileNotFoundError:
      self.response.errors.append(f"File not found: {self.file_path}")
    except Exception as e:
      self.response.errors.append(f"An error occurred: {e}")

  def scan_for_pattern(self, pattern):
    if self.file_contents is None:
      print("File content is empty.")
      return False

    line_number = 0
    occurrences = []

    # Open the file and read line by line
    with open(self.file_path, 'r') as file:
      for line in file:
        line_number += 1
        # Search for for matches in the current line
        matches = re.findall(pattern, line)

        if matches:
          # Store the line number and matches for each occurrence
          occurrences.append({"line_number": line_number, "matches": matches})

    return occurrences

  def scan(self):
    if not self.response.errors:
      for pattern_name, pattern in self.patterns().items():
        self.response.__setattr__(pattern_name, self.scan_for_pattern(pattern))
    return self.response