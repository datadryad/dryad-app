module StashEngine
  class ResourceState < ActiveRecord::Base
    belongs_to :user
    belongs_to :resource

    enum resource_state: %w(in_progress processing submitted error).map { |i| [i.to_sym, i] }.to_h
    validates :resource_state, presence: true
    private
  end
end
