---
# acceptance intent: mixed JP+EN source
# sb-ingest JP/EN auto-detect test — mixed (JP primary, EN technical terms)
#
# 期待動作:
#   1. sb-ingest が JP を primary 言語と判定する (JP 文字数 > EN 文字数)
#   2. frontmatter の aliases: フィールドに EN 候補を自動生成する
#   3. EN 技術用語 (API, SDK, etc.) は mixed 判定に影響しない
#
# acceptance check:
#   - aliases: フィールドが生成されていること
#   - primary 言語判定が JP であること (JP 文字列が支配的なため)
#   - aliases の値が英語 (ラテン文字) であること
#   - mixed フラグがログに記録されること (JP primary + EN technical terms detected)
type: source
title: "クラウドAPI設計パターン"
created: 2026-05-05
updated: 2026-05-05
tags: [domain/api, domain/cloud, domain/architecture]
Status: ACTIVE
Last-verified: 2026-05-05
Half-life: 30d
language_primary: jp
language_secondary: en
# aliases: フィールドは sb-ingest が自動生成する (下記はサンプル期待値)
# aliases: ["Cloud API Design Patterns", "API Design Patterns"]
---

# クラウドAPI設計パターン

このドキュメントでは、REST API および GraphQL API の設計における
ベストプラクティスについて解説します。

## API設計の基本原則

クラウド環境での API 設計では、以下の原則を遵守してください。

### RESTful Design

REST API を設計する際は、HTTP メソッド (GET, POST, PUT, DELETE) を
適切に使用することが重要です。エンドポイントはリソースを表現し、
状態を持たない (stateless) 設計にしてください。

```json
{
  "endpoint": "/api/v1/users/{id}",
  "method": "GET",
  "response": {
    "id": "string",
    "name": "string"
  }
}
```

### 認証と認可

OAuth 2.0 または API Key による認証を実装してください。
Bearer token の有効期限は短く設定し、refresh token で
セッションを維持するパターンを推奨します。

## SDK との統合

クライアント SDK を提供する場合は、以下のプログラミング言語を
優先してください: TypeScript/JavaScript, Python, Go。

バージョニングは Semantic Versioning (SemVer) に従い、
CHANGELOG を必ず更新してください。

## まとめ

適切な API 設計は、開発者体験 (DX) を大きく向上させます。
REST の原則と GraphQL の柔軟性をバランスよく活用することで、
スケーラブルなクラウドシステムを構築できます。
