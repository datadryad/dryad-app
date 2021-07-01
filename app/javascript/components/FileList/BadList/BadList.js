import React from "react";

const badList = (props) => {
  const errorFiles = filterForStatus("error", props.chosenFiles);
  const issueFiles = filterForStatus("issues", props.chosenFiles);
  if(errorFiles.length + issueFiles.length < 1) return (null);

  let errorMsg = '';
  let issueMsg = '';

  if(errorFiles.length > 0){
    errorMsg = <p>Our tabular format checker couldn't read {makeAndString(errorFiles)} correctly.
      Please check that file type is set correctly and the file appears correct.
    </p>;
  }

  if(issueFiles.length > 0){
    issueMsg = <p>Our tabular format checker found formatting issues in {makeAndString(issueFiles)}.
      Please view the issues from the links below and correct
      the issues, if appropriate.
    </p>;
  }

  return <div className="js-alert c-alert--error" role="alert">
      <div className="c-alert__text">
        {errorMsg}
        {issueMsg}
      </div>
      <button aria-label="close" className="js-alert__close o-button__close c-alert__close"></button>
    </div>;
}

// checks files to see if they have validation and also status
const filterForStatus = (status, files) => {
  let fns = files.map(file => {
    if (!file.hasOwnProperty("frictionless_report")) return null;

    if (file.frictionless_report?.status === status) return file.upload_file_name;

    return null;
  });

  // only return non-null
  return fns.filter(n => n);
}

const makeAndString = (arr) => {
  if (arr.length === 0) return "";
  if (arr.length === 1) return arr[0];
  const firsts = arr.slice(0, arr.length - 1);
  const last = arr[arr.length - 1];
  return firsts.join(', ') + ' and ' + last;
}

export default badList;