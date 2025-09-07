# frozen_string_literal: true

require "rails_helper"

describe SampleButton::Component do
  let(:options) { { url: '#', text: 'Button' } }
  let(:component) { SampleButton::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end
end
