
Upgrading Rails Versions
=========================

First ensure all tests are passing, and that there is adequate code coverage.

1. Edit the main Gemfile to set the new version:
   - Where it says "gem 'rails'"
   - Also edit the engine-level .gemspec files that reference the rails
     version, like stash/stash_api/stash_api.gemspec

`gem instal rails -v <NEW_VERSION_NUMBER>`
`bundle update rails`

2. Resolve any dependency issues by bumping up the versions of gems
   that are required. It's often best to bump up the minimal amount
   you can; you can always bump things up more once the initial rails
   version is running properly, but you don't want them to introduce
   dependencies on even-newer versions of rails.

3. `bundle install`
   - once bundle install runs without errors, commit the changes!
   - The app may start up now, but it's ok if it doesn't, since there are
     still configuration changes to be made.

4. `rails app:update`
   - DO NOT actually commit the results of running this command, because
     it doesn't know about any configuration choices we have made. Save the
     diff into a file, and then revert the changes, and manually go
     through the diff file to see what needs to be changed in your
     config files.

5. In `config/application.rb`, see the `config_defaults` variable.
   - To start, keep it on the old rails version
   - Then change each default setting in the "new_framework_defaults*"
     file
   - Once all of the settings are updated, flip the config_defaults
     to the new rails version
   - If you are keeping all defaults from the
     "new_framework_defaults*" file, you can simply delete this file.
   - For any default settings you want to override, move them into
     the application.rb file, below the config_defaults -- don't
     leave them in separate files, because Rails may load them in the
	 wrong order
   - After updating the config files, the app should at least start

5. Go through the notes for this specific Rails version in the
   [Rails Guides](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
   and update any specific features that have changed.

6. Run the test suite and keep making fixes until everything passes again.

