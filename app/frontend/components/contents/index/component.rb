# frozen_string_literal: true

class Contents::Index::Component < ApplicationViewComponent
  attr_reader :contents, :filter_status

  def initialize(contents:, filter_status: nil)
    @contents = contents
    @filter_status = filter_status
  end

  private

  def empty_state?
    contents.empty?
  end

  def paginated?
    contents.respond_to?(:current_page)
  end

  def status_counts
    return {} if empty_state?

    @status_counts ||= begin
      counts = Hash.new(0)
      contents.each do |content|
        counts[content.completion_status] += 1
      end
      counts
    end
  end

  def total_count
    contents.size
  end

  def status_summary_text
    return "0件のコンテンツ" if total_count == 0

    parts = [ "#{total_count}件のコンテンツ" ]

    if filter_status && filter_status != "all"
      status_text = case filter_status
      when "completed" then "完了"
      when "in_progress" then "制作中"
      when "needs_attention" then "要対応"
      when "not_started" then "未着手"
      else filter_status.humanize
      end
      parts << "(#{status_text}でフィルタ中)"
    else
      status_parts = []
      status_counts.each do |status, count|
        status_text = case status
        when :completed then "完了"
        when :in_progress then "制作中"
        when :needs_attention then "要対応"
        when :not_started then "未着手"
        else status.to_s.humanize
        end
        status_parts << "#{status_text}: #{count}件"
      end
      parts << status_parts.join(", ") if status_parts.any?
    end

    parts.join(" ")
  end
end
