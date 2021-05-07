import React from "react";

import Url from "./Url/Url";

const failed_url_list = (props) => {
    return (
        <div>
            <h1 className="o-heading__level2">Validation Status</h1>
            {props.failedUrls.map((url, index) => {
                return <Url
                    key={index}
                    click={() => props.clicked(index)}
                    url={url}
                />
            })}
        </div>
    )
}

export default failed_url_list;