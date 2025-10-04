import React, {useState, useEffect, useCallback} from 'react';
import {debounce} from 'lodash';
import axios from 'axios';
import MarkdownEditor from '../MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function Editor({initial, log, setLog}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const submit = (value) => {
    if (log && log.description !== value) {
      const subJson = {
        authenticity_token,
        description: {
          description: value,
          resource_id: log.resource_id,
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

  return (
    <MarkdownEditor
      id="changelog-editor"
      attr={{
        'aria-errormessage': 'log_error',
        'aria-labelledby': 'log-label',
        'aria-describedby': 'log-desc',
      }}
      initialValue={initial}
      onChange={checkSubmit}
    />
  );
}

export default function ChangeLog({resource, pubDates, setResource}) {
  const [desc, setDesc] = useState('');
  const [log, setLog] = useState(resource.descriptions.find((d) => d.description_type === 'changelog'));

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

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
      setResource((r) => ({...r, descriptions: [log, ...r.descriptions.filter((d) => d.if !== log.id)]}));
    }
  }, [log]);

  useEffect(() => {
    let logStr = `${log?.description || ''}`;
    pubDates.forEach((date) => {
      if (!logStr.includes(date)) {
        if (logStr) logStr += '\n\n';
        logStr += `**Changes after ${date}:**&nbsp;`;
      }
    });
    setDesc(logStr);
    const existing = resource.descriptions.find((d) => d.description_type === 'changelog');
    if (existing) setLog(existing);
    else create(null);
  }, []);

  return (
    <div style={{marginTop: '2em'}}>
      <h4 id="log-label">Public change log</h4>
      <p id="log-desc">
        Your dataset has been published, so a written statement describing file changes since the previous version is required.
        This change log will appear with the next published version of your dataset.
      </p>
      {log?.id && (
        <Editor initial={desc} log={log} setLog={setLog} />
      )}
    </div>
  );
}
