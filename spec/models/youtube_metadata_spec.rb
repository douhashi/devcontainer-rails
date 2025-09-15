require 'rails_helper'

RSpec.describe YoutubeMetadata, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:content) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description_en) }
    it { is_expected.to validate_presence_of(:description_ja) }

    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_length_of(:description_en).is_at_most(5000) }
    it { is_expected.to validate_length_of(:description_ja).is_at_most(5000) }
    it { is_expected.to validate_length_of(:hashtags).is_at_most(500) }
  end

  describe 'enumerize' do
    it 'enumerizes status with correct values' do
      expect(YoutubeMetadata.status.values).to eq([ 'draft', 'ready', 'published' ])
    end

    it 'has correct default status' do
      youtube_metadata = YoutubeMetadata.new
      expect(youtube_metadata.status).to eq('draft')
    end
  end

  describe 'factory' do
    it 'creates a valid youtube_metadata' do
      youtube_metadata = build(:youtube_metadata)
      expect(youtube_metadata).to be_valid
    end
  end

  describe 'methods' do
    let(:content) { create(:content) }
    let(:youtube_metadata) { create(:youtube_metadata, content: content) }

    describe '#status_draft?' do
      it 'returns true when status is draft' do
        youtube_metadata.status = 'draft'
        expect(youtube_metadata).to be_status_draft
      end
    end

    describe '#status_ready?' do
      it 'returns true when status is ready' do
        youtube_metadata.status = 'ready'
        expect(youtube_metadata).to be_status_ready
      end
    end

    describe '#status_published?' do
      it 'returns true when status is published' do
        youtube_metadata.status = 'published'
        expect(youtube_metadata).to be_status_published
      end
    end

    describe 'workflow control' do
      describe '#can_transition_to?' do
        context 'from draft status' do
          before { youtube_metadata.status = 'draft' }

          it 'allows transition to ready and published' do
            expect(youtube_metadata.can_transition_to?('ready')).to be true
            expect(youtube_metadata.can_transition_to?('published')).to be true
          end

          it 'does not allow staying in draft' do
            expect(youtube_metadata.can_transition_to?('draft')).to be false
          end
        end

        context 'from ready status' do
          before { youtube_metadata.status = 'ready' }

          it 'allows transition to published and draft' do
            expect(youtube_metadata.can_transition_to?('published')).to be true
            expect(youtube_metadata.can_transition_to?('draft')).to be true
          end

          it 'does not allow staying in ready' do
            expect(youtube_metadata.can_transition_to?('ready')).to be false
          end
        end

        context 'from published status' do
          before { youtube_metadata.status = 'published' }

          it 'allows transition back to draft for modifications' do
            expect(youtube_metadata.can_transition_to?('draft')).to be true
          end

          it 'does not allow transition to ready or staying published' do
            expect(youtube_metadata.can_transition_to?('ready')).to be false
            expect(youtube_metadata.can_transition_to?('published')).to be false
          end
        end
      end

      describe '#next_available_statuses' do
        it 'returns only allowed transitions from draft' do
          youtube_metadata.status = 'draft'
          expect(youtube_metadata.next_available_statuses).to match_array([ 'ready', 'published' ])
        end

        it 'returns only allowed transitions from ready' do
          youtube_metadata.status = 'ready'
          expect(youtube_metadata.next_available_statuses).to match_array([ 'published', 'draft' ])
        end

        it 'returns only allowed transitions from published' do
          youtube_metadata.status = 'published'
          expect(youtube_metadata.next_available_statuses).to match_array([ 'draft' ])
        end
      end

      describe '#transition_to!' do
        it 'successfully transitions when allowed' do
          youtube_metadata.status = 'draft'
          expect(youtube_metadata.transition_to!('ready')).to be true
          expect(youtube_metadata.reload.status).to eq('ready')
        end

        it 'fails to transition when not allowed' do
          youtube_metadata.update!(status: 'published')
          expect(youtube_metadata.transition_to!('ready')).to be false
          expect(youtube_metadata.errors[:status]).to be_present
          expect(youtube_metadata.reload.status).to eq('published')
        end
      end
    end
  end
end
