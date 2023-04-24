module StashEngine
  class CurationActivityPolicy
    attr_reader :user, :resource

    def initialize(user, resource)
      @user = user
      @resource = resource
    end

    def index?
      @user.limited_curator?
    end

    def curation_note?
      @user.limited_curator?
    end

  end
end
