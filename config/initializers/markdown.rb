module MarkdownHandler

  MARKDOWN_OPTIONS = {
    no_intra_emphasis: true,
    tables: true,
    fenced_code_blocks: true,
    autolink: false,
    disable_indented_code_blocks: true,
    strikethrough: true,
    space_after_headers: true,
    underline: false,
    highlight: false,
    footnotes: true
  }.freeze
  BODY_RENDERER = 'Redcarpet::Render::HTML.new(with_toc_data: true)'.freeze
  TOC_RENDERER = 'Redcarpet::Render::HTML_TOC.new(nesting_level: 1)'.freeze

  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template, source)
    @md_options ||= MARKDOWN_OPTIONS
    compiled_source = erb.call(template, source)
    compiled_source = compiled_source.gsub(/^## /, '# ') if template.locals.include?('toc') 
    renderer = template.locals.include?('toc') ? TOC_RENDERER : BODY_RENDERER
    "Redcarpet::Markdown.new(#{renderer}, #{@md_options} ).render(begin;#{compiled_source};end.to_s).html_safe"
  end
end

ActionView::Template.register_template_handler(:md, MarkdownHandler)
