import React from 'react';

function RelatedWorksErrors(
    {relatedIdentifier}
){
  // empty related identifier
  if(!relatedIdentifier.related_identifier){
    return (null);
  }

  return (
    <div>
      {!relatedIdentifier.valid_url_format &&
        <div className="o-metadata__autopopulate-message">
          We can't match the identifier provided with any known repository or publisher. Please make sure you have
          included the correct URL or DOI.
        </div>
      }

      {!relatedIdentifier.verified &&
        <div className="o-metadata__autopopulate-message">
          The identifier provided could not be verified. Please make sure you have included the correct DOI
          for your related work.
        </div>
      }
    </div>
  );
}

export default RelatedWorksErrors;


/*
<div class="js-related_id_errors">
  <% unless related_identifier&.related_identifier.blank? %>
    <% unless related_identifier.valid_url_format? %>
      <div class="o-metadata__autopopulate-message">
        We can't match the identifier provided with any known repository or publisher. Please make sure you have
        included the correct URL or DOI.
      </div>
    <% end %>
    <% unless related_identifier.verified? %>
      <div class="o-metadata__autopopulate-message">
        The identifier provided could not be verified. Please make sure you have included the correct DOI
        for your related work.
      </div>
    <% end %>
  <% end %>
</div>
 */