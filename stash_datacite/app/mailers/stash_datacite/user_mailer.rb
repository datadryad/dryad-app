module StashDatacite

  class UserMailer < ApplicationMailer

    include CitationHelper

    def published(resource)
      return unless resource.current_curation_activity.published?
      user = resource.authors.first || resource.user
      return unless user.present? && user_email(user).present?
      @user_name = user_name(user)
      @citation = cite(resource)
      assign_variables(resource)
      mail(to: user_email(user), subject: "#{rails_env} Dryad Submission \"#{@resource.title}\"")
    end

  end

end
