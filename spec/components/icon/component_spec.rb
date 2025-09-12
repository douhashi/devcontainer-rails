# frozen_string_literal: true

require "rails_helper"

RSpec.describe Icon::Component, type: :component do
  describe "#initialize" do
    context "with valid icon name" do
      it "initializes with existing icons" do
        %i[image music video delete spinner play play_circle pause check].each do |icon_name|
          expect { described_class.new(name: icon_name) }.not_to raise_error
        end
      end

      it "initializes with new edit icon" do
        expect { described_class.new(name: :edit) }.not_to raise_error
      end

      it "initializes with new plus icon" do
        expect { described_class.new(name: :plus) }.not_to raise_error
      end

      it "initializes with new arrow_left icon" do
        expect { described_class.new(name: :arrow_left) }.not_to raise_error
      end
    end

    context "with invalid icon name" do
      it "raises ArgumentError" do
        expect { described_class.new(name: :invalid_icon) }.to raise_error(ArgumentError, /Unknown icon/)
      end
    end

    context "with valid size" do
      %i[sm md lg].each do |size|
        it "initializes with size #{size}" do
          expect { described_class.new(name: :image, size: size) }.not_to raise_error
        end
      end
    end

    context "with invalid size" do
      it "raises ArgumentError" do
        expect { described_class.new(name: :image, size: :xl) }.to raise_error(ArgumentError, /Invalid size/)
      end
    end
  end

  describe "rendering" do
    context "with edit icon" do
      it "renders with correct Font Awesome classes" do
        render_inline(described_class.new(name: :edit))
        expect(page).to have_css("i.fa-solid.fa-pen-to-square")
      end

      it "renders with aria-label when provided" do
        render_inline(described_class.new(name: :edit, aria_label: "Edit"))
        expect(page).to have_css("i[aria-label='Edit'][role='img']")
      end

      it "renders with aria-hidden when no aria-label" do
        render_inline(described_class.new(name: :edit))
        expect(page).to have_css("i[aria-hidden='true']")
      end
    end

    context "with plus icon" do
      it "renders with correct Font Awesome classes" do
        render_inline(described_class.new(name: :plus))
        expect(page).to have_css("i.fa-solid.fa-plus")
      end

      it "renders with aria-label when provided" do
        render_inline(described_class.new(name: :plus, aria_label: "Add"))
        expect(page).to have_css("i[aria-label='Add'][role='img']")
      end
    end

    context "with delete icon" do
      it "renders with correct Font Awesome classes" do
        render_inline(described_class.new(name: :delete))
        expect(page).to have_css("i.fa-solid.fa-trash")
      end
    end

    context "with size variations" do
      it "renders small size" do
        render_inline(described_class.new(name: :edit, size: :sm))
        expect(page).to have_css("i.fa-sm")
      end

      it "renders medium size without extra class" do
        render_inline(described_class.new(name: :edit, size: :md))
        expect(page).to have_css("i.fa-solid")
        expect(page).not_to have_css("i.fa-md")
      end

      it "renders large size" do
        render_inline(described_class.new(name: :edit, size: :lg))
        expect(page).to have_css("i.fa-lg")
      end
    end

    context "with color" do
      it "applies color class" do
        render_inline(described_class.new(name: :edit, color: "text-blue-500"))
        expect(page).to have_css("i.text-blue-500")
      end
    end

    context "with spinner icon" do
      it "adds spin animation" do
        render_inline(described_class.new(name: :spinner))
        expect(page).to have_css("i.fa-spin")
      end
    end

    context "with arrow_left icon" do
      it "renders with correct Font Awesome classes" do
        render_inline(described_class.new(name: :arrow_left))
        expect(page).to have_css("i.fa-solid.fa-arrow-left")
      end

      it "renders with aria-label when provided" do
        render_inline(described_class.new(name: :arrow_left, aria_label: "一覧に戻る"))
        expect(page).to have_css("i[aria-label='一覧に戻る'][role='img']")
      end

      it "renders with large size" do
        render_inline(described_class.new(name: :arrow_left, size: :lg))
        expect(page).to have_css("i.fa-solid.fa-arrow-left.fa-lg")
      end

      it "renders with color when provided" do
        render_inline(described_class.new(name: :arrow_left, color: "text-blue-400"))
        expect(page).to have_css("i.fa-solid.fa-arrow-left.text-blue-400")
      end
    end
  end
end
