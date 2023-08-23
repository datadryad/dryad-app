module TinymceHelper

  # tox tox-tinymce
  # tinyMCE.editors
  # var myEditor = tinyMCE.editors.filter(x => x.id === 'editor_abstract')[0];
  # myEditor.setContent('Meow meow meow');

  def fill_in_tinymce(field:, content:)
    # this is tricky since it's an iframe and has custom controls that exist in js on the page but don't load immediately
    field = "editor_#{field}"
    content.gsub!('"', '\"')
    # binding.remote_pry

    # https://github.com/tinymce/tinymce/issues/3782
    #
    # Also see this page in case it helps.  TinyMCE seems unreliable to load in any specific time especially with multiple
    # on the page.

    counter = 0

    until page.evaluate_script("typeof tinyMCE !== 'undefined'") || counter > 60
      sleep 0.5
      counter += 1
    end

    # page.evaluate_script("tinyMCE.get('#{field}') !== null")
    # page.evaluate_script("typeof tinyMCE.editors !== 'undefined'")

    until page.evaluate_script('tinymce.get().length > 1') || counter > 60
      sleep 0.5
      counter += 1
    end

    until page.evaluate_script("(typeof tinymce.get()[1].getContent() === 'string')") || counter > 60
      sleep 0.5
      counter += 1
    end
    sleep 0.5

    script_text = <<-SCRIPT
        var myEditor = tinymce.get().filter(x => x.id === '#{field}')[0];
        myEditor.setContent("#{content}");
        myEditor.focus();
    SCRIPT

    # TinyMCE is consistent in having problems loading or loading slowly in testing, especially with other React components
    begin
      retries = 0
      page.execute_script script_text
    rescue Selenium::WebDriver::Error::JavascriptError => e
      raise e unless e.message.include?('getRng')

      sleep 0.5
      retry if (retries += 1) < 20
    end
  end
end
