import React from 'react';

import 'frictionless-components/lib/styles';
import {render} from 'frictionless-components/lib/render';
import {Report} from 'frictionless-components/lib/components/Report';

class ModalValidationReport extends React.Component {
    componentDidMount() {
        const element = document.getElementById('validation_report');
        render(Report, JSON.parse(this.props.report), element);
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
                        {/* TODO: this div just while don't have UI classes defined.
                            So we can place it here for applying "c-uploadmodal__header"
                            class and have the close button right aligned before
                            the title of the modal goes here */}
                        <div/>
                        <button className="c-uploadmodal__button-close-modal js-uploadmodal__button-close-modal"
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