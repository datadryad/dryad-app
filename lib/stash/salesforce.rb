# use example
# require 'stash/salesforce'
# Stash::Salesforce.find(obj_type: 'Case', obj_id: '00Q5e000007HsfvEAC')
# Stash::Salesforce.case_id(case_num: '00006729')

require 'restforce'

# Restforce doesn't consistently implement 'empty?',
# so don't allow Rubocop to suggest it
# rubocop:disable Style/ZeroLengthPredicate

module Stash
  class Salesforce

    # ###### Generic operations #######

    def self.find(obj_type:, obj_id:)
      sf_client&.find(obj_type, obj_id)
    end

    # Update an object, using Salesforce field names in the kv_hash like {ISSN__c: '1234-5678'}
    def self.update(obj_type:, obj_id:, kv_hash:)
      sf_client&.update(obj_type, Id: obj_id, **kv_hash)
    end

    def self.db_query(query)
      sf_client&.query(query)
    end

    # ##### Cases #####

    # Retrieve globally unique case_id from a Dryad-specific case_num
    def self.case_id(case_num:)
      return unless case_num

      result = db_query("SELECT Id FROM Case Where CaseNumber = '#{case_num}' " \
                        "or CaseNumber like '%00#{case_num}'")
      return unless result && result.size > 0

      result.first['Id']
    end

    def self.case_view_url(case_id: nil, case_num: nil)
      return unless case_id.present? || case_num.present?

      case_id = case_id(case_num: case_num) unless case_id.present?
      return unless case_id.present?

      "#{APP_CONFIG[:salesforce][:server]}/lightning/r/Case/#{case_id}/view"
    end

    def self.find_cases_by_doi(doi)
      result = db_query("SELECT Id, Status, Case_Reasons__c, Reason, Case_Reason_Other__c FROM Case Where Subject like '%#{doi}%' " \
                        "or DOI__c like '%#{doi}%' ")
      return unless result && result.size > 0

      cases_found = []
      result.each do |res|
        found = find(obj_type: 'Case', obj_id: res['Id'])
        next unless found&.CaseNumber

        reason = if found.Case_Reasons__c.present? && found.Case_Reasons__c != 'Other'
                   found.Case_Reasons__c
                 elsif found.Reason.present? && found.Reason != 'Other'
                   found.Reason
                 else
                   found.Case_Reason_Other__c
                 end

        cases_found << { title: "SF #{found.CaseNumber}",
                         path: case_view_url(case_num: found.CaseNumber),
                         status: found.Status,
                         reason: reason }.to_ostruct
      end
      cases_found
    end

    def self.create_case(identifier:, owner:)
      return unless identifier && owner && sf_client

      case_user = identifier.latest_resource&.owner_author || identifier.latest_resource&.user

      case_id = sf_client.create('Case',
                                 Subject: "Your Dryad data submission - DOI:#{identifier.identifier}",
                                 DOI__c: identifier.identifier,
                                 Dataset_Title__c: identifier.latest_resource&.title,
                                 Origin: 'Web',
                                 SuppliedName: user_name(case_user),
                                 SuppliedEmail: user_email(case_user),
                                 Journal__c: find_account_by_name(identifier.journal&.title),
                                 Institutional_Affiliation__c: find_account_by_name(identifier.latest_resource&.user&.tenant&.long_name))

      # Update the OwnerId after the case is created, because if the Id does not match
      # an existing SF user with the correct permissions, it would prevent the case from being created.
      owner_id = find_user_by_orcid(owner.orcid)
      sf_client.update('Case', Id: case_id, OwnerId: owner_id) if owner_id

      case_id
    end

    # ###### Users ######

    def self.sf_user
      sf_client&.user_info
    end

    def self.find_user_by_orcid(orcid)
      result = db_query("SELECT Id FROM User Where EmployeeNumber='#{orcid}'")
      return unless result && result.size > 0

      result.first['Id']
    end

    def self.find_account_by_name(name)
      return unless name

      result = db_query("SELECT Id FROM Account Where Name='#{name.gsub("'", "\\\\'")}'")
      return unless result && result.size > 0

      result.first['Id']
    end

    # ####### Private internal methods ######

    class << self
      private

      def sf_client
        return @sf_client if @sf_client

        begin
          @sf_client = ::Restforce.new(username: APP_CONFIG[:salesforce][:username],
                                       password: APP_CONFIG[:salesforce][:password],
                                       host: APP_CONFIG[:salesforce][:login_host],
                                       security_token: APP_CONFIG[:salesforce][:security_token],
                                       client_id: APP_CONFIG[:salesforce][:client_id],
                                       client_secret: APP_CONFIG[:salesforce][:client_secret],
                                       api_version: '39.0')
          @sf_client.authenticate!
          @sf_client
        rescue StandardError => e
          Rails.logger.error("Failed to initialize Salesforce client -- #{e}")
          nil
        end
      end

      # rubocop:disable Style/NestedTernaryOperator
      def user_email(user)
        user.present? ? (user.respond_to?(:author_email) ? user.author_email : user.email) : nil
      end

      def user_name(user)
        user.present? ? (user.respond_to?(:author_standard_name) ? user.author_standard_name : user.name) : nil
      end
      # rubocop:enable Style/NestedTernaryOperator

    end
  end
end

# rubocop:enable Style/ZeroLengthPredicate
