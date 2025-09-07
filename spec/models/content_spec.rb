require 'rails_helper'

RSpec.describe Content, type: :model do
  describe 'validations' do
    it 'validates presence of theme' do
      content = Content.new(theme: nil)
      expect(content).not_to be_valid
      expect(content.errors[:theme]).to include("can't be blank")
    end

    it 'validates length of theme is at most 256 characters' do
      content = Content.new(theme: 'a' * 257)
      expect(content).not_to be_valid
      expect(content.errors[:theme]).to include('is too long (maximum is 256 characters)')
    end
  end

  describe 'theme attribute' do
    let(:content) { build(:content) }

    context 'with valid theme' do
      it 'is valid with a theme' do
        content.theme = 'レコード、古いスピーカー、ランプの明かり'
        expect(content).to be_valid
      end

      it 'is valid with 256 characters' do
        content.theme = 'a' * 256
        expect(content).to be_valid
      end
    end

    context 'with invalid theme' do
      it 'is invalid without a theme' do
        content.theme = nil
        expect(content).not_to be_valid
        expect(content.errors[:theme]).to include("can't be blank")
      end

      it 'is invalid with empty theme' do
        content.theme = ''
        expect(content).not_to be_valid
        expect(content.errors[:theme]).to include("can't be blank")
      end

      it 'is invalid with more than 256 characters' do
        content.theme = 'a' * 257
        expect(content).not_to be_valid
        expect(content.errors[:theme]).to include('is too long (maximum is 256 characters)')
      end
    end
  end
end
