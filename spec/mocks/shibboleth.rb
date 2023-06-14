module Mocks

  class Shibboleth

    def self.omniauth_response(user)
      {
        uid: user.present? && user.email.present? ? user.email : Faker::Internet.email,
        credentials: {
          token: "#{Faker::Alphanumeric.alphanumeric(number: 4)}.#{Faker::Alphanumeric.alphanumeric(number: 26)}"
        },
        info: {
          email: user.present? && user.email.present? ? user.email : Faker::Internet.email,
          identity_provider: 'localhost'
        }
      }
    end

  end

end
