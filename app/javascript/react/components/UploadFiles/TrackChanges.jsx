import React, {useState, useEffect} from 'react';
import axios from 'axios';

export default function TrackChanges({resource}) {
  const [note, setNote] = useState({});
  const [value, setValue] = useState('');

  const postNote = (e) => {
    axios.post(`/stash/file_note/${note.id}`, {note: e.currentTarget.value});
  };

  useEffect(() => {
    async function getNote() {
      axios.get(`/stash/file_note/${resource.id}`).then((data) => {
        setNote(data.data);
        setValue(data.data.note);
      });
    }
    getNote();
  }, []);

  if (note) {
    return (
      <form className="c-upload__changes-form">
        <label className="input-label" htmlFor="file-note-area">Describe your file changes</label>
        <textarea
          className="c-input__textarea"
          id="file-note-area"
          rows={3}
          value={value || ''}
          onBlur={postNote}
          onChange={(e) => setValue(e.currentTarget.value)}
        />
      </form>
    );
  }
  return null;
}
