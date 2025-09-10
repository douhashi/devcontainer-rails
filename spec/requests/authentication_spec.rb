require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let(:user) { create(:user) }

  describe 'access control' do
    context 'when user is not authenticated' do
      it 'redirects to login page for protected pages' do
        get contents_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login page for root' do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      it 'allows access to protected pages' do
        get contents_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to root' do
        get root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
