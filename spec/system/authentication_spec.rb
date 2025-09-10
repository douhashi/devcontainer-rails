require 'rails_helper'

RSpec.describe 'Authentication', type: :system, js: true do
  let(:user) { create(:user, email: 'user1@example.com', password: 'password') }

  describe 'login process' do
    before do
      visit new_user_session_path
    end

    it 'displays login form and logs in successfully' do
      expect(page).to have_content('ログイン')
      expect(page).to have_field('メールアドレス')
      expect(page).to have_field('パスワード')

      fill_in 'メールアドレス', with: user.email
      fill_in 'パスワード', with: 'password'
      click_button 'ログイン'

      expect(page).to have_current_path(root_path)
    end

    it 'shows error for invalid credentials' do
      fill_in 'メールアドレス', with: 'invalid@example.com'
      fill_in 'パスワード', with: 'password'
      click_button 'ログイン'

      expect(page).to have_content('Invalid')
    end
  end

  describe 'access control' do
    it 'redirects to login page when accessing protected pages' do
      visit contents_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
