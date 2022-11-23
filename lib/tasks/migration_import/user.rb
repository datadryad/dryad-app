module Tasks
  module MigrationImport
    class User

      attr_reader :hash

      def initialize(hash:)
        @hash = hash.with_indifferent_access
      end

      def user_id
        u = StashEngine::User.find_by(email: @hash[:email])
        return u.id unless u.nil?

        # leaving out doorkeeper application and we can ask two people to re-set up their API access
        save_hash = @hash.slice('first_name', 'last_name', 'email', 'created_at', 'updated_at', 'tenant_id', 'last_login', 'role', 'orcid')
        @user_obj = StashEngine::User.create(save_hash)
        @user_obj.id
      end

    end
  end
end
