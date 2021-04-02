import React from 'react';
import classes from './ModalUrl.module.css';
import ConfirmSubmit from "../ConfirmSubmit/ConfirmSubmit";

const modal_url = (props) => {
    return (
        <dialog className={classes.ModalUrl} open>
            <section className={classes.ModalUrlMain}>
                <form method='dialog' onSubmit={props.submitted}>
                    <div className="c-uploadmodal__header">
                        <label className="c-uploadmodal__textarea-url-label" htmlFor="location_urls">Enter
                            URLs</label>
                        <button className="c-uploadmodal__button-close-modal js-uploadmodal__button-close-modal"
                                aria-label="close" type="button" onClick={props.clicked} />
                    </div>
                    <textarea id="location_urls" className="c-uploadmodal__textarea-url" name="url"
                              onChange={props.changedUrls}
                              placeholder="List file location URLs here" />
                    <div className="c-uploadmodal__text-content">Place each URL on a new line.</div>
                    <ConfirmSubmit
                        id='confirm_to_validate'
                        buttonLabel='Validate Files'
                        disabled={props.disabled}
                        changed={props.changed} />
                </form>
            </section>
        </dialog>
    );
}

export default modal_url;