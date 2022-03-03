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

    counter = 0

    until page.evaluate_script("typeof tinyMCE !== 'undefined'") || counter > 60
      sleep 0.5
      counter += 1
    end

    # page.evaluate_script("tinyMCE.get('#{field}') !== null")
    # page.evaluate_script("typeof tinyMCE.editors !== 'undefined'")

    until page.evaluate_script('tinyMCE.editors.length > 0') || counter > 60
      sleep 0.5
      counter += 1
    end

    until page.evaluate_script("(typeof tinyMCE.editors[0].getContent() === 'string')") || counter > 60
      sleep 0.5
      counter += 1
    end

    script_text = <<-SCRIPT
        var myEditor = tinyMCE.editors.filter(x => x.id === '#{field}')[0]
        myEditor.setContent("#{content}");
        myEditor.focus();
    SCRIPT
    page.execute_script script_text
  end
end
