# KIE.AI Music Generation API 仕様書

## 概要

KIE.AI Music Generation APIは、AI技術を活用した音楽生成サービスです。本ドキュメントは、lofi-bgmアプリケーションにおけるKIE APIの統合実装に基づいた仕様書です。

- **公式ドキュメント**: https://docs.kie.ai/suno-api/quickstart
- **Generate Music API**: https://docs.kie.ai/suno-api/generate-music
- **最終更新日**: 2025年9月8日

## 認証

KIE APIではBearer Token方式を使用します。

```ruby
headers = {
  "Authorization" => "Bearer #{api_key}",
  "Content-Type" => "application/json",
  "Accept" => "application/json"
}
```

APIキーは環境変数 `KIE_AI_API_KEY` に設定してください。APIキーは https://kie.ai/api-key から取得できます。

## AIモデル

| モデル | 特徴 |
|-------|-----|
| `V3_5` | Better song structure（より良い楽曲構造） |
| `V4` | Improved vocals（改善されたボーカル） |
| `V4_5` | Smart prompts（スマートプロンプト） |
| `V4_5PLUS` | Richer sound（より豊かなサウンド） |

## エンドポイント

### 基本URL
```
https://api.kie.ai
```

### その他の利用可能なエンドポイント

本ドキュメントでは音楽生成エンドポイントに焦点を当てていますが、KIE APIには以下のエンドポイントも提供されています：

- `POST /api/v1/generate/extend` - 音楽拡張
- `POST /api/v1/lyrics` - 歌詞生成
- `POST /api/v1/generate/upload-cover` - アップロードとカバー
- `POST /api/v1/generate/upload-extend` - アップロードと拡張
- `POST /api/v1/generate/add-instrumental` - インストゥルメンタル追加
- `POST /api/v1/generate/add-vocals` - ボーカル追加

詳細は公式ドキュメントを参照してください。

### 1. 音楽生成リクエスト

**エンドポイント**: `POST /api/v1/generate`

音楽生成タスクを開始します。

#### リクエストパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|-----------|----|----|----------|-----|
| `prompt` | string | ✅ | - | 音楽生成のプロンプト（V3_5/V4: 3000文字、V4_5/V4_5PLUS: 5000文字） |
| `model` | string | - | "V4_5PLUS" | 使用するAIモデル（V3_5, V4, V4_5, V4_5PLUS） |
| `style` | string | - | null | 音楽スタイル指定 |
| `title` | string | - | null | トラック名（最大80文字） |
| `wait_audio` | boolean | - | false | 生成完了まで待機するか |
| `customMode` | boolean | - | false | カスタムモード（falseを推奨） |
| `instrumental` | boolean | - | true | インストゥルメンタル楽曲 |
| `callBackUrl` | string | - | - | コールバックURL |
| `negativeTags` | string | - | null | 避けるスタイル |
| `vocalGender` | string | - | null | 優先ボーカルタイプ |
| `styleWeight` | number | - | null | スタイル遵守の強度（0-1） |
| `weirdnessConstraint` | number | - | null | 創作的逸脱レベル（0-1） |
| `audioWeight` | number | - | null | 音声特徴のバランス（0-1） |

#### リクエスト例

```ruby
body = {
  prompt: "relaxing jazz piano with soft rain sounds",
  model: "V4_5PLUS",
  instrumental: true,
  wait_audio: false,
  callBackUrl: "https://example.com/callback"
}
```

#### レスポンス（成功時）

```json
{
  "code": 200,
  "data": {
    "taskId": "task_abc123def456",
    "status": "pending"
  },
  "message": "Success"
}
```

#### エラーレスポンス例

```json
{
  "code": 401,
  "message": "Invalid API key",
  "data": null
}
```

### 2. タスク状況取得

**エンドポイント**: `GET /api/v1/generate/record-info`

生成タスクの進行状況と結果を取得します。

#### クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|-----------|----|----|-----|
| `taskId` | string | ✅ | 生成タスクのID |

#### リクエスト例

```ruby
response = make_request(
  :get,
  "/api/v1/generate/record-info",
  query: { taskId: "task_abc123def456" }
)
```

#### レスポンス（進行中）

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "taskId": "5c79****be8e",
    "status": "PENDING"
  }
}
```

#### レスポンス（部分完了時）

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "taskId": "5c79****be8e",
    "status": "FIRST_SUCCESS",
    "response": {
      "sunoData": [
        {
          "id": "audio_abc123",
          "audioUrl": "https://storage.kie.ai/audio/audio_abc123.mp3",
          "title": "Relaxing Jazz Piano",
          "duration": 198.44
        }
      ]
    }
  }
}
```

#### レスポンス（完了時）

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "taskId": "5c79****be8e",
    "status": "SUCCESS",
    "response": {
      "sunoData": [
        {
          "id": "audio_abc123",
          "audioUrl": "https://storage.kie.ai/audio/audio_abc123.mp3",
          "title": "Relaxing Jazz Piano",
          "tags": "jazz, piano, relaxing, instrumental",
          "duration": 198.44,
          "modelName": "V4_5PLUS",
          "prompt": "relaxing jazz piano with soft rain sounds"
        },
        {
          "id": "audio_def456",
          "audioUrl": "https://storage.kie.ai/audio/audio_def456.mp3",
          "title": "Relaxing Jazz Piano (Variation)",
          "tags": "jazz, piano, relaxing, instrumental",
          "duration": 201.12,
          "modelName": "V4_5PLUS",
          "prompt": "relaxing jazz piano with soft rain sounds"
        }
      ]
    }
  }
}
```

## ステータス値

### タスクステータス（公式仕様）

| ステータス | 意味 | 説明 |
|-----------|-----|------|
| `PENDING` | Processing | タスクが待機中または処理中 |
| `TEXT_SUCCESS` | Partial | 歌詞・テキスト生成が完了 |
| `FIRST_SUCCESS` | Partial | 最初のトラック生成が完了 |
| `SUCCESS` | Complete | 全てのトラック生成が完了 |

### エラーステータス

| ステータス | 説明 |
|-----------|-----|
| `CREATE_TASK_FAILED` | タスクの作成に失敗 |
| `GENERATE_AUDIO_FAILED` | 音声生成に失敗 |
| `SENSITIVE_WORD_ERROR` | センシティブな内容によりフィルタリング |

### 実装上の注意

- **大文字表記**: 公式APIのステータス値は全て大文字です
- **完了判定**: `SUCCESS`が最終的な完了状態です
- **部分完了**: `TEXT_SUCCESS`および`FIRST_SUCCESS`は処理の中間段階です
- **既存実装との差異**: 現在の実装では小文字での判定を行っているため、正規化処理が必要です

```ruby
# ステータス判定の実装例（公式仕様対応）
status = task_data["status"]
case status
when "SUCCESS"
  # 全生成完了処理
when "FIRST_SUCCESS", "TEXT_SUCCESS"
  # 部分完了処理（継続ポーリング）
when "PENDING"
  # 待機中処理（継続ポーリング）
when "CREATE_TASK_FAILED", "GENERATE_AUDIO_FAILED", "SENSITIVE_WORD_ERROR"
  # エラー処理
end

# 既存実装との互換性のための正規化
normalized_status = status.to_s.downcase
if normalized_status == "success"
  # 完了処理
elsif normalized_status.in?(["create_task_failed", "generate_audio_failed", "sensitive_word_error"])
  # エラー処理
