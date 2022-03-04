import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import {nanoid} from 'nanoid';
import FunderAutocomplete from "./FunderAutocomplete";
import {showSavedMsg, showSavingMsg} from "../../../lib/utils";
import axios from "axios";

function FunderForm({resourceId, contributor, createPath, updatePath}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const formRef = useRef();
  const contribId = (contributor?.id || nanoid());

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik or read it
  const [acText, setAcText] = useState(name);
  const [acID, setAcID] = useState(id);

  return (
      <Formik
          initialValues={
            {
              award_number: (contributor.award_number || ''),
              id: (contributor.id || '')
            }
          }
          innerRef={formRef}
          onSubmit={(values, {setSubmitting}) => {
            console.log('submitting form w/ formik values');

            showSavingMsg();
            const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
            const submitVals = {
              authenticity_token: csrf,
              contributor: {
                id: (values.id || null),
                contributor_name: acText,
                contributor_type: 'funder',
                identifier_type: (acID ? 'crossref_funder_id' : null),
                name_identifier_id: acID,
                resource_id: resourceId,
                award_number: values.award_number
              }
            }

            let url;
            let method;
            if (values.id) {
              url = updatePath;
              method = 'patch';
            } else {
              url = createPath;
              method = 'post';
            }

            axios({
              method,
              url,
              data: submitVals,
              headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
            }).then((data) => {
              if (data.status !== 200) {
                console.log('Response failure not a 200 response from research facility save');
              }
              formRef.current.setFieldValue('id', data.data.id);
              showSavedMsg();
            });
          }}
      >
        {(formik) => (
            <Form className="c-input__inline">
              <Field name="id" type="hidden"/>>
              <div className="c-input">
                <FunderAutocomplete id={contributor.name_identifier_id}
                                    name={contributor.contributor_name}
                                    formRef={formRef}
                                    acText={acText}
                                    setAcText={setAcText}
                                    acID={acID}
                                    setAcID={setAcID}
                                    controlOptions={
                                      {
                                        'htmlId': `contrib_${contribId}`,
                                        'labelText': 'Granting Organization',
                                        'isRequired': false
                                      }
                                    }
                />
              </div>
              <div className="c-input">
                <label className="c-input__label" htmlFor={`contributor_award_number__${contribId}`}>Award
                  Number</label>
                <Field
                    id={`contributor_award_number__${contribId}`}
                    name="award_number"
                    type="text"
                    className="js-award_number c-input__text"
                    onBlur={() => { // defaults to formik.handleBlur
                      formik.handleSubmit();
                    }}
                />
              </div>

              <a role="button"
                 className="remove_record t-describe__remove-button o-button__remove"
                 rel="nofollow" href="#"
              >remove</a>
            </Form>
        )}
      </Formik>
  );
}

export default FunderForm;