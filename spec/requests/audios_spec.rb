require 'rails_helper'

RSpec.describe "Audios", type: :request do
  let(:user) { create(:user) }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end

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
