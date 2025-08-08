import React from 'react';

export default function TitlePreview({resource, previous}) {
  return (
    <h2 className="o-heading__level1">
      {previous && resource.title !== previous.title ? (
        <><ins>{resource.title}</ins>{previous.title && <del>{previous.title}</del>}</>
      ) : resource.title}
    </h2>
  );
}
