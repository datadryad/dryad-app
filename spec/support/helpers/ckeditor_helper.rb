module CkeditorHelper

  # CKEditor is made up of two parts.  A hidden textarea that will contain the value of the input after changes are made
  # and an iFrame where the actual editing takes place (in addition to controls and other things)

  def find_ckeditor_id(id)
    find("##{id}", visible: false)
  end

  def find_blank_ckeditor_id(id)
    field = find_ckeditor_id(id)
    expect(field.value).to be_blank
    field[:id]
  end

  # fill in the ckeditor
  # rubocop:disable Metrics/MethodLength
  def fill_in_ckeditor(locator, opts = {})
    id = find_ckeditor_id(locator)
    id = id[:id] if id

    # Fill the editor content
    content = opts.fetch(:with).to_json
    script_text = <<-SCRIPT
        var ckeditor = CKEDITOR.instances.#{id};
        ckeditor.setData(#{content});
        ckeditor.focusManager.focus();
        ckeditor.focusManager.blur( true );
        // ckeditor.updateElement();
    SCRIPT
    # the blur() above is needed because capybara behaves oddly. https://makandracards.com/makandra/12661-how-to-solve-selenium-focus-issues
    page.execute_script script_text
    expect(first('.cke', wait: 5).present?).to eql(true)
    # wait_for_ajax
  end
  # rubocop:enable Metrics/MethodLength

end
