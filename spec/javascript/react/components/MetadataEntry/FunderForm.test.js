import React from "react";
import {render} from '@testing-library/react';
import {faker} from '@faker-js/faker';
import FunderForm from "../../../../../app/javascript/react/components/MetadataEntry/FunderForm.js";

// import axios from 'axios';

// jest.mock('axios');

describe('FunderForm', () => {

  let resourceId, info;
  beforeEach(() => {
    resourceId = faker.datatype.number();
    info = {
      resourceId: resourceId,
      origID: faker.datatype.string(10),
      contributor:
          {
            id: faker.datatype.number(),
            contributor_name: faker.company.companyName(),
            contributor_type: 'funder',
            identifier_type: null,
            name_identifier_id: null,
            resourceId: resourceId,
            award_number: faker.datatype.string(5)
          },
      createPath: faker.system.directoryPath(),
      updatePath: faker.system.directoryPath(),
      removeFunction: jest.fn()
    }
  });

  it("renders the basic funders form", () => {

    const { container } = render(<FunderForm {...info} />);

    /* const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', acText); */
  });
});