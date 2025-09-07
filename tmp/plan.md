# 実行計画: SolidQueue用の設定をする (Issue #25)

## 前提知識
- SolidQueue（https://github.com/rails/solid_queue）：ActiveJobのキューアダプタとして動作し、SQLite3ベースの永続キューを提供
- Railsのマルチデータベース機能：config/database.ymlで用途別接続を定義可能
- Foreman／Procfile.devによる複数プロセス管理

## 要件概要
1. ジョブキュー専用のSQLite3データベースを開発・テスト・本番環境に用意
2. SolidQueueを導入し、ジョブは専用DBで永続化
3. bin/server（Procfile.dev）でSolidQueueワーカーを起動可能にする
4. CI／テスト環境でもキューDBのマイグレーションを実行

## 実装計画
1. データベース設定 (config/database.yml)  
   - 各環境に`primary`と`queue`の接続を定義  
   - 開発：db/development.sqlite3, db/solid_queue_development.sqlite3  
   - テスト：db/test.sqlite3,    db/solid_queue_test.sqlite3  
   - 本番：db/production.sqlite3, db/solid_queue_production.sqlite3  
   - `migrations_paths: db/queue_migrate`をqueue用に指定

2. 初期化ファイル作成 (config/initializers/solid_queue.rb)  
   ```ruby
   Rails.application.config.to_prepare do
     SolidQueue.configure do |config|
       config.connects_to = { database: { writing: :queue } }
       config.polling_interval = 1.second
       config.preserve_finished_jobs = true
       config.clear_finished_jobs_after = 1.day
     end
   end
   ```

3. 環境設定 (environments/*.rb)  
   - `config.active_job.queue_adapter = :solid_queue` を development, test, production に追加

4. マイグレーション生成・実行  
   ```bash
   bin/rails solid_queue:install
   mkdir -p db/queue_migrate
   bin/rails db:create:queue
   bin/rails db:migrate:queue
   ```

5. Procfile.dev更新  
   ```
   vite:  bin/vite dev
   web:   bin/rails s -b 0.0.0.0
   worker: bin/rails solid_queue:start
   ```

6. CI設定更新 (.github/workflows/ci.yml)  
   ```yaml
   - name: Setup queue database
     run: bin/rails db:create:queue db:migrate:queue
   ```

## テスト計画
- サンプルジョブを`perform_later`し、queue DBにレコードが作成されることを確認
- ワーカー起動後にジョブが実行されることを確認
- CI上でマイグレーション→テストがグリーンになること

## リスクと対策
- マルチDB設定ミス：Rails公式ドキュメント参照、各環境で動作確認
- 不要レコード蓄積：定期的に`SolidQueue::Job.clear_finished_in_batches`を実行するRakeタスクを検討