end
```

## エラーハンドリング

### エラークラス階層

```
Kie::Errors::ApiError (基底クラス)
├── AuthenticationError (401: 認証エラー)
├── RateLimitError (429: レート制限エラー)  
├── TaskFailedError (タスク実行失敗)
├── TimeoutError (タイムアウト)
├── NetworkError (ネットワークエラー)
└── InsufficientCreditsError (クレジット不足)
```

### HTTPステータスコードとエラーの対応

| HTTPコード | エラークラス | 説明 |
|-----------|-------------|-----|
| 200 | - | 成功（ただし、レスポンス内codeフィールドも確認） |
| 401 | `AuthenticationError` | API認証失敗 |
| 404 | `ApiError` | エンドポイントが見つからない |
| 429 | `RateLimitError` | API利用制限に達している |
| 400-499 | `ApiError` | クライアントエラー |
| 500-599 | `ApiError` | サーバーエラー |

### エラーレスポンスの構造

```json
{
  "code": 401,
  "message": "Authentication failed: Invalid API key",
  "data": null
}
```

### Rubyでのエラーハンドリング例

```ruby
begin
  task_id = kie_service.generate_music(prompt: "peaceful ambient music")
rescue Kie::Errors::AuthenticationError => e
  # 認証エラーの処理
  Rails.logger.error "API認証エラー: #{e.message}"
rescue Kie::Errors::RateLimitError => e
  # レート制限エラーの処理
  Rails.logger.warn "レート制限エラー: #{e.message}"
rescue Kie::Errors::ApiError => e
  # その他のAPIエラーの処理
  Rails.logger.error "APIエラー: #{e.message} (code: #{e.response_code})"
end
```

## 音楽生成ワークフロー

### 1. 基本フロー

```
1. 音楽生成リクエスト送信
   ↓ (POST /api/v1/generate)
2. タスクID取得
   ↓
3. ポーリング開始
   ↓ (GET /api/v1/generate/record-info)
4. ステータス確認（PENDING → TEXT_SUCCESS → FIRST_SUCCESS → SUCCESS）
   ↓
5. 音楽データ取得
   ↓
6. 音声ファイルダウンロード
```

### 2. ポーリング戦略

#### 指数バックオフ

```ruby
def calculate_polling_interval(attempt)
  initial_interval = 5  # 初期間隔（秒）
  max_interval = 30     # 最大間隔（秒）
  
  # 指数バックオフ: min(initial * 2^(attempt-1), max_interval)
  base_interval = [initial_interval * (2 ** (attempt - 1)), max_interval].min
  
  # ジッター追加（0-30%のランダム変動）
  jitter = rand * 0.3 * base_interval
  (base_interval + jitter).round(2)
end
```

#### ポーリング制限

- **最大試行回数**: 30回
- **初期間隔**: 5秒
- **最大間隔**: 30秒
- **タイムアウト**: 約15-20分（試行回数による）

### 3. 実装例（GenerateMusicGenerationJob）

```ruby
class GenerateMusicGenerationJob < ApplicationJob
  MAX_POLLING_ATTEMPTS = 30
  
  def perform(music_generation_id)
    # 1. 音楽生成リクエスト
    task_id = kie_service.generate_music(
      prompt: music_generation.prompt,
      model: music_generation.generation_model || "V4_5PLUS",
      instrumental: true,
      wait_audio: false
    )
    
    # 2. ポーリングで完了を待機
    attempts = 0
    loop do
      attempts += 1
      task_data = kie_service.get_task_status(task_id)
      
      # ステータス判定（公式仕様）
      case task_data["status"]
      when "SUCCESS"
        process_completed_generation(task_data)
        break
      when "FIRST_SUCCESS", "TEXT_SUCCESS"
        # 部分完了 - 継続ポーリング
        Rails.logger.info "Partial completion: #{task_data['status']}"
      when "PENDING"
        # 処理中 - 継続ポーリング
      when "CREATE_TASK_FAILED", "GENERATE_AUDIO_FAILED", "SENSITIVE_WORD_ERROR"
        raise Kie::Errors::TaskFailedError, task_data["error"] || "Generation failed: #{task_data['status']}"
      else
        Rails.logger.warn "Unknown status: #{task_data['status']}"
      end
      
      if attempts >= MAX_POLLING_ATTEMPTS
        raise Kie::Errors::TimeoutError, "Polling timeout exceeded"
      end
      
      # 指数バックオフで待機
      sleep(calculate_polling_interval(attempts))
    end
  end
