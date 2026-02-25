namespace :subscriptions do
  desc 'Send email updates for saved searches'
  task saved_searches: :environment do
    StashEngine::PublicSearch.subscribed.find_each do |search|
      next unless search.user.email.present?

      json = search.email_updates
      next unless json.present?

      StashEngine::UserMailer.search_subscription(search, json).deliver_now
    end
  end
end
