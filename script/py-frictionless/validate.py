#   frictionless:
#     # 5 MB and below
#      size_limit: 5_000_000
#      missing_values: "na,n/a,.,none,NA,N/A,N.A.,n.a.,-,empty,blank"

# cmd = 'eval "$(pyenv init -)" 2>/dev/null; ' \
#          "frictionless validate --path #{file.path} --json --field-missing-values
#          '#{APP_CONFIG.frictionless.missing_values}' 2>&1"

# it appears that the command line interface is at
# https://github.com/frictionlessdata/frictionless-py/blob/26e2f09ffdcb2ddc9fe2cdcf673e22743e0420ed/frictionless/program/main.py
# it calls super().(*args, **kwargs), seems to be calling typer.Typer

# Typer is a command line utility
# pip install "typer[all]" # includes rich and shellingham

# from typing import Optional # uses type hints see https://docs.python.org/3/library/typing.html
# from .. import settings -- what is this importing? https://docs.python.org/3/reference/import.html

# also has frictionless/plugins/csv/parser.py -- from . import settings
# frictionless/helpers.py

# seems to contain some of the options https://github.com/frictionlessdata/frictionless-py/blob/26e2f09ffdcb2ddc9fe2cdcf673e22743e0420ed/frictionless/program/validate.py
# https://github.com/frictionlessdata/frictionless-py/blob/26e2f09ffdcb2ddc9fe2cdcf673e22743e0420ed/frictionless/program/common.py
# json: bool = common.json
# try these files
# 100 Sales Records.csv
# 100000 Sales Records.csv
# 100000_Sales_Records.csv
# 50000 Sales Records.csv
# anaheim_nodes.json
# cell_culture_gte2.json
# embryos_1_7.json
# file_example_XLS_100.xls
# file_example_XLS_5000--second_tab.xls
# file_example_XLS_5000.xls
# fish_ADR1_PHYLIP_MIX_gte5.json
# fish_ADR2_PHYLIP_MIX_gt5.json
# sampledatafoodsales.xlsx
# sampledatahockey.xlsx
# sampledatainsurance.xlsx
# sampledatasafety.xlsx
# sampledataworkorders.xlsx
# tagged_corpora_20140605.json
# test_files.zip

# URLs on dev
# resource: 3512, file_ids: 10845 (excel), 10846 (json), 10847 (csv)
# file_obj = StashEngine::DataFile.find(10847)
# file_obj.merritt_s3_presigned_url

# csv shows profile 'tabular-data-resource'

# "resource": {
#         "path": "/Users/sfisher/Downloads/zTestJunk/frictionless/tested/fish_ADR2_PHYLIP_MIX_gt5.json",
#         "name": "fish_adr2_phylip_mix_gt5",
#         "profile": "tabular-data-resource",
#         "scheme": "file",
#         "format": "json",
#         "hashing": "md5",
#         "stats": {
#           "hash": "",
#           "bytes": 0,
#           "fields": 17,
#           "rows": 1
#         }

# this would get the latest access token for application in rails
# Doorkeeper.config.application_model.where(id: 1).first.access_tokens.order(created_at: desc).first

from pprint import pprint
from frictionless import Detector, validate, validate_resource
import requests
import sys

CLIENT_ID = '<fill-me>'
CLIENT_SECRET = '<fill-me>'

