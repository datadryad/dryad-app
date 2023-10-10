/**
 * @jest-environment jsdom
 */

import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import axios from 'axios';
import Title from '../../../../../app/javascript/react/components/MetadataEntry/Title';

jest.mock('axios');

describe('Title', () => {
  let resource; let path; let
    type;

  beforeEach(() => {
    // setup a DOM element as a render target
    resource = {id: 27, title: 'My test of rendering title', token: '12xu'};
    path = '/stash_datacite/titles/update';
    type = 'Dataset';
  });

  it('renders a basic title', () => {
    render(<Title resource={resource} path={path} type={type} />);

    const input = screen.getByLabelText('Dataset title', {exact: false});
    expect(input).toHaveValue(resource.title);
  });

  it('calls axios to update from server on change', async () => {
    const newTitle = 'My test of updating title';

    const promise = Promise.resolve({
      status: 200,
      data: {id: 27, title: newTitle},
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<Title
      resource={resource}
      path={path}
      type={type}
    />);

    const title = screen.getByLabelText('Dataset title', {exact: false});
    expect(title).toHaveValue(resource.title);

    userEvent.clear(screen.getByLabelText('Dataset title'));
    userEvent.type(screen.getByLabelText('Dataset title'), newTitle);

    await waitFor(() => expect(screen.getByLabelText('Dataset title')).toHaveValue(newTitle));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});
