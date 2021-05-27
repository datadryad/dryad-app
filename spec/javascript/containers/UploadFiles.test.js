/**
 * @jest-environment jsdom
 */

/* some resources for testing
https://medium.com/@kylefox/how-to-setup-javascript-testing-in-rails-5-1-with-webpacker-and-jest-ef7130a4c08e
https://jestjs.io/docs/configuration
https://jest-bot.github.io/jest/docs/configuration.html
https://reactjs.org/docs/testing-recipes.html
https://reactjs.org/docs/test-utils.html

const uploadFiles = require('UploadFiles.js');
 */

import ReactDOM, {unmountComponentAtNode} from "react-dom";
import React from 'react';
import {act} from 'react-dom/test-utils';
import UploadFiles from '../../../app/javascript/containers/UploadFiles.js'

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

describe('upload files', () => {
  it('renders something useful', () => {
    act(() => {
      /* react_component("UploadFiles", {
        resource_id: @resource.id,
        file_uploads: @resource.generic_files.validated_table.map(&:attributes),
      app_config_s3: APP_CONFIG[:s3],
      s3_dir_name: @resource.s3_dir_name(type: 'base') */
      ReactDOM.render(<UploadFiles
        resourceId={333}
        fileUploads={[]}
        appConfigS3={}
      />, container);
    });
    // make assertions
  });
});

