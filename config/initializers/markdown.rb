require 'markdown_handler'

ActionView::Template.register_template_handler(:md, MarkdownHandler)
