require 'rails_helper'

RSpec.describe 'User Dropdown', type: :request do
  let(:user) { create(:user, email: 'test@example.com') }

  describe 'Header display' do
    context 'when user is logged in' do
      before do
        post user_session_path, params: { user: { email: user.email, password: 'password' } }
      end

      it 'displays user email in header' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('test@example.com')
        expect(response.body).to include('data-testid="user-dropdown"')
      end

      it 'displays logout button' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('ログアウト')
        expect(response.body).to include(destroy_user_session_path)
      end

      it 'includes proper turbo method for logout' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-turbo-method="delete"')
      end

      it 'displays user avatar initial' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('T') # First letter of email
      end
    end

    context 'when user is not logged in' do
      it 'redirects to login page' do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'shows login page' do
        get new_user_session_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('ログイン')
        expect(response.body).to_not include('data-testid="user-dropdown"')
      end
    end
  end

  describe 'Long email handling' do
    let(:long_email_user) { create(:user, email: 'very.long.email.address@example-domain.com') }

    before do
      post user_session_path, params: { user: { email: long_email_user.email, password: 'password' } }
    end

    it 'handles long email addresses appropriately' do
      get root_path
      expect(response).to have_http_status(:success)
      # Should display the full email in the dropdown menu
      expect(response.body).to include('very.long.email.address@example-domain.com')
    end
  end

  describe 'User logout request' do
    before do
      post user_session_path, params: { user: { email: user.email, password: 'password' } }
    end

    it 'successfully logs out user' do
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)

      # Follow redirect and verify user is logged out
      follow_redirect!
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'logs out user with turbo delete method' do
      delete destroy_user_session_path, headers: { 'Turbo-Frame' => 'true' }
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'Accessibility and aria attributes' do
    before do
      post user_session_path, params: { user: { email: user.email, password: 'password' } }
    end

    it 'includes proper ARIA attributes in dropdown' do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('aria-haspopup="true"')
      expect(response.body).to include('aria-expanded="false"')
      expect(response.body).to include('role="button"')
      expect(response.body).to include('role="menu"')
    end
  end
end
