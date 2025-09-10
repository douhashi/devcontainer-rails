# frozen_string_literal: true

require "rails_helper"

RSpec.describe YoutubeConnectButton::Component, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:options) { { user: user } }
  let(:component) { YoutubeConnectButton::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "a"
  end

  context "when user has no youtube connection" do
    it "shows connect button" do
      render_inline(component)

      expect(rendered_content).to have_link(href: youtube_auth_authorize_path)
      expect(rendered_content).to have_text(I18n.t("youtube_connect_button.component.connect"))
    end
  end

  context "when user has youtube connection" do
    before do
      create(:youtube_credential, user: user)
    end

    it "shows disconnect button" do
      render_inline(component)

      expect(rendered_content).to have_link(href: youtube_auth_disconnect_path)
      expect(rendered_content).to have_text(I18n.t("youtube_connect_button.component.disconnect"))
    end
  end
end
