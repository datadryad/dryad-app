# This is a basic script that will take all the xls and xlsx files in the current directory and split out the
# worksheets into CSV files and save them in the current directory with a name like
# "<basename>_<sanitized-worksheet-name>.csv"

# It catches problems with files that cannot be parsed (a bunch of csvs were saved as xls files in our legacy data).

# A lot more will have to happen to make this into a lambda, it will also need to download files, run the conversion,
# re-upload new files back to S3 and then also notify our application in some way of the new files that have been added
# to the dataset and when all the worksheets have been split out into CSVs.

# Some large or complicated files may take excessively long to convert or may not convert successfully which we should
# catch and display something to the user at some point.  Some larger test files took 4 to 8 minutes on my machine, though
# most were much smaller.

import pandas
# import pdb
import glob
import re
from pathlib import Path
import time


for name in (glob.glob('*.xls') + glob.glob('*.xlsx')):
    start_time = time.time()
    print(f'\nStarted processing {name} at {time.ctime()}')
    try:
        data_frames = pandas.read_excel(name, sheet_name=None)
    except ValueError as inst:
        print(f'    File {name} could not be parsed as an Excel file.  Is the format correct?')
        continue

    for x in data_frames.keys():
        safe_fn_tab = re.sub(r'[^-a-zA-Z0-9_.()]+', '_', x)
        new_fn = f'{Path(name).stem}_{safe_fn_tab}.csv'
        data_frames[x].to_csv(new_fn, index=None, header=True)
        print(f'    Created new csv file {new_fn}')

    end_time = time.time()
    print(f'Completed processing {name} in {end_time-start_time} seconds')


print('bye')