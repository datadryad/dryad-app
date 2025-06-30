/**
 * @jest-environment jsdom
 */

/* some resources for testing, need to have a better understanding of how testing works like a training course
https://medium.com/@kylefox/how-to-setup-javascript-testing-in-rails-5-1-with-webpacker-and-jest-ef7130a4c08e
https://jestjs.io/docs/configuration
https://jest-bot.github.io/jest/docs/configuration.html
https://reactjs.org/docs/testing-recipes.html
https://reactjs.org/docs/test-utils.html
https://www.freecodecamp.org/news/testing-react-hooks/
https://www.valentinog.com/blog/testing-react/
https://reactjs.org/docs/test-renderer.html

const uploadFiles = require('UploadFiles.js');

to run try 'yarn jest'
if you need to see console.log output, do 'yarn jest --verbose false'
 */

import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import errorFiles from './errorFiles.json';
import UploadFiles from '../../../../../app/javascript/react/components/UploadFiles';

jest.mock('axios');
jest.mock('aws-sdk');
jest.mock('evaporate', () => ({
  create: jest.fn(() => Promise.resolve({
    add: jest.fn((addConfig) => {
      addConfig.complete();
      return Promise.resolve(jest.fn());
    }),
  })),
}));
jest.mock('../../../../../app/javascript/react/components/UploadFiles/pollingDelay', () => ({
  pollingDelay: 100,
}));

const setLoaded = (obj) => {
  const loaded = JSON.parse(JSON.stringify(obj));
  loaded.uploaded = true;
  loaded.type = 'StashEngine::DataFile';
  loaded.frictionless_report = {
    report: '{}',
    status: 'noissues',
  };
  return loaded;
};

