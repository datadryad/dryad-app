/**
 * @jest-environment jsdom
 */

import {shallow} from "enzyme"; // mount vs shallow (for superficial test)
import toJSON from "enzyme-to-json";
import React from "react";
import RorAutocomplete from "../../../../../app/javascript/react/components/MetadataEntry/RorAutocomplete.js";

describe('RorAutocomplete', () => {
  it("renders a basic autocomplete form", () => {

    const info = {name: 'Institute for Fermentation', id: 'https://ror.org/05nq89q24',
      'controlOptions': { htmlId: "instit_affil_1234", labelText: 'Institutional Affiliation', isRequired: true } }

    const wrapper = shallow(
        <RorAutocomplete {...info} />
    );

    expect(toJSON(wrapper)).toMatchSnapshot(); // this matches snapshot unless it's updated
  });

  it('should return list of institutions in dropdown', () => {
  });

  it('should select institution from dropdown and fill hidden fields', () => {
  });
});