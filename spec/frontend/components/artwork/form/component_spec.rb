# frozen_string_literal: true

require "rails_helper"

RSpec.describe Artwork::Form::Component, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(content_record: content) }

  context "削除ボタンのアイコン表示" do
    context "画像がアップロード済みの場合" do
      let(:content) { create(:content) }
      let(:artwork) { create(:artwork, content: content) }

      before do
        content.artwork = artwork
        allow(artwork).to receive_message_chain(:image, :present?).and_return(true)
        allow(artwork).to receive_message_chain(:image, :url).and_return("/test/image.jpg")
      end

      it "削除ボタンがアイコンとして表示される" do
        rendered = render_inline(component)

        # 削除ボタンのform要素を確認
        expect(rendered).to have_css("form[method='post']")

        # Icon::Componentが使用されていることを確認
        expect(rendered).to have_css("svg")
        expect(rendered).to have_css("svg[aria-label='削除']")

        # 「削除」テキストが表示されていないことを確認
        expect(rendered).not_to have_text("削除")
      end

      it "削除ボタンにtitle属性が設定される" do
        rendered = render_inline(component)

        expect(rendered).to have_css("button[title='削除']")
      end

      it "削除ボタンに適切なdata属性が設定される" do
        rendered = render_inline(component)

        expect(rendered).to have_css("button[data-turbo-method='delete']")
        expect(rendered).to have_css("button[data-controller='delete-confirmation']")
        expect(rendered).to have_css("button[data-action='click->delete-confirmation#confirm']")
        expect(rendered).to have_css("button[data-delete-confirmation-message-value='アートワークを削除しますか？']")
      end

      it "削除ボタンのスタイリングがアイコンボタン用になっている" do
        rendered = render_inline(component)

        # アイコンボタン用のパディングが設定されていることを確認
        expect(rendered).to have_css("button.p-2")
      end
    end

    context "画像がアップロードされていない場合" do
      let(:content) { create(:content) }

      it "削除ボタンが表示されない" do
        rendered = render_inline(component)

        expect(rendered).not_to have_css("button[data-turbo-method='delete']")
        expect(rendered).not_to have_text("削除")
      end
    end
  end
end
