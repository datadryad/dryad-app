require 'db_spec_helper'

# Find definitions explicitly per https://github.com/thoughtbot/factory_girl/issues/793
# FactoryGirl.find_definitions

describe 'FactoryGirl factories' do
  # See https://robots.thoughtbot.com/testing-your-factories-first
  FactoryGirl.factories.map(&:name).each do |factory_name|
    describe "The #{factory_name} factory" do
      it 'is valid' do
        model_instance = build(factory_name)
        expect(model_instance).to be_valid
        expect(model_instance).to be_new_record
      end

      it 'persists on create' do
        model_instance = create(factory_name)
        expect(model_instance).to be_persisted
      end
    end
  end
end

