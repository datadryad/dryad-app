# trying to organize like http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/ to keep things less cluttered
class AdminDatasetsController
  class Stats

    PREHISTORIC_TIME = Time.new(-60000, 1, 1)

    # leave tenant_id blank if you want stats for all
    def initialize(tenant_id: nil, since: PREHISTORIC_TIME)
      @tenant_id = tenant_id
      @since = since
    end

    def user_count
      @user_count = User.all.where(['stash_engine_users.created_at > ?', @since])
      @user_count = @user_count.where(tenant_id: @tenant_id) unless @tenant_id.nil?
      @user_count = @user_count.count
    end

    def dataset_count

    end

    def datasets_started_count

    end

    def datasets_submitted_count

    end

  end
end