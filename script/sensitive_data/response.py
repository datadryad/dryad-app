class Response:
  def __init__(self):
    self.ssns = list()
    self.addresses = list()
    self.emails = list()
    self.urls = list()
    self.coordinates = list()

    self.errors = list()
    self.valid = True
    self.issues = list()

  def checks_values(self):
    keys = ["ssns", "addresses", "emails", "urls", "coordinates"]
    values = [getattr(self, key) for key in keys]
    flattened = [item for sublist in values for item in sublist]
    return flattened

  def process_data(self):
    self.issues = self.checks_values()
    self.valid = self.has_errors() and len(self.issues) == 0

  def has_errors(self):
    return len(self.errors) == 0
