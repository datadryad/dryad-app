module Mocks

  class Orcid

    class << self

      # Its a Hash Rubocop, get over yourself!
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def omniauth_response(user)
        {
          uid: user.present? && user.orcid.present? ? user.orcid : Faker::Pid.orcid,
          credentials: {
            token: "#{Faker::Alphanumeric.alphanumeric(4)}.#{Faker::Alphanumeric.alphanumeric(26)}"
          },
          info: {
            email: user.present? && user.email.present? ? user.email : Faker::Internet.safe_email,
            name: user.present? && user.first_name.present? ? user.name : Faker::Name.name,
            test_domain: user.present? ? user.tenant_id : 'localhost'
          },
          extra: {
            raw_info: {
              first_name: user.present? && user.first_name.present? ? user.first_name : Faker::Name.first_name,
              last_name: user.present? && user.last_name.present? ? user.last_name : Faker::Name.last_name
            }
          }
        }
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def email_response(user)
        {
          email: [
            user.present? ? user.email : Faker::Internet.safe_email
          ]
        }
      end

    end

  end

end
