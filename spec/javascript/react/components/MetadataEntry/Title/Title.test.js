/**
 * @jest-environment jsdom
 */

import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import axios from 'axios';
import Title from '../../../../../../app/javascript/react/components/MetadataEntry/Title/Title';

jest.mock('axios');

describe('Title', () => {
  let resource; let setResource;

  beforeEach(() => {
    resource = {
      id: 27, title: 'My test of rendering title', token: '12xu', resource_type: {resource_type: 'dataset'},
    };
    setResource = () => {};
  });

  it('renders a basic title', () => {
    render(<Title resource={resource} setResource={setResource} />);

    const input = screen.getByLabelText('Submission title', {exact: false});
    expect(input).toHaveValue(resource.title);
  });

  it('calls axios to update from server on change', async () => {
    const newTitle = 'My test of updating title';

    const promise = Promise.resolve({
      status: 200,
      data: {id: 27, title: newTitle},
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<Title resource={resource} setResource={setResource} />);

    const title = screen.getByLabelText('Submission title', {exact: false});
    expect(title).toHaveValue(resource.title);

    userEvent.clear(screen.getByLabelText('Submission title'));
    userEvent.type(screen.getByLabelText('Submission title'), newTitle);

    await waitFor(() => expect(screen.getByLabelText('Submission title')).toHaveValue(newTitle));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});
