require 'yaml'
module YamlHelper
  def self.output_test_section(example_filename:)
    my_file = Rails.root.join('dryad-config-example', example_filename)
    # rubocop:disable Security/YAMLLoad
    # byebug
    my_yml = YAML.load(ERB.new(File.read(my_file)).result)
    # rubocop:enable Security/YAMLLoad
    # my_yml = YAML.load_file(my_file)
    new_yml = { 'test' => my_yml['test'] }.to_yaml
    new_yml.split("\n")[1..-1].join("\n") # this gets rid of the --- in the top line which we don't want when emitting
  end
end
