# Issue #31: 使用DBを PostgreSQL から SQLite3 に切り替え

## 説明
現在 PostgreSQL を使用しているデータベースアダプターを、開発・テスト環境で SQLite3 に変更します。バージョン指定なしで `sqlite3` gem を追加し、`config/database.yml` を SQLite3 用に置き換えます。

## 変更内容
1. Gemfile  
   - `gem "pg", "~> 1.1"` を削除またはコメントアウト  
   - `gem "sqlite3"` を追加（バージョン指定なし）  
2. config/database.yml  
   - `adapter: postgresql` → `adapter: sqlite3`  
   - PG 固有の設定（host/username/password）を削除  
   - 各環境の database 名を `db/development.sqlite3` 等に変更  
3. DB 初期化  
   ```
   rails db:drop db:create db:migrate
   ```  
4. テスト確認  
   `bundle exec rspec` で全テストがパスすること  
5. CI 設定  
   PostgreSQL サービスの設定を削除または不要化  

## 実装手順
1. ブランチ作成: `git checkout -b fix/#31-sqlite3`  
2. Gemfile と config/database.yml を修正し `bundle install`  
3. DB 初期化・動作確認  
4. テスト実行・修正  
5. コミット & プッシュ  
6. PR 作成  

以上の計画に基づき、実装に進行します。
