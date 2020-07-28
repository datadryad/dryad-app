stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
require "#{stash_engine_path}/db/migrate/20170329190235_fix_in_progress_resources.rb"

describe FixInProgressResources do
  attr_reader :in_progress_resources

  before(:each) do
    @in_progress_resources = []
    ident_count = 3
    identifiers = Array.new(ident_count) { |i| StashEngine::Identifier.create(identifier: "10.123/#{i}") }
    identifiers.each do |ident|
      r1 = StashEngine::Resource.create(identifier_id: ident.id, tenant_id: 'dryad')
      r1.current_state = 'submitted'
      r1.save
      v1 = r1.stash_version
      expect(v1.version).to eq(1) # just to be sure
      expect(v1.merritt_version).to eq(1) # just to be sure

      r2 = r1.amoeba_dup
      r2.save
      expect(r2.current_state).to eq('in_progress') # just to be sure
      v2 = r2.stash_version
      v2.version = 1
      v2.merritt_version = 1
      v2.save

      in_progress_resources << v2
    end
    expect(in_progress_resources.size).to eq(ident_count) # just to be sure
  end

  it 'fixes all in-progress versions' do
    fix = FixInProgressResources.new
    fix.change
    in_progress_resources.each do |v|
      v.reload
      expect(v.version).to eq(2) # just to be sure
      expect(v.merritt_version).to eq(2) # just to be sure
    end
  end
end
