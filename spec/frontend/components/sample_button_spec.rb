# frozen_string_literal: true

require "rails_helper"

RSpec.describe SampleButton::Component, type: :component do
  let(:options) { { url: '#', text: 'Button' } }
  let(:component) { described_class.new(**options) }

  it "renders using new ButtonComponent" do
    render_inline(component)

    expect(page).to have_css "a[href='#']"
    expect(page).to have_css "a.bg-blue-600" # Primary variant
    expect(page).to have_css "a.text-white"
    expect(page).to have_content "Button"
  end

  it "maintains backward compatibility" do
    render_inline(component)

    # Should still render as a link with button styling
    expect(page).to have_css "a"
    expect(page).to have_content "Button"
  end
end
