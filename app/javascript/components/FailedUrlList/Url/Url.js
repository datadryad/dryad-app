import React from 'react';

const url = (props) => {
    return (
        <div className="c-manifest__item">
            <div className="c-manifest__url">{props.url.url}</div>
            <div className="c-manifest__error">{props.url.error_message}</div>
            <div className="c-manifest__action">
                {/*<a href="#!">Edit</a>*/}
                <a href="#!" onClick={props.click}>Remove</a>
            </div>
        </div>
    )
}

export default url;