module StashEngine
  class ResourcePolicy < ApplicationPolicy

    def create?
      @user.present?
    end

    def new?
      create?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        @scope.where(user_id: @user.id)
      end

      private

      attr_reader :user, :scope
    end

    class VersionScope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.nil?
          @scope.with_visibility(states: %w[published embargoed])
        elsif @user.limited_curator?
          @scope.all
        else
          tenant_admin = (@user.tenant_id if @user.role == 'admin')
          @scope.with_visibility(states: %w[published embargoed],
                                 tenant_id: tenant_admin,
                                 funder_ids: @user.funders_as_admin.map(&:funder_id),
                                 journal_issns: @user.journals_as_admin.map(&:single_issn),
                                 user_id: @user.id)
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
