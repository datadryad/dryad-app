# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe Resource do

      before(:each) do
        @resource = create(:resource)
      end

      describe '#method' do

      end
    end
  end
end