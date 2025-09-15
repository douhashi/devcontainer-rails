# frozen_string_literal: true

module ContentSection
  class Preview < ApplicationViewComponentPreview
    # @label 基本的なContentSection
    def basic
      render ContentSection::Component.new(title: "基本セクション") do
        tag.p("基本的なコンテンツです。", class: "text-gray-200")
      end
    end

    # @label バッジ付きContentSection
    def with_badge
      render ContentSection::Component.new(title: "ステータス付きセクション") do |section|
        section.with_badge do
          tag.span("完了", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800")
        end

        tag.p("バッジが表示されているコンテンツです。", class: "text-gray-200")
      end
    end

    # @label アクション付きContentSection
    def with_actions
      render ContentSection::Component.new(title: "アクション付きセクション") do |section|
        section.with_action do
          tag.button("編集", class: "bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700")
        end

        section.with_action do
          tag.button("削除", class: "bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700")
        end

        tag.p("アクションボタンが表示されているコンテンツです。", class: "text-gray-200")
      end
    end

    # @label フル機能ContentSection
    def full_featured
      render ContentSection::Component.new do |section|
        section.with_header do
          tag.h2("カスタムヘッダー", class: "text-2xl font-bold text-gray-100")
        end

        section.with_badge do
          tag.span("進行中", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800")
        end

        section.with_action do
          tag.button("保存", class: "bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700")
        end

        section.with_action do
          tag.button("キャンセル", class: "bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700")
        end

        tag.div(class: "space-y-4") do
          tag.p("フル機能を使用したコンテンツです。", class: "text-gray-200") +
          tag.p("複数の段落も含まれています。", class: "text-gray-300")
        end
      end
    end

    # @label 異なるバリエーション
    def variants
      render ContentSection::Component.new(title: "bordered variant", variant: :bordered) do
        tag.p("bordered variantのコンテンツです。", class: "text-gray-200")
      end
    end

    # @label 異なるパディング
    def paddings
      render ContentSection::Component.new(title: "large padding", padding: :lg) do
        tag.p("大きなパディングのコンテンツです。", class: "text-gray-200")
      end
    end
  end
end
