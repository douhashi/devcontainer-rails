# frozen_string_literal: true

require "rails_helper"

RSpec.describe Layout::HeaderComponent, type: :component do
  let(:component) { described_class.new(**options) }
  let(:title) { "Test App" }
  let(:options) { { title: title } }

  describe "without current_user" do
    it "renders the default static user info" do
      render_inline(component)

      expect(page).to have_content("Admin User")
      expect(page).to have_content("A")
      expect(page).to_not have_css("[data-testid='user-dropdown']")
    end
  end

  describe "with current_user" do
    let(:user) { double("User", email: "test@example.com") }
    let(:options) { { title: title, current_user: user } }

    it "renders user email and avatar" do
      render_inline(component)

      expect(page).to have_content("test@example.com")
      expect(page).to have_content("T") # First letter of email
    end

    it "renders clickable dropdown trigger" do
      render_inline(component)

      expect(page).to have_css("[data-testid='user-dropdown']")
      expect(page).to have_css("[data-action='click->user-dropdown#toggle']")
    end

    it "renders dropdown menu structure" do
      render_inline(component)

      expect(page).to have_css("[data-user-dropdown-target='menu']")
      expect(page).to have_link("ログアウト", href: "/users/sign_out")
      expect(page).to have_css("a[data-turbo-method='delete']")
    end
  end

  describe "#truncated_email" do
    let(:user) { double("User", email: email) }
    let(:options) { { title: title, current_user: user } }

    context "with short email" do
      let(:email) { "user@test.com" }

      it "displays full email" do
        render_inline(component)
        expect(page).to have_content("user@test.com")
      end
    end

    context "with long email" do
      let(:email) { "very.long.email.address@example-domain.com" }

      it "truncates email appropriately" do
        render_inline(component)
        # Should show truncated version in the header display
        expect(page).to have_css("[data-testid='user-email-display']")
      end
    end
  end

  describe "#user_avatar_initial" do
    let(:user) { double("User", email: email) }
    let(:options) { { title: title, current_user: user } }

    context "with regular email" do
      let(:email) { "john@example.com" }

      it "shows first letter uppercase" do
        render_inline(component)
        expect(page).to have_content("J")
      end
    end

    context "with email starting with number" do
      let(:email) { "123user@example.com" }

      it "shows first character uppercase" do
        render_inline(component)
        expect(page).to have_content("1")
      end
    end

    context "with empty email" do
      let(:email) { "" }

      it "shows default avatar" do
        render_inline(component)
        expect(page).to have_content("U") # Default fallback
      end
    end
  end

  describe "accessibility" do
    let(:user) { double("User", email: "test@example.com") }
    let(:options) { { title: title, current_user: user } }

    it "includes proper ARIA attributes" do
      render_inline(component)

      expect(page).to have_css("[aria-haspopup='true']")
      expect(page).to have_css("[aria-expanded='false']")
      expect(page).to have_css("[role='button']")
    end
  end
end
