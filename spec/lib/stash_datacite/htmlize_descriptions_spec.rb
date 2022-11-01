require 'rails_helper'
require_relative '../../../lib/script/htmlize_descriptions'

module Script
  describe HtmlizeDescriptions do
    describe :html_conversion do
      it 'detects html tags' do
        item = Script::HtmlizeDescriptions.new('my cat has fleas')
        expect(item.html?).to eq(false)

        item2 = Script::HtmlizeDescriptions.new('my cat has fleas & so do you')
        expect(item2.html?).to eq(false)

        item3 = Script::HtmlizeDescriptions.new('my <em>cat</em> has fleas & so do you')
        expect(item3.html?).to eq(true)
      end

      it 'converts text to autohtml' do
        item = Script::HtmlizeDescriptions.new('my cat & I have fleas')
        expect(item.text_as_html).to eq('<p>my cat &amp; I have fleas</p>')

        item2 = Script::HtmlizeDescriptions.new("My cat\nYour cat\n\nAll cats")
        expect(item2.text_as_html).to eq("<p>My cat\nYour cat</p><p>All cats</p>")

        item3 = Script::HtmlizeDescriptions.new('My simple site is http://catfood.com.')
        expect(item3.text_as_html).to eq('<p>My simple site is <a href="http://catfood.com" target="_blank" ' \
                                         'title="http://catfood.com">http://catfood.com</a>.</p>')

        item4 = Script::HtmlizeDescriptions.new('My simple site is http://catfood.com. She & I love it.')
        expect(item4.text_as_html).to eq('<p>My simple site is <a href="http://catfood.com" target="_blank" ' \
                                         'title="http://catfood.com">http://catfood.com</a>. She &amp; I love it.</p>')

        item5 = Script::HtmlizeDescriptions.new('A long url like https://googleblog.blogspot.com/2009/12/making-urls-shorter-for-google-toolbar.html')
        expect(item5.text_as_html).to eq('<p>A long url like <a href="https://googleblog.blogspot.com/2009/12/making-urls-' \
                                         'shorter-for-google-toolbar.html" target="_blank" title="https://googleblog.blogspot.com/2009/12/making-urls-shorter' \
                                         '-for-google-toolbar.html">https://googleblog.blogspot.com/2009/12/making-urls-short...</a></p>')

      end
    end
  end
end
