# == Schema Information
#
# Table name: dcs_credit_roles
#
#  id               :bigint           not null, primary key
#  contributor_type :string(191)
#  credit_role      :string(191)
#  description      :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  credit_id        :string(191)
#
module StashDatacite
  class CreditRole < ApplicationRecord
    self.table_name = 'dcs_credit_roles'

    has_many :credit_role_authors, class_name: 'StashDatacite::CreditRoleAuthor', dependent: :destroy
    has_many :authors, class_name: 'StashEngine::Author', through: :credit_role_authors

    ContributorTypes = Datacite::Mapping::ContributorType.map(&:value)

    ContributorTypesEnum = ContributorTypes.to_h { |i| [i.downcase.to_sym, i.downcase] }
    ContributorTypesStrToFull = ContributorTypes.to_h { |i| [i.downcase, i] }

    enum :contributor_type, ContributorTypesEnum

    def contributor_type_friendly=(type)
      self.contributor_type = type.to_s.downcase unless type.blank?
    end

    def contributor_type_friendly
      return nil if contributor_type.blank?

      ContributorTypesStrToFull[contributor_type]
    end

    def self.contributor_type_mapping_obj(str)
      return nil if str.nil?

      Datacite::Mapping::ContributorType.find_by_value(str)
    end

    def contributor_type_mapping_obj
      return nil if contributor_type_friendly.nil?

      CreditRole.contributor_type_mapping_obj(contributor_type_friendly)
    end

  end
end
