module DatasetHelper

  def start_new_dataset
    click_button 'Start New Dataset'
    expect(page).to have_content('Describe Dataset')
    navigate_to_metadata
  end

  def navigate_to_metadata
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_link 'Describe Dataset'
    expect(page).to have_content('Dataset: Basic Information', wait: 10)
  end

  def navigate_to_software_upload
    click_link 'Upload Software'
    expect(page).to have_content('Choose Files')
  end

  def navigate_to_upload
    click_link 'Upload Data'
    expect(page).to have_content('Step 2: Choose Files', wait: 10)
  end

  def navigate_to_upload_urls
    click_link 'Upload files from public URLs'
    expect(page).to have_content('Step 2: Enter Files', wait: 10)
  end

  def navigate_to_software_upload_urls
    click_link 'Upload software files from public URLs'
    expect(page).to have_content('Step 2: Enter Files', wait: 10)
  end

  def navigate_to_review
    click_link 'Review and Submit'
    expect(page).to have_content('Review Description', wait: 10)
  end

  def fill_required_fields
    only_fill_required_fields

    # ##############################
    # LICENSE/PAYMENT AGREEMENTS
    agree_to_everything
  end

  def only_fill_required_fields
    # make sure we're on the right page
    navigate_to_metadata

    # ##############################
    # Title
    fill_in 'title', with: Faker::Lorem.sentence

    # ##############################
    # Author
    fill_in_author

    # TODO: additional author(s)

    # ##############################
    # Abstract
    abstract = find_blank_ckeditor_id('description_abstract')
    fill_in_ckeditor abstract, with: Faker::Lorem.paragraph
  end

  def submit_form
    navigate_to_review
    submit = find_button('submit_dataset', disabled: :all)
    submit.click
  end

  def fill_manuscript_info(name:, issn:, msid:)
    choose('choose_manuscript')
    page.execute_script("$('#internal_datum_publication').val('#{name}')")
    page.execute_script("$('#internal_datum_publication_issn').val('#{issn}')") # must do to fill hidden field for issn
    page.execute_script("$('#internal_datum_publication_name').val('#{name}')") # must do to fill hidden field for issn
    fill_in 'internal_datum[msid]', with: msid
  end

  def fill_crossref_info(name:, doi:)
    choose('choose_published')
    fill_in 'internal_datum[publication]', with: name
    fill_in 'internal_datum[doi]', with: doi
  end

  def fill_in_author
    fill_in 'author[author_first_name]', with: Faker::Name.unique.first_name
    fill_in 'author[author_last_name]', with: Faker::Name.unique.last_name
    fill_in 'author[author_email]', with: Faker::Internet.safe_email
    fill_in 'author[affiliation][long_name]', with: Faker::Educator.university
  end

  def fill_in_funder(name:, value:)
    funder_el = page.find('input.js-funders', match: :first)
    funder_el.fill_in(with: name)
    first('.ui-menu-item-wrapper', wait: 5).click
    award_el = page.find('input.js-award_number', match: :first)
    award_el.fill_in(with: value)
  end

  def agree_to_everything
    navigate_to_review
    find('#agree_to_license').click
    find('#agree_to_tos').click
    find('#agree_to_payment').click
  end

end
