import React from "react";
import {render} from '@testing-library/react';
import RelatedWorksErrors from "../../../../../app/javascript/react/components/MetadataEntry/RelatedWorksErrors";

describe('RelatedWorksErrors', () => {

  it("renders without error info", () => {
    const {container}  = render(<RelatedWorksErrors
        relatedIdentifier={{related_identifier: '1234', valid_url_format: true, verified: true}} />);

    expect(container.getElementsByClassName('o-metadata__autopopulate-message').length).toBe(0);
  });

  it("renders with error info", () => {
    const {container} = render(<RelatedWorksErrors
        relatedIdentifier={{related_identifier: '1234', valid_url_format: false, verified: false}} />);

    expect(container.getElementsByClassName('o-metadata__autopopulate-message').length).toBe(2);
  });
});