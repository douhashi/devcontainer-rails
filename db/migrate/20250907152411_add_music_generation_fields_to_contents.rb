class AddMusicGenerationFieldsToContents < ActiveRecord::Migration[8.0]
  def up
    add_column :contents, :duration, :integer, null: false, default: 3
    add_column :contents, :audio_prompt, :text

    # 既存のレコードのaudio_promptをthemeの値で更新
    Content.reset_column_information
    Content.find_each do |content|
      content.update_column(:audio_prompt, content.theme)
    end

    # audio_promptにNOT NULL制約を追加
    change_column_null :contents, :audio_prompt, false
  end

  def down
    remove_column :contents, :duration
    remove_column :contents, :audio_prompt
  end
end
