# frozen_string_literal: true

require "rails_helper"

RSpec.describe SampleButton::Component, type: :component do
  let(:options) { { url: '#', text: 'Button' } }
  let(:component) { described_class.new(**options) }

  it "renders" do
    render_inline(component)

    expect(page).to have_css "a"
    expect(page).to have_css "div.p-1.bg-blue-700.text-white"
    expect(page).to have_content "Button"
  end
end
