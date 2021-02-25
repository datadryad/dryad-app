import React from "react"
// import PropTypes from "prop-types"
import UploadType from './UploadType/UploadType'
import classes from './UploadFiles.module.css';

class UploadFiles extends React.Component {
    state = {
        upload_type: [
            {
                name: 'Data', description: 'eg., Spreadsheets, example1, example2',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'},
            {
                name: 'Software', description: 'e.g., Example1, example2, example3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'},
            {
                name: 'Suplemental Information', description: 'e.g., Example1, example2, example3',
                buttonFiles: 'Choose Files', buttonURLs: 'Enter URLs'
            }
        ]
    };

    render () {
    return (
      <React.Fragment className={classes.UploadFiles}>
        <h1>Upload Files</h1>
        This is the resource: {this.props.resource_id}
          <p>Data is curated and preserved at Dryad. Software and supplemental information are preserved at Zenodo.</p>
          {this.state.upload_type.map(upload_type => {
              return <UploadType
                  name={upload_type.name}
                  description={upload_type.description}
                  buttonFiles={upload_type.buttonFiles}
                  buttonURLs={upload_type.buttonURLs} />
          })}
      </React.Fragment>
    );
  }
}

// UploadFiles.propTypes = {
//   greeting: PropTypes.string
// };
export default UploadFiles
