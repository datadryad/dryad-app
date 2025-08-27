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

  it('renders italics, superscript, and subscript', async () => {
    resource.title = 'A title that contains <em>italics</em> and <sup>superscript</sup> and <sub>subscript</sub>';
    render(<Title resource={resource} setResource={setResource} />);
    await waitFor(() => {
      expect(screen.getByText('italics')).toBeInTheDocument();
    });
    const superscript = screen.getAllByText('superscript');
    const subscript = screen.getAllByText('subscript');
    const italics = screen.getAllByText('italics');
    expect(superscript[0].tagName).toBe('SUP');
    expect(subscript[0].tagName).toBe('SUB');
    expect(italics[0].tagName).toBe('EM');
  });
});
