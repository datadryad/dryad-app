import React from 'react';

function Title() {
  // the title should ALWAYS be a patch request for sending data, since it's a field in the resource model
  // which should always be created before any metadata entry for title is performed
  return (
    <form id="resource_title_REPLACE_ME"
          className="c-input"
          action="/stash_datacite/titles/update#REPLACE_ME" accept-charset="UTF-8"
          data-remote="true" method="post" _lpchecked="1">
      <input name="utf8" type="hidden" value="✓" />
      <input type="hidden" name="_method" value="patch_REPLACE_ME" />
      <input type="hidden" name="authenticity_token" value="patch_REPLACE_ME" />
      <strong>
        <label className="required c-input__label" htmlFor="title__REPLACE_ME">Dataset Title</label>
      </strong><br />
      <input type="text" name="title" id="title__REPLACE_ME" value="title REPLACE_ME" className="title c-input__text" size="130" />
      <input type="hidden" name="id" id="id" value="3511_REPLACE_ME" />
      <input type="hidden" name="form_id" id="form_id" value="resource_title_REPLACE_ME" />
    </form>
  );
}

export default Title;