class YoutubeMetadata < ApplicationRecord
  extend Enumerize

  self.table_name = "youtube_metadatas"

  belongs_to :content

  validates :title, presence: true, length: { maximum: 100 }
  validates :description_en, presence: true, length: { maximum: 5000 }
  validates :description_ja, presence: true, length: { maximum: 5000 }
  validates :hashtags, length: { maximum: 500 }

  enumerize :status, in: {
    draft: 0,
    ready: 1,
    published: 2
  }, default: :draft, predicates: { prefix: true }, scope: :shallow

  # ワークフロー制御メソッド
  def can_transition_to?(new_status)
    new_status = new_status.to_s
    current = status

    case current
    when "draft"
      %w[ready published].include?(new_status)
    when "ready"
      %w[published draft].include?(new_status)
    when "published"
      %w[draft].include?(new_status)  # 修正のために下書きに戻すことが可能
    else
      false
    end
  end

  def next_available_statuses
    YoutubeMetadata.status.values.select { |status| can_transition_to?(status) }
  end

  # ステータス変更の検証
  def transition_to!(new_status)
    unless can_transition_to?(new_status)
      from_label = self.class.human_attribute_name("status/#{status}")
      to_label = self.class.human_attribute_name("status/#{new_status}")
      errors.add(:status, I18n.t("youtube_metadata.errors.invalid_status_transition",
                                from: from_label, to: to_label))
      return false
    end

    update!(status: new_status)
  end
end
