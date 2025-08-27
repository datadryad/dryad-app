require 'active_support/concern'

module StashEngine
  module Support
    module UserRoles
      extend ActiveSupport::Concern

      included do
        scope :curators, -> { joins(:roles).where('stash_engine_roles' => { role: 'curator', role_object_id: nil }) }

        scope :all_curators,  -> { joins(:roles).where('stash_engine_roles' => { role: 'curator' }) }
      end

      def tenant_limited?
        roles.any? { |r| r.role_object_type == 'StashEngine::Tenant' }
      end

      def admin?
        roles.any? { |r| r.role == 'admin' }
      end

      def curator?
        roles.any? { |r| r.role == 'curator' }
      end

      def manager?
        roles.any? { |r| r.role == 'manager' }
      end

      def superuser?
        roles.any? { |r| r.role == 'superuser' }
      end

      def system_user?
        roles.any? { |r| r.role_object_id.nil? }
      end

      def min_admin?
        roles.any? { |r| %w[superuser manager curator admin].include?(r.role) }
      end

      def min_app_admin?
        system_user? || min_curator?
      end

      def min_curator?
        roles.any? { |r| %w[superuser manager curator].include?(r.role) }
      end

      def min_manager?
        roles.any? { |r| %w[superuser manager].include?(r.role) }
      end

    end
  end
end
