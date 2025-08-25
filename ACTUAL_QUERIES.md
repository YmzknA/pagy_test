# 実際に発行されるSQLクエリ - Docker実測結果

このドキュメントは、Dockerコンテナ内でRailsコンソールを使用して実際にテストした結果に基づいています。

## テスト環境
- Docker Compose環境
- Rails 7.2.2.2
- PostgreSQL
- 記事データ: 63,655件

## 1. Pagy Standard

### 実行コード
```ruby
pagy_obj, articles = pagy(Article.order(:id), items: 25, page: 1)
articles.to_a
```

### 実際の発行クエリ
```sql
-- 1. pagy() 呼び出し時 (即座実行)
SELECT COUNT(*) FROM "articles"
-- 実行時間: 16.6ms

-- 2. articles.to_a 呼び出し時
SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT 25 OFFSET 0
-- 実行時間: 1.6ms
```

### 特徴
- **COUNTクエリが先に実行される** (pagy呼び出し時)
- データ取得は遅延実行
- 総件数: 63,655件 → 2,547ページ

## 2. Pagy Countless

### 実行コード
```ruby
pagy_obj, articles = pagy_countless(Article.order(:id), items: 25, page: 1)
articles.to_a
```

### 実際の発行クエリ
```sql
-- 1. pagy_countless() 呼び出し時 (即座実行)
SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT 26 OFFSET 0
-- 実行時間: 1.2ms

-- 2. articles.to_a 呼び出し時
-- クエリ実行されない (既に実行済み)
```

### 特徴
- **単一クエリのみ** (COUNTなし)
- **LIMIT +1** で次ページの有無を判定
- pagy_countless呼び出し時に即座実行

## 3. Kaminari Standard

### 実行コード
```ruby
articles = Article.order(:id).page(1).per(25)
articles.to_a
articles.total_count
```

### 実際の発行クエリ
```sql
-- 1. Article.page(1).per(25) 呼び出し時
SELECT "articles".* FROM "articles" /* loading for pp */ ORDER BY "articles"."id" ASC LIMIT 11 OFFSET 0
-- 実行時間: 0.6ms (プレビュー用？)

-- 2. articles.to_a 呼び出し時
SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT 25 OFFSET 0  
-- 実行時間: 1.6ms

-- 3. articles.total_count 呼び出し時
SELECT COUNT(*) FROM (SELECT 1 AS one FROM "articles" LIMIT 25000) subquery_for_count
-- 実行時間: 5.4ms
```

### 特徴
- **3つのクエリが実行される**
- COUNTクエリは最後（total_count呼び出し時）
- subqueryによるCOUNT最適化
- 総件数: 25,000件（LIMIT適用）

## 4. Kaminari without_count

### 実行コード  
```ruby
articles = Article.order(:id).page(1).per(25).without_count
articles.to_a
```

### 実際の発行クエリ
```sql
-- 1. Article.page(1).per(25).without_count 呼び出し時
SELECT "articles".* FROM "articles" /* loading for pp */ ORDER BY "articles"."id" ASC LIMIT 12 OFFSET 0
-- 実行時間: 1.1ms

-- 2. articles.to_a 呼び出し時
SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT 26 OFFSET 0
-- 実行時間: 0.6ms
```

### 特徴
- **COUNTクエリなし**
- 2つのSELECTクエリ
- LIMIT 26 で次ページ有無を判定

## パフォーマンス比較サマリー

| 手法 | クエリ数 | COUNT有無 | 即座実行 | 遅延実行 |
|------|----------|-----------|----------|----------|
| Pagy Standard | 2 | ✅ | COUNT | SELECT |
| Pagy Countless | 1 | ❌ | SELECT(+1) | なし |
| Kaminari Standard | 3 | ✅ | Preview+SELECT | COUNT |
| Kaminari without_count | 2 | ❌ | Preview+SELECT | なし |

## 重要な発見

1. **Pagy Countlessが最も効率的**: 1クエリのみで即座実行
2. **Kaminariには「プレビュー」クエリが存在**: 用途不明の小さなLIMITクエリ  
3. **COUNTクエリのタイミングが異なる**: 
   - Pagy: 先にCOUNT
   - Kaminari: 後でCOUNT（必要時のみ）
4. **without_count版でもクエリ数に差**: 
   - Pagy: 1クエリ
   - Kaminari: 2クエリ（プレビュー含む）

## テスト日時
2025年8月25日 17:07 (Docker実測)