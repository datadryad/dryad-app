/**
 * @jest-environment jsdom
 */

import React from 'react';
import {
  render, screen, waitFor, within,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import fs from 'fs';
import path from 'path';
import ReadMeWizard from '../../../../../app/javascript/react/components/ReadMeWizard';

jest.mock('axios');

describe('ReadMeWizard', () => {
  let info; let response;
  const setResource = () => {};
  const file = fs.readFileSync(path.join(__dirname, '../../../../fixtures/README.md'), 'utf8');
  beforeEach(() => {
    info = {
      resource: {
        title: 'Test Dataset Title',
        descriptions: [{id: faker.datatype.number(), description_type: 'technicalinfo', description: null}],
        identifier: {identifier: '10.5555/12345678'},
      },
      setResource,
      current: true,
    };
    response = {status: 200, data: {readme_file: null, file_list: [{name: 'image_file.jpg'}]}};
  });

  it('loads editing container', async () => {
    axios.get.mockResolvedValueOnce(response);
    render(<ReadMeWizard {...info} />);
    await waitFor(() => {
      expect(screen.getByText('Build a README')).toBeInTheDocument();
    });
  });

  it('loads dataset title, DOI, and files to editor', async () => {
    axios.get.mockResolvedValueOnce(response);
    axios.patch.mockResolvedValueOnce({status: 200, data: {}});
    axios.patch.mockResolvedValueOnce({status: 200, data: {}});
    axios.patch.mockResolvedValueOnce({status: 200, data: {}});
    render(<ReadMeWizard {...info} />);
    await waitFor(() => {
      expect(screen.getByText('Build a README')).toBeInTheDocument();
    });
    userEvent.click(screen.getByText('Build a README'));
    userEvent.type(screen.getAllByLabelText('Data description')[0], 'test');
    userEvent.tab();
    userEvent.click(screen.getAllByText('Next')[0]);
    await waitFor(() => {
      expect(screen.getAllByText('Files and variables')[1]).toBeInTheDocument();
    });
    const fileEditor = screen.getAllByLabelText('Files and variables')[2];
    await waitFor(() => {
      expect(within(fileEditor).getByText('File: image_file.jpg')).toBeInTheDocument();
    });
    userEvent.click(screen.getAllByText('Next')[0]);
    userEvent.click(screen.getAllByText('Next')[0]);
    userEvent.click(screen.getByText('Complete & generate README'));
    await waitFor(() => {
      expect(screen.getByText('Description of the data and file structure')).toBeInTheDocument();
    });
    const editor = screen.getAllByLabelText('Create README for dataset')[0];
    expect(within(editor).getAllByText('Test Dataset Title').length).toEqual(1);
    expect(within(editor).getAllByText('10.5555/12345678').length).toEqual(1);
  });

  it('loads an existing description', async () => {
    axios.get.mockResolvedValueOnce(response);
    info.resource.descriptions[0].description = '# Title of Dataset';
    render(<ReadMeWizard {...info} />);
    await waitFor(() => {
      expect(screen.getAllByText('Title of Dataset').length).toEqual(1);
    });
  });

  it('replaces content with uploaded file', async () => {
    axios.get.mockResolvedValueOnce(response);
    axios.patch.mockResolvedValueOnce({status: 200, data: {}});
    info.resource.descriptions[0].description = '# Old Title of Dataset';
    render(<ReadMeWizard {...info} />);

    const upload = new File([file], 'new_readme.md', {type: 'text/markdown'});
    await waitFor(() => {
      const input = screen.getByLabelText('Import README');
      userEvent.upload(input, upload);
      expect(input.files).toHaveLength(1);
    });

    await waitFor(() => {
      expect(screen.getAllByText('This is a test dataset title').length).toEqual(1);
    });
  });
});
