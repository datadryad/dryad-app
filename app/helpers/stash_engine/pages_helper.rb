module StashEngine
  module PagesHelper
    def public_pages
      {
        'Dryad home': ROOT_URL,
        'Advanced search': advanced_search_url,
        'Who we are': about_url,
        'What we do': mission_url,
        'Partner with us': join_us_url,
        'Institutional partner fees': institutions_url,
        'Publishing partner fees': publishers_url,
        'Support us': support_us_url,
        'Dryad help center': help_url,
        'Dryad API': api_url,
        Journals: journals_url,
        Login: choose_login_url,
        'Code of conduct': code_of_conduct_url,
        Ethics: ethics_url,
        Privacy: privacy_url,
        Accessibility: accessibility_url,
        'End user Terms of Use': terms_url,
        'Partner Terms of Use': partner_terms_url,
        Definitions: definitions_url, '
        Publication policy': publication_policy_url,
        Enquiries: contact_url
      }
    end
  end
end
