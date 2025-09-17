module HelpHelper

  def requirements
    [
      { path: '/help/requirements/files', name: 'File requirements' },
      { path: '/help/requirements/metadata', name: 'Metadata requirements' },
      { path: '/help/requirements/costs', name: 'Costs' }
    ]
  end

  def guides
    [
      { path: '/help/guides/QuickstartGuideToDataSharing.pdf', name: 'Data sharing (quick start)' },
      { path: '/help/guides/best_practices', name: 'Good data practices' },
      { path: '/help/guides/reuse', name: 'How to reuse Dryad data' },
      { path: '/help/guides/EndangeredSpeciesData.pdf', name: 'Guidance for species data' },
      { path: '/help/guides/HumanSubjectsData.pdf', name: 'Sharing human subjects data' },
      { path: '/help/guides/data_check_alerts', name: 'Tabular data check alerts' }
    ]
  end

  def submission_steps
    [
      { path: '/help/submission_steps/submission', name: 'Submission walkthrough' },
      { path: '/help/submission_steps/curation', name: 'Dataset curation' },
      { path: '/help/submission_steps/publication', name: 'Published datasets' }
    ]
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
