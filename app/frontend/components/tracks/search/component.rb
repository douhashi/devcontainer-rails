# frozen_string_literal: true

class Tracks::Search::Component < ApplicationViewComponent
  def initialize(q:)
    @q = q
  end

  private

  attr_reader :q

  def status_options
    [
      [ "すべて", "" ],
      [ "保留中", "pending" ],
      [ "処理中", "processing" ],
      [ "完了", "completed" ],
      [ "失敗", "failed" ]
    ]
  end
end
