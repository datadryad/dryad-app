module Mocks

  class Orcid

    class << self

      def omniauth_response(user)
        {
          uid: user&.orcid || Faker::Pid.orcid, #Faker::Number.number(8),
          credentials: {
            token: "#{Faker::Alphanumeric.alphanumeric(4)}.#{Faker::Alphanumeric.alphanumeric(26)}"
          },
          info: {
            email: user&.email || Faker::Internet.safe_email,
            name: user&.name || Faker::Name.name,
            test_domain: user&.tenant_id || 'localhost'
          },
          extra: {
            raw_info: {
              first_name: user&.first_name || Faker::Name.first_name,
              last_name: user&.last_name || Faker::Name.last_name
            }
          }
        }
      end

      def email_response(user)
        {
          email: [
            user&.email || Faker::Internet.safe_email
          ]
        }
      end

    end

  end

end