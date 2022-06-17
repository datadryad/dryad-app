/* eslint-disable jsx-a11y/label-has-associated-control */
// above eslint is too stupid to realize that the label and control match

import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

/* Formik makes it difficult to get a hold of some of the context to do some things manually unless you make the forms very
   verbose like the initial, "building Formik" ones at https://formik.org/docs/tutorial .  If you use the compact and less
   verbose function syntax (their final built examples) then it's difficult to get the context for manually triggering something like a submit.

  This page gives some options, https://stackoverflow.com/questions/49525057/react-formik-use-submitform-outside-formik ,
  but it doesn't seem to have complete information about  useFormikContext(). I got undefined variables or could only bind
  to the verbose version.  I believe it is also more geared toward for exposing context outside the component than within.

  I finally got a useRef solution to work. Look at formRef and useRef below.  Also 'formRef.current.submit()'. This is
  based on https://stackoverflow.com/questions/60491891/how-do-i-access-current-value-of-a-formik-field-without-submitting
  and the answer by Muhammed Rafeeq .  The solution by aturan23 seems to destructure the variables and doesn't cause errors,
  but the variables were then not accessible within my onBlur handler.
 */

function Cedar({resource, path}) {
    // see https://stackoverflow.com/questions/54808071/cant-verify-csrf-token-authenticity-rails-react for other options
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    
    const formRef = useRef();
    
    return (
	<h3 className="o-heading__level3">Standardized Metadata</h3>
    );
}

export default Cedar;
