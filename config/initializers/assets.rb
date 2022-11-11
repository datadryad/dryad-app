# Be sure to restart your server when you modify this file.

# Asset digests allow you to set far-future HTTP expiration dates on all assets,
# yet still be able to expire them through the digest params.
Rails.application.config.assets.digest = true

# Adds additional error checking when serving assets at runtime.
# Checks for improperly declared sprockets dependencies.
# Raises helpful error messages.
Rails.application.config.assets.raise_runtime_errors = true

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( geobl_application.js )
# Rails.application.config.assets.precompile += %w( geoblacklight.js )
