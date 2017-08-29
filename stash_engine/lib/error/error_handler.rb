# see https://medium.com/rails-ember-beyond/error-handling-in-rails-the-modular-way-9afcddd2fe1b for background
module Error
  module ErrorHandler
    def self.included(clazz)
      clazz.class_eval do
        rescue_from ActionController::InvalidCrossOriginRequest, with: :page_not_found
      end
    end

    private

    def page_not_found(_e)
      # render(nothing: true, status: 404)
      # throw :halt
    end
  end
end
