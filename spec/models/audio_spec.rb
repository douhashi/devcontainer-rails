require 'rails_helper'

RSpec.describe Audio, type: :model do
  describe 'metadata handling' do
    let(:content) { create(:content) }
    let(:metadata) { { selected_tracks: [ 1, 2, 3 ], total_duration_min: 180 } }
    let(:audio) { create(:audio, content: content, metadata: metadata) }

    it 'stores and retrieves metadata as JSON' do
      expect(audio.metadata).to be_a(Hash)
      expect(audio.metadata['selected_tracks']).to eq([ 1, 2, 3 ])
      expect(audio.metadata['total_duration_min']).to eq(180)
    end
  end
end
