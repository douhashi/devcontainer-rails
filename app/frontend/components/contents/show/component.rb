# frozen_string_literal: true

class Contents::Show::Component < ApplicationViewComponent
  attr_reader :item

  def initialize(item:)
    @item = item
  end

  private

  def formatted_date(date)
    return "" unless date
    date.strftime("%Y年%m月%d日 %H:%M")
  end

  def track_progress
    item.track_progress
  end

  def artwork_status
    item.artwork_status
  end

  def completion_status
    item.completion_status
  end

  def next_actions
    item.next_actions
  end

  def progress_variant
    case completion_status
    when :completed
      :success
    when :in_progress
      :primary
    when :needs_attention
      :danger
    else
      :primary
    end
  end

  def status_icon
    case completion_status
    when :completed
      "✓"
    when :in_progress
      "⚡"
    when :needs_attention
      "⚠"
    else
      "○"
    end
  end

  def completion_message
    case completion_status
    when :completed
      "すべての作業が完了しました！この楽曲は準備完了です。"
    when :in_progress
      "コンテンツを制作中です。進捗状況を確認してください。"
    when :needs_attention
      "注意が必要な問題があります。詳細を確認して対応してください。"
    else
      "コンテンツの制作を開始してください。"
    end
  end

  def track_status_items
    [
      { status: :pending, count: item.tracks.pending.count, label: "待機中", color: "text-yellow-400", icon: "⏳" },
      { status: :processing, count: item.tracks.processing.count, label: "生成中", color: "text-blue-400", icon: "⚙" },
      { status: :completed, count: item.tracks.completed.count, label: "完了", color: "text-green-400", icon: "✓" },
      { status: :failed, count: item.tracks.failed.count, label: "失敗", color: "text-red-400", icon: "✗" }
    ]
  end

  def artwork_preview_available?
    artwork_status == :configured && item.artwork&.image&.present?
  end
end
