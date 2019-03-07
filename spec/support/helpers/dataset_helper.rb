module DatasetHelper

  include WaitForAjax
  include Mocks::Ezid

  def start_new_dataset
    sign_in
    mock_minting!
    first(:link_or_button, 'Start New Dataset').click
    wait_for_ajax
    expect(page).to have_content('Describe Your Dataset')
  end

  def navigate_to_metadata
    first(:link_or_button, 'Describe Dataset').click
    expect(page).to have_content('Describe Your Dataset')
  end

  def navigate_to_review
    first(:link_or_button, 'Review and Submit').click
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

    author_first_name = find_field_id('author[author_first_name]')
    fill_in author_first_name, with: Faker::Name.unique.first_name
    author_last_name = find_field_id('author[author_last_name]')
    fill_in author_last_name, with: Faker::Name.unique.last_name
    # TODO: make consistent with other author fields
    author_affiliation = find_field_id('affiliation')
    fill_in author_affiliation, with: Faker::Company.unique.name
    author_email = find_field_id('author[author_email]')
    fill_in author_email, with: Faker::Internet.safe_email

    # TODO: additional author(s)

    # ##############################
    # Abstract

    abstract = find_blank_ckeditor_id('description_abstract')
    fill_in_ckeditor abstract, with: Faker::Lorem.paragraph
    wait_for_ajax
  end
  # rubocop:enable Metrics/AbcSize

end
