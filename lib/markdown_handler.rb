require 'redcarpet'

module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    compiled_source = erb.call(template)
    renderer = template.locals.include?('toc') ? 'Redcarpet::Render::HTML_TOC' : 'Redcarpet::Render::HTML.new(with_toc_data: true)'
    "Redcarpet::Markdown.new(#{renderer}, no_intra_emphasis: true, autolink: true).render(begin;#{compiled_source};end).html_safe"
  end
end
