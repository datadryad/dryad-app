module DatasetHelper

  include Mocks::Ezid

  def start_new_dataset
    mock_minting!
    click_button 'Start New Dataset'
    expect(page).to have_content('Describe Dataset')
    navigate_to_metadata
  end

  def navigate_to_metadata
    click_link 'Describe Dataset'

    expect(page).to have_content('Dataset: Basic Information', wait: 10)
  end

  def navigate_to_upload
    click_link 'Upload Files'
    expect(page).to have_content('Step 2: Choose Files', wait: 10)
  end

  def navigate_to_review
    click_link 'Review and Submit'
    expect(page).to have_content('Review Description', wait: 10)
  end

  # rubocop:disable Metrics/AbcSize
  def fill_required_fields
    # make sure we're on the right page
    navigate_to_metadata

    # ##############################
    # Title
    title = find_field_id('title')
    fill_in title, with: Faker::Lorem.sentence

    # ##############################
    # Author
    fill_in 'author[author_first_name]', with: Faker::Name.unique.first_name
    fill_in 'author[author_last_name]', with: Faker::Name.unique.last_name
    # TODO: make consistent with other author fields
    fill_in 'affiliation', with: Faker::Company.unique.name
    fill_in 'author[author_email]', with: Faker::Internet.safe_email

    # TODO: additional author(s)

    # ##############################
    # Abstract
    fill_in_ckeditor 'description_abstract', with: Faker::Lorem.paragraph
    wait_for_ajax

    navigate_to_review
    find('#agree_to_license').click
    find('#agree_to_payment').click
  end
  # rubocop:enable Metrics/AbcSize

end
