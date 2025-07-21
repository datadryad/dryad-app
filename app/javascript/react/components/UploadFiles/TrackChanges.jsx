import React, {useState, useEffect, useCallback} from 'react';
import {debounce} from 'lodash';
import axios from 'axios';
import MarkdownEditor from '../MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export function ChangeNote({resource}) {
  const [note, setNote] = useState({});
  const [value, setValue] = useState('');
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const postNote = (e) => {
    axios.post(`/file_note/${note.id}`, {authenticity_token, note: e.currentTarget.value});
  };

  useEffect(() => {
    async function getNote() {
      axios.get(`/file_note/${resource.id}`).then((data) => {
        setNote(data.data);
        setValue(data.data.note);
      });
    }
    getNote();
  }, []);

  if (note) {
    return (
      <div className="input-stack" style={{margin: '1em 0'}}>
        <label className="input-label" htmlFor="file-note-area">
          Describe your file changes for our data curators. These comments are not published.
        </label>
        <textarea
          className="c-input__textarea"
          id="file-note-area"
          rows={3}
          value={value || ''}
          onBlur={postNote}
          onChange={(e) => setValue(e.currentTarget.value)}
        />
      </div>
    );
  }
  return null;
}

export default function TrackChanges({resource, setResource, current}) {
  const [log, setLog] = useState(resource.descriptions?.find((d) => d.description_type === 'changelog'));
  const [desc, setDesc] = useState('');

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const submit = (value) => {
    if (log && log.description !== value) {
      const subJson = {
        authenticity_token,
        description: {
          description: value,
          resource_id: resource.id,
          id: log.id,
        },
      };
      showSavingMsg();
      axios.patch(
        '/stash_datacite/descriptions/update',
        subJson,
        {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
      ).then((data) => {
        setLog(data.data);
        showSavedMsg();
      });
    }
  };

  const checkSubmit = useCallback(debounce(submit, 900), []);

  const create = (val) => {
    showSavingMsg();
    axios.post(
      '/stash_datacite/descriptions/create',
      {
        authenticity_token, resource_id: resource.id, type: 'changelog', val,
      },
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      showSavedMsg();
      setLog(data.data);
    });
  };

  useEffect(() => {
    if (log?.id) {
      setResource((r) => ({
        ...r,
        descriptions: [log, ...r.descriptions.filter((d) => d.id !== log.id)],
      }));
    }
  }, [log]);

  useEffect(() => {
    if (current) setDesc(`${log.description || ''}`);
  }, [current]);

  useEffect(() => {
    if (!log) create(null);
  }, []);

  return (
    <div style={{marginTop: '2em'}}>
      <h4 id="log-label">Public change log</h4>
      <p id="log-desc">
        Your dataset has been published, so a written statement listing changes made to published files is required.
        This change log will appear with the next published version of your dataset.
      </p>
      <MarkdownEditor
        id="changelog-editor"
        attr={{
          'aria-errormessage': 'log_error',
          'aria-labelledby': 'log-label',
          'aria-describedby': 'log-desc',
        }}
        initialValue={desc}
        onChange={checkSubmit}
      />
    </div>
  );
}
