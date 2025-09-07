require 'rails_helper'

RSpec.describe Video, type: :model do
  describe 'associations' do
    it { should belong_to(:content) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:status) }
  end

  describe 'enums' do
    it { should enumerize(:status).in(:pending, :processing, :completed, :failed).with_default(:pending) }
  end

  describe 'scopes' do
    let!(:pending_video) { create(:video, :pending) }
    let!(:processing_video) { create(:video, :processing) }
    let!(:completed_video) { create(:video, :completed) }
    let!(:failed_video) { create(:video, :failed) }

    it 'has working scopes' do
      expect(Video.recent).to include(pending_video, processing_video, completed_video, failed_video)
      expect(Video.pending).to include(pending_video)
      expect(Video.processing).to include(processing_video)
      expect(Video.completed).to include(completed_video)
      expect(Video.failed).to include(failed_video)
    end
  end

  describe 'predicates' do
    let(:video) { create(:video, :pending) }

    it 'has status predicates' do
      expect(video).to be_pending
      expect(video).not_to be_processing
      expect(video).not_to be_completed
      expect(video).not_to be_failed

      video.update!(status: :completed)
      expect(video).not_to be_pending
      expect(video).to be_completed
    end
  end
end
