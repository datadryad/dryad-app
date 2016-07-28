module StashDatacite
  class Contributor < ActiveRecord::Base
    self.table_name = 'dcs_contributors'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :name_identifier
    has_and_belongs_to_many :affiliations, :class_name => 'StashDatacite::Affiliation'

    ContributorTypes = %w(ContactPerson DataCollector DataCurator DataManager Distributor Editor Funder
          HostingInstitution Other Producer ProjectLeader ProjectManager ProjectMember RegistrationAgency
          RegistrationAuthority RelatedPerson ResearchGroup RightsHolder Researcher Sponsor Supervisor
          WorkPackageLeader)

    ContributorTypesEnum = ContributorTypes.map{|i| [i.downcase.to_sym, i.downcase]}.to_h
    ContributorTypesStrToFull = ContributorTypes.map{|i| [i.downcase, i]}.to_h

    enum contributor_type: ContributorTypesEnum

    before_save :strip_whitespace

    amoeba do
      enable
    end

    def contributor_type_friendly=(type)
      # self required here to work correctly
      self.contributor_type = type.to_s.downcase unless type.blank?
    end

    def contributor_type_friendly
      return nil if contributor_type.blank?
      ContributorTypesStrToFull[contributor_type]
    end

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation_id=(affil_id)
      self.affiliation_ids = affil_id
    end

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation_id
      affiliation_ids.try(:first)
    end

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation=(affil)
      affiliations.clear
      affiliations << affil
    end

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation
      affiliations.try(:first)
    end

    private
    def strip_whitespace
      self.contributor_name = self.contributor_name.strip unless self.contributor_name.nil?
      self.award_number =  self.award_number.strip unless self.award_number.nil?
    end
  end
end
