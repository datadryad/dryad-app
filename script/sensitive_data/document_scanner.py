import re
from response import Response
import constants as const

class DocumentScanner:
  def __init__(self, file_path):
    self.file_path = file_path
    self.file_content = self.read_file()
    self.response = Response()

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
      print(f"File not found: {file_path}")
    except Exception as e:
      print(f"An error occurred: {e}")

  def scan_for_pattern(self, pattern):
    if self.file_content is None:
      print("File content is empty.")
      return False

    line_number = 0
    occurrences = []

    # Open the file and read line by line
    with open(self.file_path, 'r') as file:
      for line in file:
        line_number += 1
        # Search for SSNs in the current line
        matches = re.findall(pattern, line)

        if matches:
          # Store the line number and found SSNs
          occurrences.append((line_number, matches))

    return occurrences

  def check_extension(self):
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

  def scan(self):
    for pattern_name, pattern in self.patterns().items():
      self.response.__setattr__(pattern_name, self.scan_for_pattern(pattern))
    return self.response