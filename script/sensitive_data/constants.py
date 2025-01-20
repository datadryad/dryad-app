# Regular expression pattern for SSN (format: XXX-XX-XXXX)
SSN_PATTERN = r"\b\d{3}-\d{2}-\d{4}\b"

# Regular expression pattern for US mailing addresses
# Matches common address formats like: "123 Main St, Springfield, IL 62704"
ADDRESS_PATTERN = r'\d{1,5}\s\w+\s\w+,\s\w+,\s[A-Z]{2}\s\d{5}(-\d{4})?'

# Regular expression pattern for email addresses
EMAIL_PATTERN = r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'

# Regular expression pattern for web URLs
URL_PATTERN = r'(?:(?:https?|ftp)://)?(?:www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[^\s]*)?(?:\?[^\s]*)?(?:#[^\s]*)?'

# Regular expression to match latitude and longitude
# Latitude: -90.0000 to 90.0000
# Longitude: -180.0000 to 180.0000
COORD_PATTERN = r"\(?(-?\d{1,2}(?:\.\d+)?),\s*(-?\d{1,3}(?:\.\d+)?)\)?"

CUTOFF_ERROR_COUNT = 20