# my_path = "https://uc3-s3mrt5001-stg.s3.us-west-2.amazonaws.com/ark%3A/99999/fk4z620d9x%7C1%7Cproducer/50000_Sales_Records.csv?response-content-type=text%2Fcsv&X-Amz-Security-Token=IQoJb3JpZ2luX2VjELn%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQClGmbwbhs1E6sQrzwQUk0iOOtsR%2FJC6Da0c06w2o83QwIgRCTbMPbfVcNMQwo4hZuqeF7jrwd%2FnjPRoEZV2EAXgOsq0gQIMRAAGgw0NTE4MjY5MTQxNTciDDQ3otuk%2FBO%2FXS62XSqvBCahlGiNzSo8frIphVbnDIP5RKdf%2B5aQ%2BDHMYe3686r4v%2FAl%2Ftd4n5LBlRXeQ8H7VA2kkwcfx9%2BMhw1BsPISvYSDr6herXDn535%2BLDUlqjnfaBC%2BqhqnZMMr9iXFhSzlOudV8rj6mDmHMg4qB9oy5gjHqqKyCCp%2BBxXndFH6rB4xFk09lfosVIOVQIgBxAPZp9Kylu9%2BM0NMzxjL%2ByhUTNuPAlv8Qdvkl%2F%2F%2FEXOfmiTkgLJQg5B14AoUOKusIqCW5%2BeOs7FHK12dAbE1ZcvxXzj82oGlpdYD0BK3jmHYfzbd3r5%2BF8NoGbiet%2Fg8k9MMUDSeB2%2FGxdd7%2BKE9f11fpNTwgu2b%2BinEWChFwK1pv0mwS6vWuv%2Blpycu0QVddcDVNGaqV8ZBQM0rg2OXIvSWBFeDXgu08uuSF7RYNovQRqG5wWUKmGaWVy65d9VkLIY%2BISwWVLZe8aoqNI1QL5hnYe8zRFnBoRmLbzfRRgr%2BTk1%2F6aFkRKS8PvsIhczGaTzz1QxMQVeydjsvPWjzMKRhJBnX5T0Lz0Klzual2YyIsyV1pU0TybgJUUqjGLONZBVlnaAQXWt55CiKlkC5OMyvtJA%2BMIQs4cTk1s5%2B8Rje7i0u4qz3At7fUSMhAjdr266sEXwaNRS1%2Ba3rp7LM1zG7EbBlv2jCo9bMSJN5gLLss%2BV0vdnVhxNRAlTWcHmDrqv5WV4huNp9D4qQ3N%2BrAc1ynnwDFY%2BTZRqy6bXPt7%2FxrYww8%2FD%2BlwY6qQEpJwvtzh5nzkg1MAFCDiKoXlDauG%2B8XuZesHVgsc8g2eVoeTXoZ03XrgLAMZi7b6A6QqoI%2Fc7UDp%2BjMn1z1FrqEZOfCCUVE1cbFF%2BWqVMmMWjV8x%2BZOHdFZuY%2FtTE9wgOCIB1R5N6JuSqF5DhVzn%2BMCttdx1%2Bj7cgBsw86sDo6w5LbEWKc2Fi2tc3DgLAZWwBjwacHBERdeyVKxvYrRB7%2F2OaF2QGVR0q%2F&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20220819T170155Z&X-Amz-SignedHeaders=host&X-Amz-Expires=14399&X-Amz-Credential=ASIAWSMX3SNWQYP7HU5P%2F20220819%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Signature=a30ab6112a22ba25b8f1562d6df3b856145e570377e43b3080d478b8b155a16a"
# my_path = '/Users/sfisher/test2.json'
my_path = '/Users/sfisher/Downloads/zTestJunk/frictionless/tested/50000 Sales Records.csv'

detector = Detector(field_missing_values="na,n/a,.,none,NA,N/A,N.A.,n.a.,-,empty,blank".split(","))
try:
  report = validate(my_path, "resource", detector=detector) # , {profile: "tabular-data-resource", format: "json" }
  # report = validate_resource(my_path, detector=detector)
except Exception as exception:
  print(exception)

pprint(report)

# Now try accessing the Dryad API from Python
r = requests.post("https://dryad-stg.cdlib.org/oauth/token", json={
  'grant_type': 'client_credentials',
  'client_id': CLIENT_ID,
  'client_secret': CLIENT_SECRET
  })

if r.status_code > 399:
  print('Could not log in to Dryad API')
  sys.exit()

access_token = r.json()['access_token']
print(f'Access token={access_token}')
headers = {'Authorization': f'Bearer {access_token}'}

r = requests.post('https://dryad-stg.cdlib.org/api/v2/test', headers=headers)

if r.status_code > 399:
  print('Could not execute query against API with token')
  sys.exit()

pprint(r.json())

print('done')
