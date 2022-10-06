import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import PrelimManu from "../../../../../app/javascript/react/components/MetadataEntry/PrelimManu";
import axios from 'axios';

jest.mock('axios');

describe('PrelimManu', () => {

  let resourceId, identifierId, publication_name, publication_issn, msid, acText, setAcText,
      acID, setAcID, msId, setMsId;

  beforeEach(() => {
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
      "value": `CROM-${faker.datatype.number({min:1000, max:9999})}-${faker.datatype.number({min:1000, max:9999})}`
    }

    acText = publication_name.value;
    setAcText = jest.fn();

    acID = publication_issn.value;
    setAcID = jest.fn();

    msId = msid.value;
    setMsId = jest.fn();
  });

  it("renders the basic article and manuscript id form", () => {
    render(<PrelimManu
        resourceId={resourceId}
        identifierId={identifierId}
        acText={acText}
        setAcText={setAcText}
        acID={acID}
        setAcID={setAcID}
        msId={msId}
        setMsId={setMsId} />);

    const labeledElements = screen.getAllByLabelText('Journal Name', { exact: false });
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', publication_name.value);
    expect(screen.getByLabelText('Manuscript Number')).toHaveValue(msid.value);
  });

  it("checks that updating fields triggers axios save on blur", async () => {

    const promise = Promise.resolve({
      status: 200,
      data: {}
    })

    axios.patch.mockImplementationOnce(() => promise);

    render(<PrelimManu
        resourceId={resourceId}
        identifierId={identifierId}
        acText={acText}
        setAcText={setAcText}
        acID={acID}
        setAcID={setAcID}
        msId={msId}
        setMsId={setMsId} />);

    userEvent.clear(screen.getByLabelText('Manuscript Number'));
    userEvent.type(screen.getByLabelText('Manuscript Number'), 'GUD-MS-387-555');

    await waitFor(() => expect(screen.getByLabelText('Manuscript Number')).toHaveValue('GUD-MS-387-555'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByText('Import Manuscript Metadata')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
  })

});