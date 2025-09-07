# frozen_string_literal: true

require "rails_helper"

RSpec.describe Content::Form::Component, type: :component do
  include ViewComponent::TestHelpers
  include ViewComponent::SystemTestHelpers
  let(:content) { build(:content) }
  let(:form) { double("form", label: "", text_field: "") }
  let(:options) { { item: content, form: form } }
  let(:component) { Content::Form::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end
end
