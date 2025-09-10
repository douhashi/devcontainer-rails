require "rails_helper"

RSpec.describe YoutubeCredential, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:access_token) }
    it { should validate_presence_of(:refresh_token) }
    it { should validate_presence_of(:expires_at) }
  end

  describe "token storage" do
    let(:user) { create(:user) }
    let(:credential) do
      described_class.create!(
        user: user,
        access_token: "test_access_token",
        refresh_token: "test_refresh_token",
        expires_at: 1.hour.from_now,
        scope: "youtube.readonly yt-analytics.readonly"
      )
    end

    it "stores access_token" do
      expect(credential.access_token).to eq("test_access_token")
    end

    it "stores refresh_token" do
      expect(credential.refresh_token).to eq("test_refresh_token")
    end
  end

  describe "#expired?" do
    let(:user) { create(:user) }

    context "when token is expired" do
      let(:credential) do
        create(:youtube_credential, user: user, expires_at: 1.hour.ago)
      end

      it "returns true" do
        expect(credential.expired?).to be true
      end
    end

    context "when token is not expired" do
      let(:credential) do
        create(:youtube_credential, user: user, expires_at: 1.hour.from_now)
      end

      it "returns false" do
        expect(credential.expired?).to be false
      end
    end
  end

  describe "#needs_refresh?" do
    let(:user) { create(:user) }

    context "when token expires within 5 minutes" do
      let(:credential) do
        create(:youtube_credential, user: user, expires_at: 3.minutes.from_now)
      end

      it "returns true" do
        expect(credential.needs_refresh?).to be true
      end
    end

    context "when token expires after 5 minutes" do
      let(:credential) do
        create(:youtube_credential, user: user, expires_at: 10.minutes.from_now)
      end

      it "returns false" do
        expect(credential.needs_refresh?).to be false
      end
    end
  end

  describe "#update_tokens!" do
    let(:user) { create(:user) }
    let(:credential) { create(:youtube_credential, user: user) }
    let(:new_tokens) do
      {
        access_token: "new_access_token",
        refresh_token: "new_refresh_token",
        expires_in: 3600
      }
    end

    it "updates tokens and expiration" do
      credential.update_tokens!(new_tokens)
      credential.reload

      expect(credential.access_token).to eq("new_access_token")
      expect(credential.refresh_token).to eq("new_refresh_token")
      expect(credential.expires_at).to be_within(1.second).of(1.hour.from_now)
    end

    context "when refresh_token is not provided" do
      let(:new_tokens) do
        {
          access_token: "new_access_token",
          expires_in: 3600
        }
      end

      it "keeps the existing refresh_token" do
        original_refresh_token = credential.refresh_token
        credential.update_tokens!(new_tokens)
        credential.reload

        expect(credential.access_token).to eq("new_access_token")
        expect(credential.refresh_token).to eq(original_refresh_token)
        expect(credential.expires_at).to be_within(1.second).of(1.hour.from_now)
      end
    end
  end
end
