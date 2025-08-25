/**
 * @jest-environment jsdom
 */

import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import Title from '../../../../../../app/javascript/react/components/MetadataEntry/Title/Title';

describe('Title', () => {
  let resource; let setResource;

  beforeEach(() => {
    resource = {
      id: 27, title: 'My test of rendering title', token: '12xu', resource_type: {resource_type: 'dataset'},
    };
    setResource = () => {};
  });

  it('renders a basic title', async () => {
    render(<Title resource={resource} setResource={setResource} />);
    await waitFor(() => {
      expect(screen.getByText(resource.title)).toBeInTheDocument();
    });
  });
});
