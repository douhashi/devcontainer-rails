# frozen_string_literal: true

RSpec.shared_context "ログイン済み" do
  let(:user) { create(:user) }

  before do
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password'
    click_button 'ログイン'
    expect(page).to have_current_path(root_path)
  end
end
