import React from 'react';
import {render, screen} from '@testing-library/react';
import {faker} from '@faker-js/faker';
import OrcidInfo from '../../../../../../app/javascript/react/components/MetadataEntry/Authors/OrcidInfo';

describe('OrcidInfo', () => {
  const makeAuthor = (resource_id = null, author_order = null) => {
    const sect = () => faker.datatype.number({min: 1000, max: 9999});
    return {
      id: faker.datatype.number({min: 1, max: 32767}),
      author_first_name: faker.name.firstName(),
      author_last_name: faker.name.lastName(),
      author_email: faker.internet.email(),
      author_orcid: `${sect()}-${sect()}-${sect()}-${sect()}`,
      resource_id: resource_id || faker.datatype.number({min: 1, max: 32767}),
      author_order: author_order || faker.datatype.number({min: 1, max: 32767}),
      orcid_invite_path: faker.internet.url(),
      affiliations: [],
    };
  };

  beforeEach(() => {

  });

  it('renders orcid info if present', () => {
    const auth = makeAuthor();
    render(<OrcidInfo author={auth} curator={false} />);
    expect(screen.getByRole('link')).toHaveTextContent(auth.author_orcid);
  });

  it('renders orcid link if curator and no orcid', () => {
    const auth = {...makeAuthor(), author_orcid: null};
    render(<OrcidInfo author={auth} curator />);
    expect(screen.getByTitle(auth.orcid_invite_path, {exact: false})).toBeInTheDocument();
  });
});