describe('UploadFiles', () => {
  let info; let files; let datafile; let setfile; let loaded;
  const setResource = () => {};
  const form = {
    data: `<label for="searchselect-license__input">Software license</label>
    <input type="hidden" name="license[value]" id="searchselect-license__value" value=""/>
    <input type="text" id="searchselect-license__input"/>`,
  };
  const software_data = {
    data: {
      name: 'MIT License',
      identifier: 'MIT',
      details_url: 'https://spdx.org/licenses/MIT.json',
    },
  };
  beforeEach(() => {
    HTMLDialogElement.prototype.show = jest.fn(function mock() { this.open = true; });
    HTMLDialogElement.prototype.showModal = jest.fn(function mock() { this.open = true; });
    HTMLDialogElement.prototype.close = jest.fn(function mock() { this.open = false; });
    document.body.innerHTML = '<div id="aria-info" class="screen-reader-only" aria-live="polite" aria-atomic="true"></div>';

    const resourceId = faker.datatype.number(9999);

    files = [
      new File(['data1'], 'data.csv', {type: 'text/csv'}),
      new File(['data2'], 'set.csv', {type: 'text/csv'}),
    ];
    Object.defineProperty(files[0], 'size', {value: 180000});

    datafile = {
      id: faker.datatype.number(999),
      download_filename: 'data.csv',
      upload_file_name: '383cd2f9-49a7-4d3e-a8cb-2393fda58ba2.csv',
      upload_content_type: 'text/csv',
      upload_file_size: 180000,
      resource_id: resourceId,
      file_state: 'created',
      original_filename: 'data.csv',
      compressed_try: 0,
      type: 'StashEngine::DataFile',
    };
    setfile = {
      id: datafile.id + 1,
      download_filename: 'set.csv',
      upload_file_name: 'dbf18952-6007-4668-9497-b098c4659780.csv',
      upload_content_type: 'text/csv',
      upload_file_size: 130000,
      resource_id: resourceId,
      file_state: 'created',
      original_filename: 'set.csv',
      compressed_try: 0,
      type: 'StashEngine::DataFile',
    };
    loaded = setLoaded(datafile);

    info = {
      current: true,
      setResource,
      resource: {
        id: resourceId,
        identifier: {},
        generic_files: [],
      },
      config_s3: {table: {region: 'us-west-2', bucket: 'a-test-bucket', key: 'abcdefg'}},
      s3_dir_name: 'b759e787-333',
      config_maximums: {files: 3},
      config_payments: {large_file_size: 500000},
    };
  });

  it('loads and does not show the file note', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    render(<UploadFiles {...info} />);
    await waitFor(() => form);
    await waitFor(() => software_data);

    expect(screen.getByText('No files have been selected.')).toBeInTheDocument();
    expect(screen.queryByLabelText('Describe your file changes')).not.toBeInTheDocument();
  });

  it('uploads a data file and shows the size', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    render(<UploadFiles {...info} />);

    const newfile = {status: 200, data: {new_file: datafile}};
    axios.post.mockResolvedValueOnce(newfile);

    const [input] = screen.getAllByLabelText('Choose files');
    expect(input).toHaveAttribute('id', 'data');

    userEvent.upload(input, files[0]);

    expect(input.files).toHaveLength(1);
    expect(screen.getByText('data.csv')).toBeInTheDocument();
    await waitFor(() => newfile);

    await waitFor(() => {
      expect(screen.getByText('data.csv')).toBeInTheDocument();
      expect(screen.queryByText('Pending')).not.toBeInTheDocument();
      expect(screen.getAllByText('180 KB')[0]).toBeInTheDocument();
    });
  });

  it('starts and runs frictionless checks', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);

    const postA = {status: 200, data: {new_file: datafile}};
    const postB = {status: 200, data: [{file_id: datafile.id, triggered: true}]};
    const get = {status: 200, data: [loaded]};

    axios.post.mockResolvedValueOnce(postA);
    axios.post.mockResolvedValueOnce(postB);
    axios.get.mockResolvedValueOnce(get);

    info.config_maximums.frictionless = 200000;
    render(<UploadFiles {...info} />);

    const [input] = screen.getAllByLabelText('Choose files');
    userEvent.upload(input, files[0]);
    await waitFor(() => postA);
    await waitFor(() => postB);

    await waitFor(() => {
      expect(screen.getByText('Validating...')).toBeInTheDocument();
    });

    await waitFor(() => get);

    await waitFor(() => {
      expect(screen.getByText('Passed')).toBeInTheDocument();
    });
  });

  it('shows frictionless errors', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);

    info.resource.generic_files = errorFiles;
    info.config_maximums.frictionless = 200000;
    render(<UploadFiles {...info} />);

    const buttons = screen.getAllByText(/View \d*\s?alerts/);

    expect(buttons.length).toEqual(errorFiles.length);

    userEvent.click(buttons[0]);
    await waitFor(() => {
      expect(screen.getByText(`Formatting report: ${errorFiles[0].download_filename}`)).toBeVisible();
    });
  });

  it('closes the frictionless errors', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);

    info.resource.generic_files = errorFiles;
    info.config_maximums.frictionless = 200000;
    render(<UploadFiles {...info} />);

    const buttons = screen.getAllByText(/View \d*\s?alerts/);
    userEvent.click(buttons[0]);

    const head = screen.getByText(`Formatting report: ${errorFiles[0].download_filename}`);
    await waitFor(() => {
      expect(head).toBeVisible();
    });

    userEvent.click(head.nextSibling);

    await waitFor(() => {
      expect(head).not.toBeVisible();
    });
  });

  it('removes an uploaded file', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    axios.patch.mockResolvedValueOnce('OK');

    info.resource.generic_files = [loaded];
    render(<UploadFiles {...info} />);

    const button = screen.getByLabelText('Remove file');
    userEvent.click(button);

    expect(screen.queryByLabelText('Remove file')).not.toBeInTheDocument();

    await waitFor(() => 'OK');

    await waitFor(() => {
      expect(screen.getByText('No files have been selected.')).toBeInTheDocument();
    });
  });

  it('renames an uploaded file', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    datafile.download_filename = 'dataChanged.csv';
    axios.patch.mockResolvedValueOnce({data: datafile});

    info.resource.generic_files = [loaded];
    render(<UploadFiles {...info} />);

    const button = screen.getByLabelText('Rename file data.csv');
    userEvent.click(button);

    const input = screen.getByLabelText('Rename file data.csv');
    userEvent.type(input, 'Changed');
    const save = screen.getByLabelText('Save new name for data.csv');
    userEvent.click(save);

    await waitFor(() => {
      expect(screen.getByText('dataChanged.csv')).toBeInTheDocument();
    });
  });

  it('does not rename to a used filename', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    axios.patch.mockResolvedValueOnce({data: {error: 'Filename data.csv is in use'}});

    info.resource.generic_files = [loaded, setLoaded(setfile)];
    render(<UploadFiles {...info} />);

    const button = screen.getByLabelText('Rename file set.csv');
    userEvent.click(button);

    const input = screen.getByLabelText('Rename file set.csv');
    userEvent.clear(input);
    userEvent.type(input, 'data');
    const save = screen.getByLabelText('Save new name for set.csv');
    userEvent.click(save);

    await waitFor(() => {
      expect(screen.getByText('Filename data.csv is in use')).toBeInTheDocument();
    });
  });

  it('does not allow duplicate files', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    const postA = {status: 200, data: {new_file: setfile}};
    axios.post.mockResolvedValueOnce(postA);

    info.resource.generic_files = [loaded];
    render(<UploadFiles {...info} />);

    const [input] = screen.getAllByLabelText('Choose files');
    userEvent.upload(input, files);
    await waitFor(() => postA);
    expect(screen.getByText('A file of the same name is already in the table. The new file was not added.')).toBeInTheDocument();
  });

  it('allows duplicate files for zenodo', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    setfile.type = 'StashEngine::SoftwareFile';
    datafile.type = 'StashEngine::SoftwareFile';
    const postA = {status: 200, data: {new_file: setfile}};
    datafile.id += 2;
    datafile.upload_file_name = 'f36a99b7-0c5d-4aee-943a-7ed4f34a208f.csv';
    const postB = {status: 200, data: {new_file: datafile}};
    axios.post.mockResolvedValueOnce(postA);
    axios.post.mockResolvedValueOnce(postB);

    info.resource.generic_files = [loaded];
    render(<UploadFiles {...info} />);

    const button = screen.getByText('+ Add files for simultaneous publication at Zenodo');
    await waitFor(() => userEvent.click(button));
    const input = screen.getAllByLabelText('Choose files')[1];
    expect(input).toHaveAttribute('id', 'software');

    userEvent.upload(input, files);
    await waitFor(() => postA);
    await waitFor(() => postB);
    expect(screen.getAllByText('data.csv').length).toEqual(3);
    expect(screen.queryByText('A file of the same name is already in the table. The new file was not added.')).not.toBeInTheDocument();
  });

  it('does not allow more than the max allowed files', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    info.config_maximums.files = 1;
    info.resource.generic_files = [loaded];
    render(<UploadFiles {...info} />);

    const [data] = screen.getAllByLabelText('Choose files');
    await waitFor(() => userEvent.upload(data, [files[1]]));
    expect(screen.getByText('You may not upload more than 1 individual files of this type.')).toBeInTheDocument();
  });

  it('does not show the file note when files are not edited', () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);

    info.previous = {generic_files: [loaded]};
    loaded.file_state = 'copied';
    info.resource.generic_files = [loaded];
    render(<UploadFiles {...info} />);

    expect(screen.queryByLabelText('Describe your file changes')).not.toBeInTheDocument();
  });

  it('shows and changes the file note when files are edited', async () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);

    const note = faker.lorem.sentence();
    const data = {
      id: faker.datatype.number(),
      note: '',
    };
    axios.get.mockResolvedValueOnce({data});
    axios.post.mockResolvedValueOnce({note});

    info.resource.generic_files = [loaded];
    info.previous = {generic_files: []};
    render(<UploadFiles {...info} />);

    const notebox = screen.getByLabelText('Describe your file changes');

    userEvent.type(notebox, note);
    userEvent.tab();

    await waitFor(() => note);
  });

  it('loads and opens the URL dialog', () => {
    axios.get.mockResolvedValueOnce(form);
    axios.post.mockResolvedValueOnce(software_data);
    render(<UploadFiles {...info} />);

    const [button] = screen.getAllByText('Enter URLs');

    expect(button).toHaveAttribute('id', 'data_manifest');
    userEvent.click(button);
    expect(screen.getByText('Place each URL on a new line.')).toBeVisible();
  });

  it('enters URLs and uploads', async () => {
    axios.get.mockResolvedValueOnce(form);
    const file_url = `${faker.internet.url()}/data.csv`;
    datafile.url = file_url;
    datafile.status_code = 200;
    datafile.type = 'StashEngine::DataFile';
    const data = {
      status: 200,
      data: {
        valid_urls: [datafile],
        invalid_urls: [],
      },
    };
    axios.post.mockResolvedValueOnce(data);
    axios.post.mockResolvedValueOnce(software_data);

    render(<UploadFiles {...info} />);
    const [button] = screen.getAllByText('Enter URLs');
    userEvent.click(button);

    const input = screen.getByRole('textbox');
    const validate = screen.getByText('Validate files');

    userEvent.type(input, file_url);
    userEvent.click(validate);

    await waitFor(() => data);

    expect(screen.getByText('data.csv')).toBeInTheDocument();
    expect(screen.getAllByText('180 KB')[0]).toBeInTheDocument();
  });

  it('enters URLs and shows failures', async () => {
    axios.get.mockResolvedValueOnce(form);
    const filenames = ['badUrl.csv', 'unAuth.csv', 'notFound.csv', 'unavail.csv', 'please.csv', 'accept.csv', 'timeout.csv', 'dupe.csv'];
    const codes = [400, 401, 403, 410, 411, 414, 408, 409];
    const urls = filenames.map((name) => faker.internet.url() + name);
    datafile.type = 'StashEngine::DataFile';
    const badfiles = filenames.map((name, i) => {
      const file = JSON.parse(JSON.stringify(datafile));
      file.id += i;
      file.download_filename = name;
      file.original_filename = name;
      file.url = urls[i];
      file.status_code = codes[i];
      file.timed_out = name.startsWith('timeout');
      return file;
    });
    const data = {
      status: 200,
      data: {
        valid_urls: [],
        invalid_urls: badfiles,
      },
    };
    axios.post.mockResolvedValueOnce(data);
    axios.post.mockResolvedValueOnce(software_data);

    render(<UploadFiles {...info} />);
    const [button] = screen.getAllByText('Enter URLs');
    userEvent.click(button);

    const input = screen.getByRole('textbox');
    const validate = screen.getByText('Validate files');

    userEvent.type(input, urls.join('\n'));
    userEvent.click(validate);

    await waitFor(() => data);

    expect(screen.getByText('The URL was not entered correctly. Be sure to use http:// or https:// to start all URLS')).toBeInTheDocument();
    expect(screen.getByText('The URL was not authorized for download.')).toBeInTheDocument();
    expect(screen.getByText('The URL was not found.')).toBeInTheDocument();
    expect(screen.getByText('The requested URL is no longer available.')).toBeInTheDocument();
    expect(screen.getByText('URL cannot be downloaded, please link directly to data file')).toBeInTheDocument();
    expect(screen.getByText(`The server will not accept the request, because the URL ${urls[5]} is too long.`)).toBeInTheDocument();
    expect(screen.getByText('The server timed out waiting for the request to complete.')).toBeInTheDocument();
    expect(screen.getByText("You've already added this URL in this version.")).toBeInTheDocument();
  });
});
