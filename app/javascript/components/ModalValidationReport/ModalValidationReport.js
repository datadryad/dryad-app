import React from 'react';

import classes from './ModalValidationReport.module.css';

import '@cdl-dryad/frictionless-components/lib/styles';
import {render} from '@cdl-dryad/frictionless-components/lib/render';
import {Report} from '@cdl-dryad/frictionless-components/lib/components/Report';


class ModalValidationReport extends React.Component {
    componentDidMount() {
        const element = document.getElementById('validation_report');
        render(Report, JSON.parse(this.props.file.frictionless_report.report), element);
    }

    render () {
        return (
            <div>
                <dialog className="c-uploadmodal"
                        style={{
                            'width': '60%', 'max-width': '950px', 'min-width': '220px',
                            'z-index': '100149', 'top': '50%'}}
                        open>
                    <div className="c-uploadmodal__header">
                        <h2 className="c-datasets-heading__heading o-heading__level1">Formatting Report: {this.props.file.sanitized_name}</h2>
                        <button className={classes.CloseButton}
                                aria-label="close"
                                type="button"
                                onClick={(event) => this.props.clickedClose(event)} />
                    </div>
                    <div id="validation_report">
                    </div>
                </dialog>
                <div className="backdrop" style={{'z-index': '100148'}} />
            </div>
        )
    }
}

export default ModalValidationReport;