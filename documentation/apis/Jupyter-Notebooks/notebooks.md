Using Jupiter Notebooks to interact with Dryad
========================

in order to demonstrate how to use Dryad API from Jupyter Notebooks, we added 2 examples:
1. Using public API endpoints - fetch data from a specific column for a file uploaded to an existing dataset. [fetch_file_data_notebook](./fetch_file_data_notebook.ipynb).
The example file contains code to:
    * Configure notebook
    * Retrieve last version of your dataset
    * Retrieve the list of files for the dataset
    * Select specified file by name
    * Parse CSV file and retrieve specified column data
    * Show colum data in Bar chart format


2. Using API credentials - create a dataset, attach a file and submit the dataset. [create_dataset_notebook](./create_dataset_notebook.ipynb)
The example file contains code to:
    * Configure notebook - Set host and API credentials
    * Authorize API connection and retrieve access token
    * Create dataset
    * Update dataset and set missing information
    * Embed/Upload a file on the dataset using file URL
    * Submit dataset

