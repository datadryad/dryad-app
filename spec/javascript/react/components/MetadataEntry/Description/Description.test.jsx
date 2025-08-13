import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import Description from '../../../../../../app/javascript/react/components/MetadataEntry/Description/Description';

jest.mock('axios');

describe('Description', () => {
  const setResource = () => {};
  let dcsDescription; let mceLabel;
  beforeEach(() => {
    dcsDescription = {
      id: faker.datatype.number(),
      resource_id: faker.datatype.number(),
      description_type: 'abstract',
      description: null,
    }
    mceLabel = {
      label: 'Abstract',
      required: true,
      describe: <><i aria-hidden="true" />An introductory description of your dataset</>,
    }
  });

  it('renders the description editor', async () => {
    render(<Description {...{mceLabel, dcsDescription, setResource}} />);
    await waitFor(() => {
      expect(screen.getByText('Markdown')).toBeInTheDocument();      
    });
    expect(screen.getByText('Rich text')).toBeInTheDocument();
    expect(screen.getByText('Abstract')).toBeInTheDocument();
    expect(screen.getByText('An introductory description of your dataset')).toBeInTheDocument();    
  });

  it('renders an html description', async () => {
    dcsDescription.description = '<h2>This is an HTML header</h2><p>This is an HTML paragraph</p>'
    render(<Description {...{mceLabel, dcsDescription, setResource}} />);
    await waitFor(() => {
      expect(screen.getByText('Markdown')).toBeInTheDocument();      
    });
    expect(screen.getByText('This is an HTML header')).toBeInTheDocument();
    expect(screen.getByText('This is an HTML paragraph')).toBeInTheDocument();
  });

});
