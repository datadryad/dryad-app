class PrimaryArticleJob < BaseJob
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 2, lock: :until_and_while_executing

  def perform(work_id)
    primary_article = StashDatacite::RelatedIdentifier.find_by(id: work_id)
    resource = primary_article.resource
    return if resource.nil?

    p "#{Time.current} - Searching Crossref for updates for #{resource.id}"
    article_doi = Integrations::Crossref.bare_doi(doi_string: primary_article.related_identifier)
    item = Integrations::Crossref.query_by_doi(doi: article_doi)
    update = item&.[]('updated-by')&.find { |u| u['type'] == 'retraction' }
    if update.present?
      Stash::Import::Crossref.new(resource: resource, json: update).to_retraction_note
    else
      RelatedIdentifierService.new(resource).remove_concern_note
    end
  end
end
