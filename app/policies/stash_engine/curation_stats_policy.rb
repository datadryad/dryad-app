module StashEngine
  class CurationStatsPolicy
    attr_reader :user, :stats

    def initialize(user, stats)
      @user = user
      @stats = stats
    end

    def index?
      @user.admin?
    end

  end
end
