FactoryBot.define do
  factory :content do
    theme { 'レコード、古いスピーカー、ランプの明かり' }

    trait :cafe_theme do
      theme { 'コーヒーアロマ、木製テーブル、窓際の観葉植物' }
    end

    trait :nature_theme do
      theme { '森の音、鳥のさえずり、朝露のきらめき' }
    end

    trait :urban_theme do
      theme { 'City lights, rain on windows, midnight traffic sounds' }
    end

    trait :minimal_theme do
      theme { 'シンプル' }
    end

    trait :long_theme do
      theme { 'a' * 256 }
    end
  end
end
