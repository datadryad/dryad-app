# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :active_record_store,
                                       key: '_dash2_session',
                                       same_site: :lax, # <-- lax because of OAuth redirects
                                       httponly: true,
                                       secure: !Rails.env.development? && !Rails.env.test?
