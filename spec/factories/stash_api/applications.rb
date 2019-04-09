FactoryBot.define do
  factory :doorkeeper_application, class: Doorkeeper::Application do
    sequence(:name) { |n| "Application #{n}" }
    redirect_uri { "https://app.com/callback" }
  end
end