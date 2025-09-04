import React, {useRef, useEffect} from 'react';

export default function TitlePreview({resource, previous}) {
  const titleRef = useRef(null);
  const prevRef = useRef(null);

  useEffect(() => {
    if (titleRef.current) titleRef.current.innerHTML = resource.title;
  }, [titleRef.current]);

  useEffect(() => {
    if (prevRef.current) prevRef.current.innerHTML = previous.title;
  }, [prevRef.current]);

  /* eslint-disable jsx-a11y/heading-has-content */
  if (previous && resource.title !== previous.title) {
    return (
      <h2 className="o-heading__level1">
        <ins ref={titleRef} />{previous.title && <del ref={prevRef} />}
      </h2>
    );
  }
  return <h2 className="o-heading__level1" ref={titleRef} />;
  /* eslint-enable jsx-a11y/heading-has-content */
}
