import React from 'react';

const Title = ({ resource }) => {
  // see https://stackoverflow.com/questions/54808071/cant-verify-csrf-token-authenticity-rails-react for other options
  const csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content");

  // the title should ALWAYS be a patch request for sending data, since it's a field in the resource model
  // which should always be created before any metadata entry for title is performed
  return (
    <form id="resource_title_REPLACE_ME"
          className="c-input"
          action="/stash_datacite/titles/update#REPLACE_ME" acceptCharset="UTF-8"
          data-remote="true" method="post" _lpchecked="1">
      <input name="utf8" type="hidden" value="✓" />
      <input type="hidden" name="_method" value="patch" />
      <input type="hidden" name="authenticity_token" value={csrf} />
      <strong>
        <label className="required c-input__label" htmlFor={`title__${resource.id}`} >Dataset Title</label>
      </strong><br />
      <input type="text" name="title" id={`title__${resource.id}`} value={resource.title} className="title c-input__text" size="130" />
      <input type="hidden" name="id" id="id" value={resource.id} />
      <input type="hidden" name="form_id" id="form_id" value={`resource_title_${resource.id}`} />
    </form>
  );
}

export default Title;