module StashEngine
  class ResourcePolicy
    attr_reader :user, :resource

    def initialize(user, resource)
      @user = user
      @resource = resource
    end

    def create?
      @user.present?
    end

    def new?
      create?
    end

    # def update?
    #  @user = @resource.current_editor_id
    # end

    # def edit?
    #  update?
    # end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        if @user.limited_curator?
          @scope.all
        elsif @user.journals_as_admin.present? || @user.funders_as_admin.present?
          @scope.where(admin_for_this_item?)
        else
          @scope.where(user_id: @user.user_id)
        end
      end

      private

      attr_reader :user, :scope
    end
  end
end
