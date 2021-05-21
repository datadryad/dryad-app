require 'rails_helper'

module StashEngine
  RSpec.describe GenericFilesController, type: :request do
    describe 'frictionless integration test' do
      it 'can call external process' do
        result = `frictionless validate "#{Rails.root}/spec/fixtures/stash_engine/table.csv"`
        expect(result).to eq("# -----
# valid: #{Rails.root}/spec/fixtures/stash_engine/table.csv
# -----\n")
      end
      it 'can return json report' do
        result = `frictionless validate "#{Rails.root}/spec/fixtures/stash_engine/table.csv" --json`
        expect(result).to include('"errors": []')
      end
    end
  end
end

