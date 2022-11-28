describe 'related_identifiers:fix_common_doi_problems', type: :task do

  before(:each) do
    @non_matching = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'I type random stuff as an identifier')
  end

  it "updates format for items like 'doi:10.1073/pnas.1322632112'" do
    matching_one = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'doi:10.1073/pnas.1322632112')
    Tasks::RelatedIdentifiers::Replacements.update_doi_prefix
    matching_one.reload
    @non_matching.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(@non_matching.fixed_id).to be_nil
  end

  it "updates a bare doi like '10.1073/pnas.1322632112'" do
    matching_one = create(:related_identifier, related_identifier_type: 'doi', related_identifier: '10.1073/pnas.1322632112')
    Tasks::RelatedIdentifiers::Replacements.update_bare_doi
    matching_one.reload
    @non_matching.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(@non_matching.fixed_id).to be_nil
  end

  it "copies across preferred format like 'https://doi.org/10.1073/pnas.1322632112'" do
    matching_one = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'https://doi.org/10.1073/pnas.1322632112')
    Tasks::RelatedIdentifiers::Replacements.move_good_format
    matching_one.reload
    @non_matching.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(@non_matching.fixed_id).to be_nil
  end

  it 'changes good http ones into preferred https protocol' do
    matching_one = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'http://doi.org/10.1073/pnas.1322632112')
    Tasks::RelatedIdentifiers::Replacements.update_http_good
    matching_one.reload
    @non_matching.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(@non_matching.fixed_id).to be_nil
  end

  it 'updates dx.doi.org ones' do
    matching_one = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'https://dx.doi.org/10.1073/pnas.1322632112')
    matching_two = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'http://dx.doi.org/10.1073/pnas.1322632112')
    Tasks::RelatedIdentifiers::Replacements.update_http_dx_doi
    matching_one.reload
    matching_two.reload
    @non_matching.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(matching_two.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(@non_matching.fixed_id).to be_nil
  end

  it 'updates protocol free ones' do
    matching_one = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'dx.doi.org/10.1073/pnas.1322632112')
    matching_two = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'doi.org/10.1073/pnas.1322632112')
    Tasks::RelatedIdentifiers::Replacements.update_protocol_free
    matching_one.reload
    matching_two.reload
    @non_matching.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(matching_two.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(@non_matching.fixed_id).to be_nil
  end

  it 'deals with people who insert non-printing or non-ascii characters into their DOIs' do
    badchar = [8203].pack('U*')
    matching_one = create(:related_identifier, related_identifier_type: 'doi', related_identifier: "doi:10.1016/​j.c#{badchar}ub.2018.08.012")
    matching_two = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'doi.org/10.1073/pna✅s.1322632112')
    Tasks::RelatedIdentifiers::Replacements.update_non_ascii
    matching_one.reload
    matching_two.reload
    @non_matching.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1016/j.cub.2018.08.012')
    expect(matching_two.fixed_id).to eq('https://doi.org/10.1073/pnas.1322632112')
    expect(@non_matching.fixed_id).to be_nil
  end

  it 'finds apparent dois in remaining, non-matched records' do
    matching_one = create(:related_identifier, related_identifier_type: 'doi',
                                               related_identifier: 'my cat likes to rrag=10.1016/j.cub.2018.08.012 and so do I')
    matching_two = create(:related_identifier, related_identifier_type: 'doi', related_identifier: 'https://journals.plos.org/plosone/article?id=10.1371/journal.pone.023256510')
    already_done = create(:related_identifier, related_identifier_type: 'doi', related_identifier: '10.2222/nog', fixed_id: 'https://doi.org/10.2222/nogggin')
    Tasks::RelatedIdentifiers::Replacements.remaining_strings_containing_dois
    matching_one.reload
    matching_two.reload
    @non_matching.reload
    already_done.reload
    expect(matching_one.fixed_id).to eq('https://doi.org/10.1016/j.cub.2018.08.012')
    expect(matching_two.fixed_id).to eq('https://doi.org/10.1371/journal.pone.023256510')
    expect(already_done.fixed_id).to eq('https://doi.org/10.2222/nogggin') # this one not updated again because already exists
    expect(@non_matching.fixed_id).to be_nil
  end

end
