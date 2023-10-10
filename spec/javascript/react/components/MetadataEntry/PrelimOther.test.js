import React from 'react';
import {render, screen} from '@testing-library/react';
import PrelimOther from '../../../../../app/javascript/react/components/MetadataEntry/PrelimOther';

// this doesn't do much but display a section

describe('PrelimOther', () => {
  it('renders the information for Preliminaries: Other', () => {
    /* mocks for use/set state, these don't really do the functionality, but just give dummy objects */

    render(<PrelimOther />);

    const para = screen.getByText('you will have the opportunity to relate', {exact: false});
    expect(para).toBeInTheDocument();
  });
});
