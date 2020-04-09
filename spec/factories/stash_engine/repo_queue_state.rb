FactoryBot.define do

  factory :repo_queue_state, class: StashEngine::RepoQueueState do
    resource

    state { 'enqueued' }
    hostname { Faker::Number.number(digits: 5) }
  end
end