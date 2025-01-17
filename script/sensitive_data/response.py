class Response:
  def __init__(self):
    self.errors = list()
    self.valid = True
    self.issues = list()
    self.run_time = 0
    self.finished = False

  def process_data(self):
    self.issues = sorted(self.issues, key=lambda x: x['line_number'])
    self.valid = not self.has_errors() and not self.has_issues()

  def has_issues(self):
    return len(self.issues) > 0

  def has_errors(self):
    return len(self.errors) > 0
