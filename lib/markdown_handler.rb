require 'redcarpet'

# module
module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    compiled_source = erb.call(template)
    renderer = if template.locals.include?('toc')
                 'Redcarpet::Render::HTML_TOC'
               else
                 'Redcarpet::Render::HTML.new(with_toc_data: true)'
               end
    "Redcarpet::Markdown.new(#{renderer}, no_intra_emphasis: true, autolink: true)."\
    "render(begin;#{compiled_source};end).html_safe"
  end
end
