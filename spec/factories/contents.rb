FactoryBot.define do
  factory :content do
    theme { 'レコード、古いスピーカー、ランプの明かり' }
    duration_min { 5 }
    audio_prompt { 'リラックスできる穏やかなローファイ音楽、ビンテージな雰囲気' }

    trait :cafe_theme do
      theme { 'コーヒーアロマ、木製テーブル、窓際の観葉植物' }
      audio_prompt { 'カフェの雰囲気を感じさせる落ち着いたBGM、コーヒーを飲みながら作業に集中できる音楽' }
    end

    trait :nature_theme do
      theme { '森の音、鳥のさえずり、朝露のきらめき' }
      audio_prompt { '自然を感じる穏やかなアンビエントミュージック、鳥のさえずりと風の音' }
    end

    trait :urban_theme do
      theme { 'City lights, rain on windows, midnight traffic sounds' }
      audio_prompt { 'Urban lo-fi beats with city ambiance, rain sounds, and late-night vibes' }
    end

    trait :minimal_theme do
      theme { 'シンプル' }
      audio_prompt { 'ミニマルで集中力を高めるBGM' }
    end

    trait :long_theme do
      theme { 'a' * 256 }
      audio_prompt { 'a' * 1000 }
    end

    trait :short_duration do
      duration_min { 1 }
    end

    trait :medium_duration do
      duration_min { 10 }
    end

    trait :long_duration do
      duration_min { 30 }
    end

    trait :max_duration do
      duration_min { 60 }
    end
  end
end
