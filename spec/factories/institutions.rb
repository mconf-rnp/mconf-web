# Read about factories at https://github.com/thoughtbot/factory_girl

def name_to_acronym n
    n.to_s.scan(/\w+/).map{|w| w[0]}.join
end

FactoryGirl.define do
  sequence(:name) { |n| Forgery::Name.unique_full_name(n) }

  factory :institution do
    name
    acronym { name_to_acronym(name) }
  end
end
