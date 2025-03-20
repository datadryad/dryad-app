class AffiliationsService

  attr_reader :affiliation
  def initialize(affiliation)
    @affiliation = affiliation
  end

  def make_uniq
    affiliations_with_same_name.each do |aff|
      next if aff.id == base_affiliation.id

      # updating authors affiliation with new affiliation
      aff.authors.each do |author|
        author.affiliations.destroy(aff)
        author.affiliations << base_affiliation unless author.affiliations.include?(base_affiliation)
      end
      aff.destroy
    end
  end

  def affiliations_with_same_name
    @affiliations_with_same_name ||= StashDatacite::Affiliation.where(long_name: affiliation.long_name)
  end

  private

  def base_affiliation
    return @base_affiliation if @base_affiliation

    @base_affiliation = affiliation
    if affiliation.ror_id.blank?
      ror_affiliation = affiliations_with_same_name.where.not(ror_id: nil).first
      @base_affiliation = ror_affiliation if ror_affiliation
    end
    @base_affiliation
  end
end
