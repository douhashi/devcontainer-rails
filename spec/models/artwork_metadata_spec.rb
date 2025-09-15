require "rails_helper"

RSpec.describe ArtworkMetadata, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:content) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:positive_prompt) }
    it { is_expected.to validate_presence_of(:negative_prompt) }
  end

  describe "content association" do
    let(:content) { create(:content) }
    let(:artwork_metadata) { create(:artwork_metadata, content: content) }

    it "has correct content association" do
      expect(artwork_metadata.content).to eq(content)
    end

    it "is destroyed when content is destroyed" do
      artwork_metadata
      expect { content.destroy }.to change(ArtworkMetadata, :count).by(-1)
    end
  end

  describe "prompt management" do
    let(:artwork_metadata) { build(:artwork_metadata) }

    it "stores positive_prompt" do
      artwork_metadata.positive_prompt = "beautiful landscape, digital art, vibrant colors"
      expect(artwork_metadata.positive_prompt).to eq("beautiful landscape, digital art, vibrant colors")
    end

    it "stores negative_prompt" do
      artwork_metadata.negative_prompt = "blurry, low quality, distorted"
      expect(artwork_metadata.negative_prompt).to eq("blurry, low quality, distorted")
    end

    it "handles long prompts" do
      long_prompt = "a" * 5000
      artwork_metadata.positive_prompt = long_prompt
      artwork_metadata.negative_prompt = long_prompt
      expect(artwork_metadata).to be_valid
    end
  end

  describe "uniqueness" do
    let(:content) { create(:content) }

    it "allows only one artwork_metadata per content" do
      create(:artwork_metadata, content: content)
      duplicate = build(:artwork_metadata, content: content)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:content_id]).to include("has already been taken")
    end
  end
end
