# frozen_string_literal: true

# Contentモデルに対する認可ポリシークラス
# 現在はApplicationPolicyを継承しているため、すべてのアクションが許可されています。
# 将来的には、コンテンツの所有者や管理者権限に基づいた認可ロジックを実装する予定です。
class ContentPolicy < ApplicationPolicy
  # コンテンツの管理権限をチェック
  # 現在はログインユーザーであれば誰でも管理可能
  # 将来的には所有者や管理者権限のチェックを追加
  def manage?
    user.present?
  end

  # 例: 所有者のみが編集・削除できるようにする場合
  # def update?
  #   user.admin? || record.user == user
  # end
  #
  # def destroy?
  #   user.admin? || record.user == user
  # end
end
