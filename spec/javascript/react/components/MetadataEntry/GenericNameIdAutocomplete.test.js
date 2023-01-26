import React from "react";
import {render, screen} from '@testing-library/react';

import GenericNameIdAutocomplete
  from "../../../../../app/javascript/react/components/MetadataEntry/GenericNameIdAutocomplete";

describe('GenericNameIdAutocomplete', () => {
  it("renders an interior form", () => {
    // these ar simple replacements for useState that don't really produce functionality, just allow a static render
    const [acText, setAcText] = ['ralpheo', () => {}];
    const [acID, setAcID] = ['', () => {}];
    const [autoBlurred, setAutoBlurred] = [false, () => {}]
    const supplyLookupList = () => { return [ { "id": 1, "name": 'cat'}, { "id": 2, "name": 'dog' } ] };
    const nameFunc = (item) => item?.name;
    const idFunc = (item) => item?.id;
    const controlOptions = { "htmlId": "instit_affil_1234", "labelText": 'Institutional affiliation', "isRequired": true };

    render(
      <GenericNameIdAutocomplete
          acText={acText || ''}
          setAcText={setAcText}
          acID={acID}
          setAcID={setAcID}
          setAutoBlurred={setAutoBlurred}
          supplyLookupList={supplyLookupList}
          nameFunc={nameFunc}
          idFunc={idFunc}
          controlOptions={controlOptions}
      />
    );

    // screen.debug();  // shows the html output of the document
    const labeledElements = screen.getAllByLabelText(controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(3);
    expect(labeledElements[0]).toHaveAttribute('value', 'ralpheo');
  })
});