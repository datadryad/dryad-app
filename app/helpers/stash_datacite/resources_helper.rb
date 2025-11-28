module StashDatacite
  module ResourcesHelper

    def author_display(authors, affs)
      # rubocop:disable Layout/LineLength
      authors.map do |author|
        next unless author.author_full_name

        if author.author_orcid.present?
          str = "<a class=\"o-metadata__author\" href=\"#{new_search_path(orcid: author.author_orcid)}\">#{author.author_full_name}</a>"
        end
        str ||= "<span class=\"o-metadata__author\">#{author.author_full_name}</span>"
        af = author.affiliations.map do |a|
          next unless a.smart_name.present? && ![',', '.'].include?(a.smart_name)

          "<a class=\"o-metadata__link\" aria-label=\"Affiliation #{affs.index { |x| x[0] == a.id } + 1}\" href=\"#aff#{a.id}\">#{affs.index { |x| x[0] == a.id } + 1}</a>"
        end.join
        str += af unless af.blank?
        if author.corresp && author.author_email.present?
          str += "<a href=\"mailto:#{author.author_email}\" class=\"o-metadata__link\" aria-label=\"Email #{author.author_standard_name}\" target=\"_blank\" title=\"#{author.author_email}\"><i class=\"fas fa-envelope\" aria-hidden=\"true\"></i></a>"
        end
        if author.author_orcid.present?
          str += "<a href=\"#{author_orcid_link(author)}\" class=\"o-metadata__link\" target=\"_blank\" aria-label=\"#{author.author_standard_name} ORCID profile (opens in new window)\" title=\"ORCID: #{author.author_orcid}\"><i class=\"fab fa-orcid\" aria-hidden=\"true\"></i></a>"
        end
        str
      end.reject(&:blank?).join('; ')
      # rubocop:enable Layout/LineLength
    end

    def affs_list(authors)
      authors.map(&:affiliations).flatten.uniq.each_with_object([]) do |a, arr|
        arr << [a.id, a.smart_name, a.ror_id] if a.smart_name.present? && a.smart_name != ',' && a.smart_name != '.'
        arr
      end
    end

  end
end
