require 'rails_helper'

module StashEngine
  RSpec.describe GenericFilesController, type: :request do
    describe 'frictionless integration test' do
      it 'can call external process for csv files' do
        result = `frictionless validate "#{Rails.root}/spec/fixtures/stash_engine/valid.csv"`
        expect(result).to eq("# -----
# valid: #{Rails.root}/spec/fixtures/stash_engine/valid.csv
# -----\n")
      end

      it 'can call external process for xls files' do
        result = `frictionless validate "#{Rails.root}/spec/fixtures/stash_engine/valid.xls"`
        expect(result).to eq("# -----
# valid: #{Rails.root}/spec/fixtures/stash_engine/valid.xls
# -----\n")
      end

      it 'can call external process for xlsx files' do
        result = `frictionless validate "#{Rails.root}/spec/fixtures/stash_engine/valid.xlsx"`
        expect(result).to eq("# -----
# valid: #{Rails.root}/spec/fixtures/stash_engine/valid.xlsx
# -----\n")
      end

      it 'returns json report' do
        result = `frictionless validate "#{Rails.root}/spec/fixtures/stash_engine/valid.csv" --json`
        expect(result).to include('"errors": []')
      end
    end
  end
end
