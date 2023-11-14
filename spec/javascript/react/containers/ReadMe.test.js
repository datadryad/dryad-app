/**
 * @jest-environment jsdom
 */

import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import fs from 'fs';
import path from 'path';
import ReadMe from '../../../../app/javascript/react/containers/ReadMe';

jest.mock('axios');

describe('ReadMe', () => {
  let info;
  const template = fs.readFileSync(path.join(__dirname, '../../../../public/docs/README.md'), 'utf8');

  global.fetch = jest.fn(() => Promise.resolve({
    text: () => Promise.resolve(template),
  }));

  window.scrollBy = jest.fn();

  document.elementFromPoint = jest.fn();

  document.createRange = () => {
    const range = new Range();

    range.getBoundingClientRect = jest.fn();

    range.getClientRects = jest.fn(() => ([{
      length: 100,
      width: 100,
      top: 1,
      bottom: 100,
      left: 1,
      right: 100,
    }]));

    return range;
  };

  beforeEach(() => {
    info = {
      dcsDescription: {id: faker.datatype.number(), description: null},
      updatePath: faker.system.directoryPath(),
      fileContent: null,
      title: 'Test Dataset Title',
      doi: 'http://doi.org/10.5555/12345678',
    };
  });

  it('loads editing container', async () => {
    render(<ReadMe {...info} />);
    await waitFor(() => {
      expect(screen.getByText('Prepare README file')).toBeInTheDocument();
    });
  });

  it('loads dataset title and DOI to editor', async () => {
    render(<ReadMe {...info} />);
    await waitFor(() => {
      expect(screen.getAllByText(info.title).length).toEqual(3);
      expect(screen.getAllByText(info.doi).length).toEqual(4);
    });
  });

  it('loads an existing description', async () => {
    info.dcsDescription.description = template;
    render(<ReadMe {...info} />);
    await waitFor(() => {
      expect(screen.getAllByText('Title of Dataset').length).toEqual(3);
    });
  });

  it('replaces content with uploaded file', async () => {
    const promise = Promise.resolve({status: 200});
    axios.patch.mockImplementationOnce(() => promise);

    render(<ReadMe {...info} />);

    const upload = new File([template], 'new_readme.md', {type: 'text/markdown'});
    const input = screen.getByLabelText('Import README');

    userEvent.upload(input, upload);

    expect(input.files).toHaveLength(1);

    await waitFor(() => {
      expect(screen.getAllByText('Title of Dataset').length).toEqual(3);
    });
    await waitFor(() => promise);
  });
});
