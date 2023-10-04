/**
 * @jest-environment jsdom
 */

import ReactDOM, {unmountComponentAtNode} from 'react-dom';
import React from 'react';
import {act} from 'react-dom/test-utils';
import Title from '../../../../../app/javascript/react/components/MetadataEntry/Title';

let container = null;
beforeEach(() => {
  // setup a DOM element as a render target
  container = document.createElement('div');
  document.body.appendChild(container);
});

afterEach(() => {
  // cleanup on exiting
  unmountComponentAtNode(container);
  container.remove();
  container = null;
});

describe('Title', () => {
  it('renders a basic title', () => {
    const info = {
      resource: {id: 27, title: 'My test of rendering title', token: '12xu'},
      path: '/stash_datacite/titles/update',
    };

    act(() => {
      ReactDOM.render(<Title resource={info.resource} path={info.path} />, container);
    });

    const input = container.querySelector('input#title__27');
    expect(input).toBeDefined();
  });
});
