import hashlib

class Logger:
  def __init__(self, url):
    self.url = url
    self.token = self.generate_worker_token()

  def log(self, message):
    print(f"{self.token} - {message}")

  def generate_worker_token(self):
    md5_hash = hashlib.md5(self.url.encode())
    return md5_hash.hexdigest()
