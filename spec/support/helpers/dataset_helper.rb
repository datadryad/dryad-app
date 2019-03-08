module DatasetHelper

  include Mocks::Ezid

  def start_new_dataset
    sign_in
    mock_minting!
    click_button 'Start New Dataset'
    expect(page).to have_content('Describe Your Dataset')
  end

  def navigate_to_metadata
    click_link 'Describe Dataset'
    expect(page).to have_content('Describe Your Dataset')
  end

  def navigate_to_review
    click_link 'Review and Submit'
    wait_for_ajax
    expect(page).to have_content('Finalize Submission')
  end

  # rubocop:disable Metrics/AbcSize
  def fill_required_fields
    # make sure we're on the right page
    expect(page).to have_content('Describe Your Dataset')

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
  end
  # rubocop:enable Metrics/AbcSize

end
