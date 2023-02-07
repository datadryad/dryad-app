require 'redcarpet'

# module
module MarkdownHandler

  MARKDOWN_OPTIONS = {
    autolink: true,
    underline: true,
    no_intra_emphasis: true,
    tables: true,
    highlight: true,
    footnotes: true,
    link_attributes: { rel: 'nofollow', target: '_blank' }.freeze
  }.freeze
  BODY_RENDERER = 'Redcarpet::Render::HTML.new(with_toc_data: true)'.freeze
  TOC_RENDERER = 'Redcarpet::Render::HTML_TOC.new(nesting_level: 2)'.freeze

  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template, source)
    @md_options ||= MARKDOWN_OPTIONS
    compiled_source = erb.call(template, source)
    renderer = template.locals.include?('toc') ? TOC_RENDERER : BODY_RENDERER
    "Redcarpet::Markdown.new(#{renderer}, #{@md_options} ). render(begin;#{compiled_source};end).html_safe"
  end
end
