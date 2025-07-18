# == Schema Information
#
# Table name: dcs_resource_types
#
#  id                    :integer          not null, primary key
#  resource_type         :text(65535)
#  resource_type_general :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  resource_id           :integer
#
# Indexes
#
#  index_dcs_resource_types_on_resource_id  (resource_id)
#
require 'rails_helper'

module StashDatacite
  describe ResourcesSubjects do

    describe 'associations' do
      it { should belong_to(:resource) }
      it { should belong_to(:subject) }
    end

    describe 'validations' do
      it { should validate_presence_of(:subject_id) }
      it { should validate_uniqueness_of(:subject_id).scoped_to(:resource_id) }
    end
  end
end
