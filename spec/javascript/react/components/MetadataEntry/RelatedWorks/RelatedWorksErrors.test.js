import React from 'react';
import {render} from '@testing-library/react';
import RelatedWorksErrors from '../../../../../../app/javascript/react/components/MetadataEntry/RelatedWorks/RelatedWorksErrors';

global.URL.canParse = () => true;

describe('RelatedWorksErrors', () => {
  it('renders without error info', () => {
    const {container} = render(<RelatedWorksErrors
      relatedIdentifier={{related_identifier: 'http://test.com/1234', verified: true}}
    />);

    expect(container.getElementsByClassName('warn').length).toBe(0);
  });

  it('renders with error info', () => {
    const {container} = render(<RelatedWorksErrors
      relatedIdentifier={{related_identifier: 'http://test.com/1234', verified: false}}
    />);

    expect(container.getElementsByClassName('warn').length).toBe(1);
  });
});
