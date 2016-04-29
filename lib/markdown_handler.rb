require 'redcarpet'

module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    compiled_source = erb.call(template)

    is_toc = template.locals.include?('toc')
    renderer = is_toc ? "Redcarpet::Render::HTML_TOC" : "Redcarpet::Render::HTML.new(with_toc_data: true)"

    "Redcarpet::Markdown.new(#{renderer}, no_intra_emphasis: true, autolink: true).render(begin;#{compiled_source};end).html_safe"

    # "Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_intra_emphasis: true, autolink: true).render(begin;#{compiled_source};end).html_safe"
    #

    # <<-RUBY
    # is_toc = template.locals.include?('toc')
    # renderer = is_toc ? RedCarpet::Render::HTML_TOC : RedCarpet::Render::HTML(with_toc_data: true)
    # Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, autolink: true)
    #   .render(begin;#{compiled_source};end).html_safe
    # RUBY
  end
end
