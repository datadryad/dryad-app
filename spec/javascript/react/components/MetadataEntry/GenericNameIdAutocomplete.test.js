import React from "react";
import {render, screen} from '@testing-library/react';


import GenericNameIdAutocomplete
  from "../../../../../app/javascript/react/components/MetadataEntry/GenericNameIdAutocomplete";

describe('RorAutocomplete', () => {
  it("renders an interior form", () => {
    // these ar simple replacements for useState that don't really produce functionality, just allow a static render
    const [acText, setAcText] = ['ralpheo', () => {}];
    const [acID, setAcID] = ['', () => {}];
    const [autoBlurred, setAutoBlurred] = [false, () => {}]
    const supplyLookupList = () => { return [ { "id": 1, "name": 'cat'}, { "id": 2, "name": 'dog' } ] };
    const nameFunc = (item) => item?.name;
    const idFunc = (item) => item?.id;
    const controlOptions = { "htmlId": "instit_affil_1234", "labelText": 'Institutional Affiliation', "isRequired": true };

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

    screen.debug();
    // expect(toJSON(wrapper)).toMatchSnapshot(); // this takes a snapshot of output when functioning correctly 1st time and then matches it later
  })
});