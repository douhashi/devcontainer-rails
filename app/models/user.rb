class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable

  has_one :youtube_credential, dependent: :destroy

  scope :with_youtube_connected, -> { joins(:youtube_credential) }

  def youtube_connected?
    youtube_credential.present?
  end
end
