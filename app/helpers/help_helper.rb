module HelpHelper

  def account
    HELP_PAGES_ACCOUNT
  end

  def requirements
    HELP_PAGES_REQUIREMENTS
  end

  def guides
    HELP_PAGES_GUIDES
  end

  def submission_steps
    HELP_PAGES_STEPS
  end

  def create_menu(page_list)
    str = '<ul>'
    page_list.each do |page|
      str += "<li><a href=\"#{page[:path]}\""
      str += ' aria-current="page"' if request.path == page[:path]
      str += ">#{page[:name]}"
      str += '<span class="pdfIcon" role="img" aria-label=" (PDF)"/></a>' if page[:path].end_with?('.pdf')
      str += '</a>'
      str += render template: page[:path], locals: { toc: true } if request.path == page[:path]
      str += '</li>'
    end
    str += '</ul>'
  end

end
