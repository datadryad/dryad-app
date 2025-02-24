import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import PrelimManu from './PrelimManu';
import PrelimArticle from './PrelimArticle';
import PrelimOther from './PrelimOther';

function PrelimInfo(
  {
    importInfo, resourceId, identifierId, publication_name, publication_issn, msid, related_identifier, api_journals,
  },
) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const tempVal = importInfo;

  const [acText, setAcText] = useState(publication_name || '');
  const [acID, setAcID] = useState(publication_issn || '');
  const [msId, setMsId] = useState(msid || '');
  const [importType, setImportType] = useState(tempVal);
  const [relatedIdentifier, setRelatedIdentifier] = useState(related_identifier);

  const optionChange = (choice) => {
    setImportType(choice);

    axios.patch(
      `/resources/${resourceId}/import_type`,
      {authenticity_token: csrf, import_info: choice},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't change import_type on remote server");
        }
      });
  };

  return (
    <>
      <fieldset className="c-import__fieldset">
        <div className="js-contributors_form_top">
          <legend id="import-choices-label">My data is related to:</legend>
        </div>

        <div className="c-import__choicesbox js-import-choice">
          <div className="c-import__choicebox">
            <div className="c-import__icon"><i className="fas fa-pen-to-square fa-3x" aria-hidden="true" /></div>
            <div>
              <input
                type="radio"
                name="import_type"
                id="choose_manuscript"
                value="manuscript"
                checked={importType === 'manuscript'}
                onChange={() => { optionChange('manuscript'); }}
              />
              <label htmlFor="choose_manuscript">&nbsp;a manuscript in progress</label>
            </div>
          </div>

          <div className="c-import__choicebox">
            <div className="c-import__icon"><i className="fa fa-file-lines fa-3x" aria-hidden="true" /></div>
            <div>
              <input
                type="radio"
                name="import_type"
                id="choose_published"
                value="published"
                checked={importType === 'published'}
                onChange={() => { optionChange('published'); }}
              />
              <label htmlFor="choose_published">&nbsp;a published article</label>
            </div>
          </div>

          <div className="c-import__choicebox">
            <div className="c-import__icon"><i className="fa fa-table fa-3x" aria-hidden="true" /></div>
            <div>
              <input
                type="radio"
                name="import_type"
                id="choose_other"
                value="other"
                checked={importType === 'other'}
                onChange={() => { optionChange('other'); }}
              />
              <label htmlFor="choose_other">&nbsp;other or not applicable</label>
            </div>
          </div>
        </div>
      </fieldset>

      {(() => {
        switch (importType) {
        case 'manuscript':
          return (
            <PrelimManu
              resourceId={resourceId}
              identifierId={identifierId}
              acText={acText}
              setAcText={setAcText}
              acID={acID}
              setAcID={setAcID}
              msId={msId}
              setMsId={setMsId}
              hideImport={api_journals.includes(acID)}
            />
          );
        case 'published':
          return (
            <PrelimArticle
              resourceId={resourceId}
              identifierId={identifierId}
              acText={acText}
              setAcText={setAcText}
              acID={acID}
              setAcID={setAcID}
              relatedIdentifier={relatedIdentifier}
              setRelatedIdentifier={setRelatedIdentifier}
              hideImport={api_journals.includes(acID)}
            />
          );
        default:
          return (<PrelimOther />);
        }
      }
      )()}

    </>
  );
}

export default PrelimInfo;

PrelimInfo.propTypes = {
  importInfo: PropTypes.string.isRequired, // the type of import it is doing
  resourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  identifierId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  publication_name: PropTypes.string.isRequired,
  publication_issn: PropTypes.string.isRequired,
  msid: PropTypes.string.isRequired,
  related_identifier: PropTypes.string.isRequired,
  api_journals: PropTypes.array.isRequired,
};
