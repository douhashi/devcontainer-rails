require "rails_helper"

RSpec.describe "Track search functionality", type: :system, js: true do
  let!(:content1) { create(:content, theme: "Relaxing Background Music") }
  let!(:content2) { create(:content, theme: "Focus Study Sounds") }

  let!(:track1) do
    create(:track,
      content: content1,
      status: "completed",
      metadata: { music_title: "Morning Coffee Jazz" },
      created_at: 1.day.ago)
  end

  let!(:track2) do
    create(:track,
      content: content2,
      status: "pending",
      metadata: { music_title: "Deep Work Flow" },
      created_at: 2.days.ago)
  end

  let!(:track3) do
    create(:track,
      content: content1,
      status: "processing",
      metadata: { music_title: "Evening Relaxation" },
      created_at: 3.hours.ago)
  end

  before do
    visit tracks_path
  end

  describe "search form display" do
    it "displays the search form on tracks index page" do
      expect(page).to have_css("form[data-controller='track-search']")
      expect(page).to have_field("q[content_theme_cont]")
      expect(page).to have_field("q[music_title_cont]")
      expect(page).to have_select("q[status_eq]")
      expect(page).to have_field("q[created_at_gteq]")
      expect(page).to have_field("q[created_at_lteq]")
    end

    it "displays search and reset buttons" do
      expect(page).to have_button("検索")
      expect(page).to have_link("リセット")
    end
  end

  describe "search by content theme" do
    it "filters tracks by content theme" do
      fill_in "q_content_theme_cont", with: "Relax"
      click_button "検索"

      # Wait for search results to load
      expect(page).to have_current_path(tracks_path, ignore_query: false)

      expect(page).to have_content("Morning Coffee Jazz")
      expect(page).to have_content("Evening Relaxation")
      expect(page).not_to have_content("Deep Work Flow")
    end
  end

  describe "search by music title" do
    it "filters tracks by music title" do
      fill_in "q_music_title_cont", with: "Coffee"
      click_button "検索"

      expect(page).to have_content("Morning Coffee Jazz")
      expect(page).not_to have_content("Deep Work Flow")
      expect(page).not_to have_content("Evening Relaxation")
    end
  end

  describe "search by status" do
    it "filters tracks by status" do
      select "完了", from: "q_status_eq"
      click_button "検索"

      expect(page).to have_content("Morning Coffee Jazz")
      expect(page).not_to have_content("Deep Work Flow")
      expect(page).not_to have_content("Evening Relaxation")
    end
  end

  describe "combined search criteria" do
    it "filters tracks using multiple criteria" do
      fill_in "q_content_theme_cont", with: "Relax"
      select "完了", from: "q_status_eq"
      click_button "検索"

      expect(page).to have_content("Morning Coffee Jazz")
      expect(page).not_to have_content("Deep Work Flow")
      expect(page).not_to have_content("Evening Relaxation")
    end
  end

  describe "search form reset" do
    it "clears all search criteria when reset is clicked" do
      fill_in "q[content_theme_cont]", with: "Test"
      select "処理中", from: "q[status_eq]"

      click_link "リセット"

      expect(page).to have_field("q[content_theme_cont]", with: "")
      expect(page).to have_select("q[status_eq]", selected: "すべて")

      # All tracks should be visible
      expect(page).to have_content("Morning Coffee Jazz")
      expect(page).to have_content("Deep Work Flow")
      expect(page).to have_content("Evening Relaxation")
    end
  end

  describe "date range validation", js: true do
    xit "sets min attribute on end date when start date is selected" do
      fill_in "q_created_at_gteq", with: Date.today.to_s

      # Trigger change event
      find_field("q_created_at_gteq").send_keys(:tab)

      # The JavaScript should set min attribute on end date
      expect(find_field("q_created_at_lteq")["min"]).to eq(Date.today.to_s)
    end
  end

  describe "search results persistence" do
    it "preserves search criteria after performing a search" do
      fill_in "q_content_theme_cont", with: "Relax"
      select "完了", from: "q_status_eq"
      click_button "検索"

      expect(page).to have_field("q_content_theme_cont", with: "Relax")
      expect(page).to have_select("q_status_eq", selected: "完了")
    end
  end
end
