module StashDatacite
  module RelatedIdentifiersHelper

    def icons
      {
        primary_article: '<i class="fas fa-newspaper" role="img" aria-label="(opens in new window) "></i>',
        article: '<i class="far fa-newspaper" role="img" aria-label="(opens in new window) "></i>',
        dataset: '<i class="fas fa-table" role="img" aria-label="(opens in new window) "></i>',
        software: '<i class="fas fa-code-branch" role="img" aria-label="(opens in new window) "></i>',
        preprint: '<i class="fas fa-receipt" role="img" aria-label="(opens in new window) "></i>',
        supplemental_information: '<i class="far fa-file-lines" role="img" aria-label="(opens in new window) "></i>',
        data_management_plan: '<i class="fas fa-list-check" role="img" aria-label="(opens in new window) "></i>',
        undefined: ''
      }
    end

    def prim_article_ids
      @resource.related_identifiers.where(work_type: :primary_article).where(hidden: false).order(work_type: :desc)
    end

    def article_ids
      @resource.related_identifiers.where(work_type: :article).where(hidden: false).order(work_type: :desc)
    end

    def unpublished
      @resource.identifier.latest_resource_with_public_download.nil?
    end

    def other_relations
      if @resource&.resource_type&.resource_type == 'collection'
        @resource.related_identifiers.select(:work_type).where(hidden: false)
          .where.not(work_type: %i[article primary_article]).where.not(relation_type: 'haspart').distinct.order(:work_type)
      else
        @resource.related_identifiers.select(:work_type).where(hidden: false)
          .where.not(work_type: %i[article primary_article]).distinct.order(:work_type)
      end
    end

  end
end
