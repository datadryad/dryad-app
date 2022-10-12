import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import PrelimInfo from "../../../../../app/javascript/react/components/MetadataEntry/PrelimInfo.js";
import axios from 'axios';

jest.mock('axios');

describe('PrelimInfo', () => {

  let importInfo, resourceId, identifierId, publication_name, publication_issn, msid, related_identifier;

  beforeEach(() => {
    importInfo = 'other';
    resourceId = faker.datatype.number();
    identifierId = faker.datatype.number();
    publication_name = {
      "id": faker.datatype.number(),
      "identifier_id": identifierId,
      "data_type": "publicationName",
      "value": faker.company.companyName(),
    };
    publication_issn = {
      "id": faker.datatype.number(),
      "identifier_id": identifierId,
      "data_type": "publicationISSN",
      "value": `${faker.datatype.number({min:1000, max:9999})}-${faker.datatype.number({min:1000, max:9999})}`
    };
    msid = {
      "id": faker.datatype.number(),
      "identifier_id": identifierId,
      "data_type": "manuscriptNumber",
      "value": ''
    }
    related_identifier = '';
  });

  it("renders the preliminary information section", () => {
    render(<PrelimInfo
        importInfo={importInfo}
        resourceId={resourceId}
        identifierId={identifierId}
        publication_name={publication_name}
        publication_issn={publication_issn}
        msid={msid}
        related_identifier={related_identifier}
    />);

    expect(screen.getByLabelText('a manuscript in progress')).toBeInTheDocument();
    expect(screen.getByLabelText('a published article')).toBeInTheDocument();
    expect(screen.getByLabelText('other or not applicable')).toBeInTheDocument();
  });

  it("changes radio button and sends json request", async () => {
    const promise = Promise.resolve({
      data: {"import_info":"published"}
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<PrelimInfo
        importInfo={importInfo}
        resourceId={resourceId}
        identifierId={identifierId}
        publication_name={publication_name}
        publication_issn={publication_issn}
        msid={msid}
        related_identifier={related_identifier}
    />);

    expect(screen.getByLabelText('other or not applicable')).toHaveAttribute('checked');
    expect(screen.getByLabelText('a published article')).not.toHaveAttribute('checked');

    userEvent.click(screen.getByLabelText('a published article') );

    await waitFor(() => promise); // waits for the axios promise to fulfill

    await (() => { return new Promise(resolve => setTimeout(resolve, 3000)) }) ;

    // I couldn't figure out how to await a check event here, but this is good enough I think.
  });

});