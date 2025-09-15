# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentSection::Component, type: :component do
  let(:component) { described_class.new(title: "テストセクション") }

  describe "basic rendering" do
    it "renders content section with default classes" do
      render_inline(component) do
        "テストコンテンツ"
      end

      expect(page).to have_css('div.bg-gray-800.rounded-lg.mb-6.p-6')
      expect(page).to have_text("テストセクション")
      expect(page).to have_text("テストコンテンツ")
    end

    it "renders header with title" do
      render_inline(component) do
        "テストコンテンツ"
      end

      expect(page).to have_css('h2.text-xl.font-bold.text-gray-200.flex-grow', text: "テストセクション")
    end

    it "renders content in body section" do
      render_inline(component) do
        "テストコンテンツ"
      end

      expect(page).to have_css('div.content-section-body', text: "テストコンテンツ")
    end
  end

  describe "title option" do
    context "when title is provided" do
      let(:component) { described_class.new(title: "カスタムタイトル") }

      it "displays the title" do
        render_inline(component)

        expect(page).to have_text("カスタムタイトル")
        expect(page).to have_css('h2', text: "カスタムタイトル")
      end
    end

    context "when title is not provided" do
      let(:component) { described_class.new }

      it "does not render header section" do
        render_inline(component)

        expect(page).not_to have_css('.content-section-header')
        expect(page).not_to have_css('h2')
      end
    end
  end

  describe "variant option" do
    context "with default variant" do
      let(:component) { described_class.new(title: "テスト", variant: :default) }

      it "applies default background class" do
        render_inline(component)

        expect(page).to have_css('div.bg-gray-800')
        expect(page).not_to have_css('div.border')
        expect(page).not_to have_css('div.shadow-lg')
      end
    end

    context "with bordered variant" do
      let(:component) { described_class.new(title: "テスト", variant: :bordered) }

      it "applies border classes" do
        render_inline(component)

        expect(page).to have_css('div.bg-gray-800.border.border-gray-600')
      end
    end

    context "with elevated variant" do
      let(:component) { described_class.new(title: "テスト", variant: :elevated) }

      it "applies shadow classes" do
        render_inline(component)

        expect(page).to have_css('div.bg-gray-800.shadow-lg.shadow-gray-900\\/30')
      end
    end

    context "with invalid variant" do
      let(:component) { described_class.new(title: "テスト", variant: :invalid) }

      it "falls back to default variant" do
        render_inline(component)

        expect(page).to have_css('div.bg-gray-800')
        expect(page).not_to have_css('div.border')
        expect(page).not_to have_css('div.shadow-lg')
      end
    end
  end

  describe "padding option" do
    context "with small padding" do
      let(:component) { described_class.new(title: "テスト", padding: :sm) }

      it "applies small padding class" do
        render_inline(component)

        expect(page).to have_css('div.p-4')
      end
    end

    context "with medium padding (default)" do
      let(:component) { described_class.new(title: "テスト", padding: :md) }

      it "applies medium padding class" do
        render_inline(component)

        expect(page).to have_css('div.p-6')
      end
    end

    context "with large padding" do
      let(:component) { described_class.new(title: "テスト", padding: :lg) }

      it "applies large padding class" do
        render_inline(component)

        expect(page).to have_css('div.p-8')
      end
    end

    context "with invalid padding" do
      let(:component) { described_class.new(title: "テスト", padding: :invalid) }

      it "falls back to default padding" do
        render_inline(component)

        expect(page).to have_css('div.p-6')
      end
    end
  end

  describe "custom class option" do
    let(:component) { described_class.new(title: "テスト", class: "custom-class another-class") }

    it "applies custom classes" do
      render_inline(component)

      expect(page).to have_css('div.custom-class.another-class')
    end
  end

  describe "slot functionality" do
    context "with header slot" do
      let(:component) { described_class.new }

      it "renders custom header" do
        render_inline(component) do |section|
          section.with_header do
            '<h1 class="text-2xl font-bold">カスタムヘッダー</h1>'.html_safe
          end
          "コンテンツ"
        end

        expect(page).to have_css('h1.text-2xl.font-bold', text: "カスタムヘッダー")
        expect(page).not_to have_css('h2') # Default title should not render
      end
    end

    context "with badge slot" do
      let(:component) { described_class.new(title: "テスト") }

      it "renders badge in header" do
        render_inline(component) do |section|
          section.with_badge do
            '<span class="bg-green-100 text-green-800 px-2 py-1 rounded">完了</span>'.html_safe
          end
          "コンテンツ"
        end

        expect(page).to have_css('span.bg-green-100.text-green-800', text: "完了")
        expect(page).to have_css('.content-section-header .flex-shrink-0')
      end
    end

    context "with actions slot" do
      let(:component) { described_class.new(title: "テスト") }

      it "renders single action" do
        render_inline(component) do |section|
          section.with_action do
            '<button class="bg-blue-600 text-white px-4 py-2 rounded">編集</button>'.html_safe
          end
          "コンテンツ"
        end

        expect(page).to have_css('button.bg-blue-600.text-white', text: "編集")
        expect(page).to have_css('.content-section-actions.flex.justify-end.gap-4')
      end

      it "renders multiple actions" do
        render_inline(component) do |section|
          section.with_action do
            '<button class="bg-blue-600 text-white px-4 py-2 rounded">編集</button>'.html_safe
          end
          section.with_action do
            '<button class="bg-red-600 text-white px-4 py-2 rounded">削除</button>'.html_safe
          end
          "コンテンツ"
        end

        expect(page).to have_css('button.bg-blue-600.text-white', text: "編集")
        expect(page).to have_css('button.bg-red-600.text-white', text: "削除")
      end
    end

    context "without slots" do
      let(:component) { described_class.new }

      it "renders only content without header or actions" do
        render_inline(component) do
          "シンプルコンテンツ"
        end

        expect(page).not_to have_css('.content-section-header')
        expect(page).not_to have_css('.content-section-actions')
        expect(page).to have_css('.content-section-body', text: "シンプルコンテンツ")
      end
    end
  end

  describe "complex scenarios" do
    context "with all features combined" do
      let(:component) { described_class.new(variant: :elevated, padding: :lg, class: "custom") }

      it "renders all features correctly" do
        render_inline(component) do |section|
          section.with_header do
            '<h1 class="text-3xl font-bold">フルフィーチャー</h1>'.html_safe
          end
          section.with_badge do
            '<span class="bg-yellow-100 text-yellow-800 px-2 py-1 rounded">進行中</span>'.html_safe
          end
          section.with_action do
            '<button class="bg-green-600 text-white px-4 py-2 rounded">保存</button>'.html_safe
          end
          section.with_action do
            '<button class="bg-gray-600 text-white px-4 py-2 rounded">キャンセル</button>'.html_safe
          end
          '<div class="text-gray-200">フルフィーチャーコンテンツ</div>'.html_safe
        end

        # Variant and padding classes
        expect(page).to have_css('div.bg-gray-800.shadow-lg.shadow-gray-900\\/30.p-8.custom')

        # Header with badge
        expect(page).to have_css('h1.text-3xl.font-bold', text: "フルフィーチャー")
        expect(page).to have_css('span.bg-yellow-100.text-yellow-800', text: "進行中")

        # Content
        expect(page).to have_css('div.text-gray-200', text: "フルフィーチャーコンテンツ")

        # Actions
        expect(page).to have_css('button.bg-green-600.text-white', text: "保存")
        expect(page).to have_css('button.bg-gray-600.text-white', text: "キャンセル")
      end
    end
  end

  describe "accessibility and structure" do
    let(:component) { described_class.new(title: "アクセシビリティテスト") }

    it "maintains proper semantic structure" do
      render_inline(component) do |section|
        section.with_badge do
          '<span class="bg-blue-100">ステータス</span>'.html_safe
        end
        section.with_action do
          '<button>アクション</button>'.html_safe
        end
        "メインコンテンツ"
      end

      # Check structural elements exist
      expect(page).to have_css('.content-section-header')
      expect(page).to have_css('.content-section-body')
      expect(page).to have_css('.content-section-actions')
    end

    it "maintains proper heading hierarchy" do
      render_inline(component)

      expect(page).to have_css('h2', text: "アクセシビリティテスト")
    end
  end
end
