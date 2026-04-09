class RelatedIdentifierService
  attr_reader :primary_article, :resource
  include PublicationMixin

  def initialize(resource)
    @resource = resource
    @primary_article = resource.related_identifiers.find_by(work_type: 'primary_article', related_identifier_type: 'doi')
  end

  def process
    PublicationJob.perform_async(resource.last_curation_activity_id) if resource.status_published?
    if primary_article&.related_identifier&.present?
      set_primary_article
    else
      remove_concern_note
    end
  end

  def remove_concern_note
    re = %r{The <a href=".*">primary article associated with this dataset</a> has been retracted\.}
    notice = resource.descriptions.find_by(description_type: 'concern')
    return unless notice&.description&.present? && re.match?(notice&.description)

    # delete retraction text and destroy note if no other content
    notice.update(description: notice.description.gsub(re, ''))
    notice.update(description: notice.description.gsub('<p></p>', ''))
    notice.destroy unless notice.description.present?
  end

  private

  def set_primary_article
    release_resource(resource)
    check_resource_payment(resource)
    PrimaryArticleJob.perform_async(primary_article.id)
  end
end
