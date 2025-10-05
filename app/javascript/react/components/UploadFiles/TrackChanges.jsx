import React, {useState, useEffect} from 'react';
import axios from 'axios';

export default function TrackChanges({resource}) {
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