end
```

## レスポンスデータ構造

### sunoData配列の構造

生成された音楽データは`response.sunoData`配列に格納されます。

```json
{
  "response": {
    "sunoData": [
      {
        "audioId": "audio_abc123",
        "audioUrl": "https://storage.kie.ai/audio/audio_abc123.mp3",
        "title": "Peaceful Morning Jazz",
        "tags": "jazz, morning, peaceful, piano",
        "duration": 180,
        "modelName": "V4_5PLUS",
        "prompt": "peaceful morning jazz with piano"
      }
    ]
  }
}
```

### フィールド説明

| フィールド | 型 | 説明 |
|-----------|----|----|
| `audioId` | string | 音声ファイルの一意ID |
| `audioUrl` | string | 音声ファイルのダウンロードURL |
| `title` | string | 生成された楽曲タイトル |
| `tags` | string | 楽曲のタグ（カンマ区切り） |
| `duration` | number | 楽曲の長さ（秒） |
| `modelName` | string | 使用されたAIモデル名 |
| `prompt` | string | 実際に使用されたプロンプト |

### データ抽出の実装例

```ruby
# 最初の音楽データを取得
def extract_music_data(task_data)
  suno_data = task_data.dig("response", "sunoData")
  return nil unless suno_data.is_a?(Array) && !suno_data.empty?
  
  first_music = suno_data.first
  return nil unless first_music.is_a?(Hash)
  
  audio_url = first_music["audioUrl"]
  return nil if audio_url.nil? || audio_url.to_s.strip.empty?
  
  {
    audio_url: audio_url,
    title: first_music["title"],
    tags: first_music["tags"],
    duration: first_music["duration"],
    model_name: first_music["modelName"],
    generated_prompt: first_music["prompt"],
    audio_id: first_music["audioId"]
  }
end

# 全ての音楽データを取得
def extract_all_music_data(task_data)
  suno_data = task_data.dig("response", "sunoData")
  return [] unless suno_data.is_a?(Array)
  
  suno_data.filter_map do |music|
    next unless music.is_a?(Hash)
    
    audio_url = music["audioUrl"]
    next if audio_url.nil? || audio_url.to_s.strip.empty?
    
    {
      audio_url: audio_url,
      title: music["title"],
      tags: music["tags"],
      duration: music["duration"],
      model_name: music["modelName"],
      generated_prompt: music["prompt"],
      audio_id: music["audioId"]
    }
  end
end
```

## 音声ファイルダウンロード

### ダウンロード方法

```ruby
def download_audio(audio_url, file_path)
  uri = URI(audio_url)
  response = Net::HTTP.get_response(uri)
  
  if response.code == "200"
    # ディレクトリ作成
    FileUtils.mkdir_p(File.dirname(file_path))
    
    # バイナリファイルとして保存
    File.binwrite(file_path, response.body)
    file_path
  else
    raise Kie::Errors::NetworkError, "Failed to download audio: HTTP #{response.code}"
  end
