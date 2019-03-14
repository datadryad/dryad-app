require 'rails_helper'

# TODO: Setting this model up as an example using shoulda helpers. We should just
#       move the stash_engine model tests into this repo

# rubocop:disable Metrics/BlockLength
module StashEngine

  RSpec.describe User, type: :model do

    # Using shoulda helpers to assert model validations
    context 'validations' do

      # TODO: These fields should probably be required for data integrity purposes

      # it { is_expected.to validate_presence_of(:email) }
      # it { is_expected.to validate_presence_of(:tenant_id) }
      # it { is_expected.to validate_presence_of(:orcid) }

      # TODO: Emails should probably be unique
      it 'should validate that email address is unique' do
        user = build(:user)
        subject.email = user.email
        # is_expected.to validate_uniqueness_of(:email)
        #   .case_insensitive
        #   .with_message('has already been taken')
      end

      # TODO: Emails should probably be validated for format
      # it { is_expected.to allow_values('one@dryad.org', 'foo-bar@dryad.org').for(:email) }
      # it { is_expected.not_to allow_values('dryad.org', 'foo bar@dryad.org').for(:email) }

    end

    # Using shoulda helpers to assert associations
    context 'associations' do

      it { is_expected.to have_many(:resources) }

    end

    describe 'name should return "[first_name] [last_name]"' do

      let!(:user) { build(:user) }

      it 'returns the right value when first and last name are both available' do
        expect(user.name).to eql("#{user.first_name} #{user.last_name}")
      end

      it 'returns the first name if no last name is available' do
        user.last_name = nil
        expect(user.name).to eql(user.first_name)
      end

      it 'returns the last name if no first name is available' do
        user.first_name = nil
        expect(user.name).to eql(user.last_name)
      end

      it 'returns an empty string if no first or last name is available' do
        user.first_name = nil
        user.last_name = nil
        expect(user.name).to eql('')
      end

    end

  end

end
# rubocop:enable Metrics/BlockLength
