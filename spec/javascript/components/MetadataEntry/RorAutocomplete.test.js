/**
 * @jest-environment jsdom
 */

import ReactDOM, {unmountComponentAtNode} from "react-dom";
import React from 'react';
import {act} from 'react-dom/test-utils';
import RorAutocomplete from "../../../../app/javascript/react/components/MetadataEntry/RorAutocomplete.js";

let container = null;
beforeEach(() => {
  // setup a DOM element as a render target
  container = document.createElement("div");
  document.body.appendChild(container);
});

afterEach(() => {
  // cleanup on exiting
  unmountComponentAtNode(container);
  container.remove();
  container = null;
});

describe('RorAutocomplete', () => {
  it("renders a basic autocomplete form", () => {
    const info = {name: 'Institute for Fermentation', id: 'https://ror.org/05nq89q24',
    'controlOptions': { htmlId: "instit_affil_1234", labelText: 'Institutional Affiliation', isRequired: true } }

    act(() => {
      ReactDOM.render( <RorAutocomplete {...info} />, container );
    });

    const input = container.querySelector('input#instit_affil_1234');
    expect(input).toBeDefined();
  });
});