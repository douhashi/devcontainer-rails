# Lofi BGM プロジェクト概要

## プロジェクトの目的

「Lofi BGM」という名前のYouTubeチャンネルに投稿するコンテンツ制作を自動化するシステムの開発・管理を行います。

Lofi BGMチャンネルでは、作業用BGMなどの長尺動画を音楽生成AIとアートワーク用の画像生成AIを用いて制作しています。本プロジェクトは、この制作プロセスを効率化・自動化するためのシステムです。

## システムの主要機能

### コンテンツ制作進捗管理

制作予定の動画（Content）の制作進捗を一元管理します。

#### Content構成要素

- **Track**: 音源（1コンテンツあたり複数の音源を持つ）
- **Artwork**: 画像（動画の静止画背景として使用）
- **Video**: 動画（Track群とArtworkを合成した最終成果物）
- **Theme**: アートワークやTrackの制作指示のテイスト（例：「レコード、古いスピーカー、ランプの明かり」）
- **Title**: YouTube投稿用動画タイトル
- **Description(EN)**: YouTube投稿用英語説明文
- **Description(JP)**: YouTube投稿用日本語説明文
- **Hashtag**: YouTube投稿時のハッシュタグ情報

## システム内処理機能

### 音源制作・編集

- **Track制作**: kie.aiが提供するSuno API経由での音源制作
- **ConcatAudio制作**: 指定された尺（分数）に基づいてTrackをランダムにつなぎ合わせ、長尺音源を作成

### 動画制作・公開

- **Video制作**: ArtworkとConcatAudioをFFMPEGで合成し、動画を作成
- **YouTube投稿**: 制作された動画のPublish（予約投稿）

## システム外処理

- **Artwork制作**: 外部で制作されたArtworkをシステムにアップロード

## 技術スタック

- Ruby on Rails（想定）
- FFMPEG（動画編集）
- Suno API（音楽生成）
- YouTube API（動画投稿）