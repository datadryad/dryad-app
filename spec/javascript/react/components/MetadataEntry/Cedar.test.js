import React from 'react';
import {render, screen} from '@testing-library/react';
import {faker} from '@faker-js/faker';
import Cedar from '../../../../../app/javascript/react/components/MetadataEntry/Cedar';

jest.mock('axios');

describe('Cedar', () => {
  let resource; let appConfig; let
    templateName;

  beforeEach(() => {
    resource = {
      id: faker.datatype.number(),
      title: faker.lorem.sentence(),
      cedar_json: null,
    };
    templateName = faker.lorem.words(3);
    appConfig = {
      table: {
        editor_url: '/bogus-url/cedar-embeddable-editor-2.6.18.js',
        templates: [[1, 'Nothing', 'Empty template'], [2, 'Faked', templateName]],
      },
    };
  });

  it('does not render when there is no config', () => {
    appConfig = null;
    render(<Cedar resource={resource} appConfig={appConfig} />);
    expect(screen.queryByText('Choose a metadata form')).not.toBeInTheDocument();
  });

  it('renders a select box', () => {
    render(<Cedar resource={resource} appConfig={appConfig} />);
    expect(screen.queryByText('Choose a metadata form')).toBeInTheDocument();

    const options = screen.getAllByRole('option');
    expect(options.length).toBe(3);
    const optionNames = options.map((o) => o.label);
    expect(optionNames).toEqual(['- Select one -', 'Empty template', templateName]);
  });

  it('renders an indicator that metadata is present', () => {
    resource = {
      id: faker.datatype.number(),
      title: faker.lorem.sentence(),
      cedar_json: `{ "template": {"id":"1","title":"${templateName}"}, "metadata": 2, "updated": 3 }`,
    };
    render(<Cedar resource={resource} appConfig={appConfig} />);

    screen.debug();
    expect(screen.queryByText(templateName)).toBeInTheDocument();
    expect(screen.queryByText('Edit form')).toBeInTheDocument();
    expect(screen.queryByText('Delete form')).toBeInTheDocument();
  });
});
