# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tracks::Search::Component, type: :component do
  let(:q) { Track.ransack }
  let(:options) { { q: q } }
  let(:component) { Tracks::Search::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "form"
    is_expected.to have_field "q[content_theme_cont]"
    is_expected.to have_field "q[music_title_cont]"
    is_expected.to have_select "q[status_eq]"
    is_expected.to have_field "q[created_at_gteq]"
    is_expected.to have_field "q[created_at_lteq]"
    is_expected.to have_link "リセット"
  end
end
