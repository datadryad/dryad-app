require 'fileutils'
require 'byebug'
require 'cgi'

module StashEngine
  describe GenericFile do

    # this is just to be sure that Single Table Inheritance is set up correctly
    describe 'works for subclasses' do
      before(:each) do
        @resource = create(:resource)
        @data_f = create(:data_file, resource_id: @resource.id)
        @soft_f = create(:software_file, resource_id: @resource.id)
        @supp_f = create(:supp_file, resource_id: @resource.id)
      end

      it 'gets all different types of files for generic files' do
        expect(@resource.generic_files.count).to eq(3)
      end

      it 'only returns one result for specific type of file' do
        expect(@resource.data_files.count).to eq(1)
      end
    end

  end
end
