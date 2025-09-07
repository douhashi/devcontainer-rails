# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # ⚠️ 警告: セキュリティリスク - 開発段階の一時的な設定 ⚠️
  #
  # 現在、すべてのアクションが無条件で許可されています。
  # これは開発段階のみの設定であり、本番環境では必ず適切な認可ロジックを実装してください。
  #
  # 本番環境での実装例:
  # def index?
  #   user.present? && user.can_view_contents?
  # end
  #
  # TODO: 本番デプロイ前に必ず認可ロジックを実装すること
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    true
  end

  def edit?
    update?
  end

  def destroy?
    true
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.all
    end

    private

    attr_reader :user, :scope
  end
end
