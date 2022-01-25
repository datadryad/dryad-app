module TinymceHelper

  # tox tox-tinymce
  # tinyMCE.editors
  # var myEditor = tinyMCE.editors.filter(x => x.id === 'editor_abstract')[0];
  # myEditor.setContent('Meow meow meow');

  def fill_in_tinymce(field:, content:)
    field = "editor_#{field}"
    content.gsub!('"', '\"')

    sleep 0.5 until page.evaluate_script("tinyMCE.get('#{field}') !== null")

    script_text = <<-SCRIPT
        var myEditor = tinyMCE.editors.filter(x => x.id === '#{field}')[0]
        myEditor.setContent("#{content}");
        myEditor.focus();
    SCRIPT
    page.execute_script script_text
  end
end