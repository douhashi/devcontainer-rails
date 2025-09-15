require 'rails_helper'

RSpec.describe "Audios", type: :request do
  let(:content) { create(:content) }

  describe "DELETE /contents/:content_id/audio" do
    context "when audio exists" do
      let!(:audio) { create(:audio, content: content) }

      it "deletes the audio" do
        expect {
          delete content_audio_path(content)
        }.to change(Audio, :count).by(-1)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("音源が削除されました")
      end
    end

    context "when audio does not exist" do
      it "redirects with error message" do
        delete content_audio_path(content)
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("削除する音源が見つかりません")
      end
    end
  end
end
