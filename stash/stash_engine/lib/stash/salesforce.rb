# use example
# require 'stash/salesforce'
# Stash::Salesforce.find('Lead', '00Q5e000007HsfvEAC')
# Stash::Salesforce.case_id(case_num: '00006729')

# Restforce doesn't consistently implement 'empty?',
# so don't allow Rubocop to suggest it
# rubocop:disable Style/ZeroLengthPredicate

module Stash
  class Salesforce

    # Retrieve globally unique case_id from a Dryad-specific case_num
    def self.case_id(case_num:)
      return unless case_num

      result = db_query("SELECT Id FROM Case Where CaseNumber = '#{case_num}'")
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
      result = db_query("SELECT Id FROM Case Where Subject like '%#{doi}%' " \
                        "or DOI__c like '%#{doi}%' ")
      return unless result && result.size > 0

      cases_found = []
      result.each do |res|
        found = find(obj_type: 'Case', obj_id: res['Id'])
        next unless found&.CaseNumber

        cases_found << { title: "SF #{found.CaseNumber}", path: case_view_url(case_num: found.CaseNumber) }.to_ostruct
      end
      cases_found
    end

    def self.current_user
      sf_client.user_info
    end

    def self.find(obj_type:, obj_id:)
      sf_client.find(obj_type, obj_id)
    end

    def self.db_query(query)
      sf_client.query(query)
    end

    def self.create_case(identifier)
      return unless identifier

      sf_client.create('Case',
                       Subject: 'Ryan-test Your Dryad data submission - DOI:10.5061/dryad.0002a',
                       Description: 'This is a test',
                       Origin: 'Web',
                       SuppliedName: 'Web Name',
                       SuppliedEmail: 'web@email.com',
                       Reason: 'I love cases')
    end

    class << self
      private

      def sf_client
        return @sf_client if @sf_client

        @sf_client = Restforce.new(username: APP_CONFIG[:salesforce][:username],
                                   password: APP_CONFIG[:salesforce][:password],
                                   security_token: APP_CONFIG[:salesforce][:security_token],
                                   client_id: APP_CONFIG[:salesforce][:client_id],
                                   client_secret: APP_CONFIG[:salesforce][:client_secret],
                                   api_version: '39.0')
        @sf_client.authenticate!
        @sf_client
      end

    end
  end
end

# rubocop:enable Style/ZeroLengthPredicate
