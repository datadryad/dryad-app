FactoryBot.define do

  factory :right, class: StashDatacite::Right do
    resource

    rights { 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication' }
    rights_uri { 'https://creativecommons.org/publicdomain/zero/1.0/' }
  end

end
