require 'rails_helper'

RSpec.describe 'Devise::Sessions', type: :request do
  let(:user) { create(:user, email: 'user1@example.com', password: 'password') }

  describe 'GET /users/sign_in' do
    it 'displays the login page' do
      get new_user_session_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('ログイン')
      expect(response.body).to include('メールアドレス')
      expect(response.body).to include('パスワード')
    end
  end

  describe 'POST /users/sign_in' do
    context 'with valid credentials' do
      it 'logs in the user successfully' do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'password'
          }
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid credentials' do
      it 'rejects login with invalid email' do
        post user_session_path, params: {
          user: {
            email: 'nonexistent@example.com',
            password: 'password'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        # Check that we're on the login page (not redirected to root)
        expect(response.body).to include('ログイン')
        expect(response.body).to include('user[email]')
      end

      it 'rejects login with invalid password' do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        # Check that we're on the login page (not redirected to root)
        expect(response.body).to include('ログイン')
        expect(response.body).to include('user[email]')
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    before { sign_in user }

    it 'logs out the user successfully' do
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
