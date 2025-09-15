require 'rails_helper'

RSpec.describe "MusicGenerations", type: :request do
  let(:content) { create(:content) }
  let!(:music_generation) { create(:music_generation, content: content) }
  let!(:track) { create(:track, content: content, music_generation: music_generation) }

  describe "DELETE /contents/:content_id/music_generations/:id" do
    context "when requesting HTML format" do
      it "destroys the MusicGeneration and its associated Tracks" do
        expect {
          delete content_music_generation_path(content, music_generation)
        }.to change(MusicGeneration, :count).by(-1)
         .and change(Track, :count).by(-1)

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("音楽生成が削除されました")
      end
    end

    context "when requesting with Turbo Stream format" do
      it "destroys the MusicGeneration and redirects (no Turbo Stream support)" do
        expect {
          delete content_music_generation_path(content, music_generation),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(MusicGeneration, :count).by(-1)
         .and change(Track, :count).by(-1)

        # Turbo StreamをサポートしないのでHTMLリダイレクトになる
        expect(response).to redirect_to(content)
      end
    end

    context "with different MusicGeneration statuses" do
      %w[pending processing completed failed].each do |status|
        it "can delete MusicGeneration with #{status} status" do
          music_generation.update!(status: status)

          expect {
            delete content_music_generation_path(content, music_generation)
          }.to change(MusicGeneration, :count).by(-1)

          expect(response).to redirect_to(content)
        end
      end
    end


    context "when MusicGeneration has multiple Tracks" do
      let!(:additional_track) { create(:track, content: content, music_generation: music_generation) }

      it "destroys all associated Tracks" do
        expect(music_generation.tracks.count).to eq(2)

        expect {
          delete content_music_generation_path(content, music_generation)
        }.to change(MusicGeneration, :count).by(-1)
         .and change(Track, :count).by(-2)
      end
    end
  end
end
