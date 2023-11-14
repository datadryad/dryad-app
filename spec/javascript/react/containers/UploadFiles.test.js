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
import UploadFiles from '../../../../app/javascript/react/containers/UploadFiles';

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
jest.mock('../../../../app/javascript/react/containers/maximums', () => ({
  maxFiles: 3,
  pollingDelay: 100,
}));

describe('UploadFiles', () => {
  let info; let files; let datafile; let loaded;

  beforeEach(() => {
    HTMLDialogElement.prototype.show = jest.fn(function mock() { this.open = true; });
    HTMLDialogElement.prototype.showModal = jest.fn(function mock() { this.open = true; });
    HTMLDialogElement.prototype.close = jest.fn(function mock() { this.open = false; });
    document.body.innerHTML = '<div id="aria-info" class="screen-reader-only" aria-live="polite" aria-atomic="true"></div>';

    const resourceId = faker.datatype.number(9999);

    info = {
      resource_id: resourceId,
      readme_size: 480,
      file_uploads: [],
      app_config_s3: {table: {region: 'us-west-2', bucket: 'a-test-bucket', key: 'abcdefg'}},
      s3_dir_name: 'b759e787-333',
      frictionless: {},
      previous_version: false,
      file_note: null,
    };

    files = [
      new File(['data1'], 'data.csv', {type: 'text/csv'}),
      new File(['data2'], 'set.csv', {type: 'text/csv'}),
    ];
    Object.defineProperty(files[0], 'size', {value: 180000});

    datafile = {
      id: faker.datatype.number(999),
      upload_file_name: 'data.csv',
      upload_content_type: 'text/csv',
      upload_file_size: 180000,
      resource_id: info.resource_id,
      file_state: 'created',
      original_filename: 'data.csv',
      compressed_try: 0,
    };
    loaded = JSON.parse(JSON.stringify(datafile));
    loaded.type = 'StashEngine::DataFile';
    loaded.frictionless_report = {
      report: '{}',
      status: 'noissues',
    };
  });

  it('loads and does not show the file note', () => {
    render(<UploadFiles {...info} />);
    expect(screen.getByText('No files have been selected.')).toBeInTheDocument();
    expect(screen.queryByLabelText('Please describe your file changes')).not.toBeInTheDocument();
  });

  it('loads pending data files', () => {
    render(<UploadFiles {...info} />);

    const [input] = screen.getAllByLabelText('Choose files');
    expect(input).toHaveAttribute('id', 'data');

    userEvent.upload(input, files);

    expect(input.files).toHaveLength(2);
    expect(input.files[0]).toStrictEqual(files[0]);
    expect(input.files[1]).toStrictEqual(files[1]);
    expect(screen.getByText('data.csv')).toBeInTheDocument();
  });

  it('loads pending software files', () => {
    render(<UploadFiles {...info} />);

    const input = screen.getAllByLabelText('Choose files')[1];
    expect(input).toHaveAttribute('id', 'software');

    userEvent.upload(input, files);

    expect(input.files).toHaveLength(2);
    expect(input.files[0]).toStrictEqual(files[0]);
    expect(input.files[1]).toStrictEqual(files[1]);
    expect(screen.getByText('data.csv')).toBeInTheDocument();
  });

  it('loads pending supp files', () => {
    render(<UploadFiles {...info} />);

    const input = screen.getAllByLabelText('Choose files')[2];
    expect(input).toHaveAttribute('id', 'supp');

    userEvent.upload(input, files);

    expect(input.files).toHaveLength(2);
    expect(input.files[0]).toStrictEqual(files[0]);
    expect(input.files[1]).toStrictEqual(files[1]);
    expect(screen.getByText('data.csv')).toBeInTheDocument();
  });

  it('removes a pending file', () => {
    render(<UploadFiles {...info} />);

    const [input] = screen.getAllByLabelText('Choose files');
    userEvent.upload(input, [files[1]]);

    const button = screen.getByText('Remove');
    userEvent.click(button);

    expect(screen.queryByText('Remove')).not.toBeInTheDocument();
    expect(screen.getByText('No files have been selected.')).toBeInTheDocument();
  });

  it('uploads a data file and shows the size', async () => {
    const promise = Promise.resolve({status: 200, data: {new_file: datafile}});
    axios.post.mockImplementationOnce(() => promise);

    render(<UploadFiles {...info} />);

    const [input] = screen.getAllByLabelText('Choose files');
    expect(input).toHaveAttribute('id', 'data');

    userEvent.upload(input, files[0]);

    expect(input.files).toHaveLength(1);
    expect(screen.getByText('data.csv')).toBeInTheDocument();
    expect(screen.getByText('Pending')).toBeInTheDocument();

    const checkbox = screen.getByRole('checkbox');
    expect(checkbox).toHaveAttribute('id', 'confirm_to_validate_files');

    userEvent.click(checkbox);
    await waitFor(() => {
      expect(checkbox.checked).toEqual(true);
    });

    userEvent.click(screen.getByText('Upload pending files'));

    await waitFor(() => promise);

    await waitFor(() => {
      expect(screen.getByText('data.csv')).toBeInTheDocument();
      expect(screen.queryByText('Pending')).not.toBeInTheDocument();
      expect(screen.getByText('Uploaded')).toBeInTheDocument();
      expect(screen.getByText('180.00 KB')).toBeInTheDocument();
    });
  });

  it('starts and runs frictionless checks', async () => {
    const promiseA = Promise.resolve({status: 200, data: {new_file: datafile}});
    const promiseB = Promise.resolve({status: 200, data: [{file_id: datafile.id, triggered: true}]});
    const promiseC = Promise.resolve({status: 200, data: [loaded]});

    axios.post.mockImplementationOnce(() => promiseA);
    axios.post.mockImplementationOnce(() => promiseB);
    axios.get.mockImplementationOnce(() => promiseC);

    info.frictionless = {size_limit: 200000};
    render(<UploadFiles {...info} />);

    const [input] = screen.getAllByLabelText('Choose files');
    userEvent.upload(input, files[0]);
    const checkbox = screen.getByRole('checkbox');
    userEvent.click(checkbox);
    userEvent.click(screen.getByText('Upload pending files'));

    await waitFor(() => promiseA);
    await waitFor(() => promiseB);

    await waitFor(() => {
      expect(screen.getByText('Uploaded')).toBeInTheDocument();
    });
    expect(screen.getByText('Validating...')).toBeInTheDocument();

    await waitFor(() => promiseC);

    await waitFor(() => {
      expect(screen.getByText('Passed')).toBeInTheDocument();
    });
  });

  it('shows frictionless errors', async () => {
    info.file_uploads = errorFiles;
    info.frictionless = {size_limit: 200000};
    render(<UploadFiles {...info} />);

    const buttons = screen.getAllByText(/View \d*\s?alerts/);

    expect(buttons.length).toEqual(errorFiles.length);

    userEvent.click(buttons[0]);
    await waitFor(() => {
      expect(screen.getByText(`Formatting report: ${errorFiles[0].upload_file_name}`)).toBeVisible();
    });
  });

  it('closes the frictionless errors', async () => {
    info.file_uploads = errorFiles;
    info.frictionless = {size_limit: 200000};
    render(<UploadFiles {...info} />);

    const buttons = screen.getAllByText(/View \d*\s?alerts/);
    userEvent.click(buttons[0]);

    const head = screen.getByText(`Formatting report: ${errorFiles[0].upload_file_name}`);
    await waitFor(() => {
      expect(head).toBeVisible();
    });

    userEvent.click(head.nextSibling);

    await waitFor(() => {
      expect(head).not.toBeVisible();
    });
  });

  it('removes an uploaded file', async () => {
    const promise = Promise.resolve('OK');
    axios.patch.mockImplementationOnce(() => promise);

    info.file_uploads = [loaded];
    render(<UploadFiles {...info} />);

    const button = screen.getByText('Remove');
    userEvent.click(button);

    expect(screen.queryByText('Remove')).not.toBeInTheDocument();
    expect(screen.getByText('Removing...')).toBeInTheDocument();

    await waitFor(() => promise);

    await waitFor(() => {
      expect(screen.getByText('No files have been selected.')).toBeInTheDocument();
    });
  });

  it('does not allow duplicate files', () => {
    info.file_uploads = [loaded];
    render(<UploadFiles {...info} />);

    const [input] = screen.getAllByLabelText('Choose files');
    userEvent.upload(input, files);

    expect(screen.getByText('A file of the same name is already in the table, and was not added.')).toBeInTheDocument();
  });

  it('allows duplicate files for zenodo', () => {
    info.file_uploads = [loaded];
    render(<UploadFiles {...info} />);

    const input = screen.getAllByLabelText('Choose files')[1];
    expect(input).toHaveAttribute('id', 'software');

    userEvent.upload(input, files);
    expect(screen.getAllByText('data.csv').length).toEqual(2);
    expect(screen.queryByText('A file of the same name is already in the table, and was not added.')).not.toBeInTheDocument();
  });

  it('does not allow more than the max allowed files', () => {
    info.file_uploads = [loaded];
    render(<UploadFiles {...info} />);

    const [data, soft] = screen.getAllByLabelText('Choose files');
    userEvent.upload(data, [files[1]]);
    userEvent.upload(soft, files);
    expect(screen.getByText('You may not upload more than 3 individual files.')).toBeInTheDocument();
  });

  it('does not show the file note when files are not edited', () => {
    loaded.file_state = 'copied';
    info.file_uploads = [loaded];
    info.previous_version = true;
    render(<UploadFiles {...info} />);
    expect(screen.queryByLabelText('Please describe your file changes')).not.toBeInTheDocument();
  });

  it('shows and changes the file note when files are edited', async () => {
    const note = faker.lorem.sentence();

    const file_note = {
      note: {
        id: faker.datatype.number(),
        note: `User described file changes: ${note}`,
      },
    };
    const promise = Promise.resolve({status: 200, data: file_note});

    axios.post.mockImplementationOnce(() => promise);

    info.file_uploads = [loaded];
    info.previous_version = true;
    render(<UploadFiles {...info} />);

    const notebox = screen.getByLabelText('Please describe your file changes');

    userEvent.type(notebox, note);
    userEvent.tab();

    await waitFor(() => promise);

    expect(notebox).toHaveValue(note);
  });

  it('loads and opens the URL dialog', () => {
    render(<UploadFiles {...info} />);
    const [button] = screen.getAllByText('Enter URLs');

    expect(button).toHaveAttribute('id', 'data_manifest');
    userEvent.click(button);
    expect(screen.getByText('Place each URL on a new line.')).toBeVisible();
  });

  it('enters URLs and uploads', async () => {
    const file_url = `${faker.internet.url()}/data.csv`;
    datafile.url = file_url;
    datafile.status_code = 200;
    datafile.type = 'StashEngine::DataFile';
    const data = {
      valid_urls: [datafile],
      invalid_urls: [],
    };
    const promise = Promise.resolve({status: 200, data});
    axios.post.mockImplementationOnce(() => promise);
    axios.post.mockImplementationOnce(() => Promise.resolve({status: 200}));

    render(<UploadFiles {...info} />);
    const [button] = screen.getAllByText('Enter URLs');
    userEvent.click(button);

    const input = screen.getByRole('textbox');
    const validate = screen.getByText('Validate files');

    userEvent.type(input, file_url);
    userEvent.click(validate);

    await waitFor(() => promise);

    expect(screen.getByText('data.csv')).toBeInTheDocument();
    expect(screen.getByText('Uploaded')).toBeInTheDocument();
  });

  it('enters URLs and shows failures', async () => {
    const filenames = ['badUrl.csv', 'unAuth.csv', 'notFound.csv', 'unavail.csv', 'please.csv', 'accept.csv', 'timeout.csv', 'dupe.csv'];
    const codes = [400, 401, 403, 410, 411, 414, 408, 409];
    const urls = filenames.map((name) => faker.internet.url() + name);
    datafile.type = 'StashEngine::DataFile';
    const badfiles = filenames.map((name, i) => {
      const file = JSON.parse(JSON.stringify(datafile));
      file.id += i;
      file.upload_file_name = name;
      file.original_filename = name;
      file.url = urls[i];
      file.status_code = codes[i];
      file.timed_out = name.startsWith('timeout');
      return file;
    });
    const data = {
      valid_urls: [],
      invalid_urls: badfiles,
    };
    const promise = Promise.resolve({status: 200, data});
    axios.post.mockImplementationOnce(() => promise);

    render(<UploadFiles {...info} />);
    const [button] = screen.getAllByText('Enter URLs');
    userEvent.click(button);

    const input = screen.getByRole('textbox');
    const validate = screen.getByText('Validate files');

    userEvent.type(input, urls.join('\n'));
    userEvent.click(validate);

    await waitFor(() => promise);

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
