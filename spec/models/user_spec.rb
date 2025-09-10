require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'generates sequential email addresses' do
      user1 = create(:user)
      user2 = create(:user)

      expect(user1.email).to match(/user\d+@example\.com/)
      expect(user2.email).to match(/user\d+@example\.com/)
      expect(user1.email).not_to eq(user2.email)
    end
  end

  describe 'authentication' do
    let(:user) { create(:user, password: 'password') }

    it 'authenticates with correct password' do
      expect(user.valid_password?('password')).to be true
    end

    it 'does not authenticate with incorrect password' do
      expect(user.valid_password?('wrong_password')).to be false
    end
  end
end
