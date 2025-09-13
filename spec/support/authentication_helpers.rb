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

# Request Spec用の認証ヘルパー
RSpec.shared_context "Request Spec用認証" do
  let(:user) { create(:user) }

  before do
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end
end
