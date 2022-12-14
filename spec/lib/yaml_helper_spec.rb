require 'rails_helper'
require 'yaml'
RSpec.describe YamlHelper do

  describe 'self.output_test_section'

  it 'makes sure parsed and re-outputted example matches original example' do
    # directly load the example file
    direct_to_file = YAML.load_file(File.join(Rails.root, 'dryad-config-example', 'app_config.yml'))

    # outputs the YAML and re-parses it
    yaml_text = YamlHelper.output_test_section(example_filename: 'app_config.yml')
    manipulated_yaml = YAML.safe_load(yaml_text, [Date])

    # see if the two match, they should
    expect(direct_to_file['test']['old_dryad_access_token']).to eq(manipulated_yaml['test']['old_dryad_access_token'])
  end

  it 'eliminates the --- at top of the yaml file since not appropriate for dropping in the middle' do
    yaml_text = YamlHelper.output_test_section(example_filename: 'app_config.yml')
    expect(yaml_text).not_to include('---')
  end

  it 'parses dynamic ERB stuff in original file as necessary' do
    ENV['SOLR_URL'] = 'my_test_catfood'
    # blacklight_yml has dynamic templating for this environment variable
    yaml_text = YamlHelper.output_test_section(example_filename: 'blacklight.yml')
    expect(yaml_text).to include('my_test_catfood')
    ENV['SOLR_URL'] = nil
  end
end