end
```

### ファイル保持期間

- **保持期間**: 生成されたファイルは14日間保持されます
- 生成後はできるだけ早期にダウンロードして永続化することを推奨します
- 保持期間を過ぎるとファイルへのアクセスができなくなります

### コールバック機能

コールバックURLを指定した場合、以下のステージでWebhookが送信されます：

1. **`text`**: テキスト生成完了時
2. **`first`**: 最初のトラック完了時  
3. **`complete`**: 全トラック完了時

```json
{
  "taskId": "5c79****be8e",
  "stage": "complete",
  "status": "SUCCESS",
  "response": {
    "sunoData": [...]
  }
}
```

## 実装上の注意点

### 1. リクエスト制限

```ruby
DEFAULT_MODEL = "V4_5PLUS"
MAX_PROMPT_LENGTH_V3_V4 = 3000     # V3_5, V4の最大文字数
MAX_PROMPT_LENGTH_V4_5 = 5000      # V4_5, V4_5PLUSの最大文字数
MAX_TITLE_LENGTH = 80              # タイトル最大文字数
MAX_RETRIES = 3                    # 最大リトライ回数  
RETRY_DELAY = 1                    # リトライ間隔（秒）
```

### 2. customModeの使用について

- **新規ユーザー**: `customMode: false`を推奨
- **falseの場合**: シンプルなパラメータ要件
- **trueの場合**: 詳細なパラメータ制御が可能

### 2. タイムアウト設定

```ruby
default_timeout 30  # HTTPリクエストタイムアウト（秒）
```

### 3. リトライ戦略

```ruby
def with_retry(max_retries: MAX_RETRIES, &block)
  retries = 0
  begin
    yield
  rescue Kie::Errors::NetworkError, Kie::Errors::RateLimitError => e
    retries += 1
    if retries < max_retries
      sleep(RETRY_DELAY * retries) # 指数バックオフ
      retry
    else
      raise
    end
  end
end
```

### 4. レスポンス検証

```ruby
def validate_task_response(task_data)
  # 必須フィールドチェック
  required_fields = %w[taskId status]
  missing_fields = required_fields - task_data.keys
  
  # ステータス値チェック  
  expected_statuses = %w[pending processing completed failed success]
  normalized_status = task_data["status"].to_s.downcase
  unless expected_statuses.include?(normalized_status)
    Rails.logger.warn "Unexpected status: '#{task_data['status']}'"
  end
end
```

### 5. ログ出力

開発環境では詳細なAPIレスポンスをログ出力します：

```ruby
if Rails.env.development? && task_data
  Rails.logger.debug "KIE API Response: #{JSON.pretty_generate(task_data)}"
end
```

## Ruby実装例

### KieServiceクラス

```ruby
class KieService
  include HTTParty
  
  base_uri "https://api.kie.ai"
  default_timeout 30
  
  def initialize
    @api_key = ENV.fetch("KIE_AI_API_KEY")
    raise Kie::Errors::AuthenticationError, "API key not set" if @api_key.blank?
  end
  
  def generate_music(prompt:, model: "V4_5PLUS", **options)
    validate_prompt(prompt)
    
    body = {
      prompt: prompt,
      model: model,
      instrumental: true,
      wait_audio: false,
      callBackUrl: "https://lofi-bgm-not-exist-server.com/callback"
    }.merge(options).compact
    
    response = with_retry do
      make_request(:post, "/api/v1/generate", body: body.to_json)
    end
    
    response.dig("data", "taskId")
  end
  
  def get_task_status(task_id)
    response = with_retry do
      make_request(:get, "/api/v1/generate/record-info", query: { taskId: task_id })
    end
    
    response["data"]
  end
end
```

## よくある問題と対処法

### 1. 認証エラー
- **原因**: APIキーが未設定または無効
- **対処**: `KIE_AI_API_KEY`環境変数を確認

### 2. タスク失敗
- **原因**: プロンプトが不適切、またはサーバー側エラー
- **対処**: プロンプトを見直し、エラーメッセージを確認

### 3. タイムアウト
- **原因**: 生成に想定以上の時間がかかっている
- **対処**: ポーリング設定を調整、またはプロンプトを簡潔にする

### 4. レート制限
- **原因**: API呼び出し頻度が制限を超過
- **対処**: リトライ間隔を長くする、並列処理数を制限

---

**注意**: この仕様書は2025年9月8日時点のKIE APIおよび実装に基づいています。API仕様の変更により内容が古くなる可能性があるため、定期的な見直しが必要です。