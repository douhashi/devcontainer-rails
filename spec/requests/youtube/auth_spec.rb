require "rails_helper"

RSpec.describe "Youtube::Auth", type: :request do
  let(:user) { create(:user) }

  def sign_in_user(user = nil)
    user ||= self.user
    post user_session_path, params: {
      user: { email: user.email, password: user.password }
    }
  end

  before do
    # Set up test environment variables for YoutubeService
    ENV['YOUTUBE_CLIENT_ID'] ||= 'test_client_id'
    ENV['YOUTUBE_CLIENT_SECRET'] ||= 'test_client_secret'
    ENV['YOUTUBE_REDIRECT_URI'] ||= 'http://localhost:5100/youtube/auth/callback'
  end

  describe "GET /youtube/auth/authorize" do
    it "redirects to YouTube OAuth URL" do
      sign_in_user
      allow_any_instance_of(YoutubeService).to receive(:authorization_url)
        .and_return("https://accounts.google.com/oauth2/auth?client_id=test")

      get youtube_auth_authorize_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("accounts.google.com/oauth2/auth")
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get youtube_auth_authorize_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /youtube/auth/callback" do
    let(:authorization_code) { "test_auth_code" }
    let(:access_token) { "test_access_token" }
    let(:refresh_token) { "test_refresh_token" }
    let(:expires_in) { 3600 }

    context "with valid authorization code" do
      before do
        allow_any_instance_of(YoutubeService).to receive(:authenticate).with(authorization_code).and_return(
          {
            access_token: access_token,
            refresh_token: refresh_token,
            expires_in: expires_in
          }
        )
      end

      it "creates youtube credentials and redirects with success message" do
        sign_in_user
        # First make a request to authorize to set up the state in session
        get youtube_auth_authorize_path
        # Extract state from redirect URL
        state = CGI.parse(URI.parse(response.location).query)["state"].first if response.location

        expect {
          get youtube_auth_callback_path(code: authorization_code, state: state)
        }.to change(YoutubeCredential, :count).by(1)

        credential = user.reload.youtube_credential
        expect(credential.access_token).to eq(access_token)
        expect(credential.refresh_token).to eq(refresh_token)
        expect(credential.expires_at).to be_within(1.second).of(expires_in.seconds.from_now)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq(I18n.t("youtube.auth.callback.success"))
      end

      context "when user already has credentials" do
        let!(:existing_credential) { create(:youtube_credential, user: user) }

        it "updates existing credentials" do
          sign_in_user
          # First make a request to authorize to set up the state in session
          get youtube_auth_authorize_path
          # Extract state from redirect URL
          state = CGI.parse(URI.parse(response.location).query)["state"].first if response.location

          expect {
            get youtube_auth_callback_path(code: authorization_code, state: state)
          }.not_to change(YoutubeCredential, :count)

          existing_credential.reload
          expect(existing_credential.access_token).to eq(access_token)
          expect(existing_credential.refresh_token).to eq(refresh_token)
        end
      end
    end

    context "with invalid authorization code" do
      before do
        allow_any_instance_of(YoutubeService).to receive(:authenticate).and_raise(Youtube::Errors::AuthenticationError, "Invalid code")
      end

      it "redirects with error message" do
        sign_in_user
        # First make a request to authorize to set up the state in session
        get youtube_auth_authorize_path
        # Extract state from redirect URL
        state = CGI.parse(URI.parse(response.location).query)["state"].first if response.location

        get youtube_auth_callback_path(code: "invalid_code", state: state)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("youtube.auth.callback.error"))
      end
    end

    context "when user denies access" do
      it "redirects with cancelled message" do
        sign_in_user
        get youtube_auth_callback_path(error: "access_denied")

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("youtube.auth.callback.cancelled"))
      end
    end

    context "when state parameter is invalid" do
      it "redirects with error message for CSRF protection" do
        sign_in_user
        # First make a request to authorize to set up the state in session
        get youtube_auth_authorize_path
        # Use a different state than what was set
        get youtube_auth_callback_path(code: authorization_code, state: "invalid_state")

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("youtube.auth.callback.error"))
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get youtube_auth_callback_path(code: authorization_code)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /youtube/auth/disconnect" do
    context "when user has youtube credentials" do
      let!(:youtube_credential) { create(:youtube_credential, user: user) }

      it "destroys youtube credentials and redirects with success message" do
        sign_in_user
        expect {
          delete youtube_auth_disconnect_path
        }.to change(YoutubeCredential, :count).by(-1)

        expect(user.reload.youtube_credential).to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq(I18n.t("youtube.auth.disconnect.success"))
      end
    end

    context "when user does not have youtube credentials" do
      it "redirects with error message" do
        sign_in_user
        delete youtube_auth_disconnect_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("youtube.auth.disconnect.not_connected"))
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        delete youtube_auth_disconnect_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
