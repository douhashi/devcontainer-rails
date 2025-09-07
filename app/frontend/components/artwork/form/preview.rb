# frozen_string_literal: true

class Artwork::Form::Preview < ViewComponentContrib::Preview
  def default
    content = FactoryBot.build(:content)
    render Artwork::Form::Component.new(content_record: content)
  end

  def with_existing_artwork
    content = FactoryBot.build(:content)
    content.artwork = FactoryBot.build(:artwork, content: content)
    render Artwork::Form::Component.new(content_record: content)
  end
end
