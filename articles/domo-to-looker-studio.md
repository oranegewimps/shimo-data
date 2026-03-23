---
title: "DOMOユーザーがLooker Studioで予実管理ダッシュボードを作ってみた"
emoji: "📊"
type: "tech"
topics: ["SQL", "LookerStudio", "DuckDB", "analytics", "DOMO"]
published: true
---

## はじめに

前職で会計・戦略部門に2年間在籍し、BIツール「DOMO」を使って経営会議向けの予実管理レポートを作成していました。

フリーランスのアナリティクスエンジニアを目指して学習を開始して約1週間。DOMOは個人利用ができないためポートフォリオに使えません。そこで前職で作っていた予実管理ダッシュボードをDuckDB・SQL・Looker Studioで再現しました。

## 作ったもの

- [Looker Studio ダッシュボード](https://lookerstudio.google.com/reporting/39934e43-4a91-49ec-bde1-0b567c151398)
- [GitHub リポジトリ](https://github.com/oranegewimps/shimo-data)

## 技術スタック

- DuckDB（ローカル環境でのデータ加工・SQL実行）
- SQL（予実比較・達成率・前月比・累計・部門別ランキング）
- Looker Studio（可視化・ダッシュボード）
- Google スプレッドシート（データソース）

## やったこと

架空の中小企業データ（部門別・月別の予算と実績）を自作し、以下のSQLを実装しました。

- 予実比較：budgetとactualをJOINして並べる
- 達成率・ステータス：CASE WHENで達成・惜しい・未達を判定
- 前月比：LAGで前月実績を取得してMoMを計算
- 累計：ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROWで積み上げ
- 部門別ランキング：RANKで達成率順に並べる

## 詰まったポイント

**Looker Studioのブレンド設定**
budgetとactualが別シートにあるため、ブレンド機能でJOINする必要がありました。結合キーをyear_monthとdeptの2つに設定することで正しく紐付けられました。

**ラベルの日本語化**
デフォルトでは英語表記（budget・actual）になるため、指標名を予算・実績に変更しました。

## おわりに

学習開始から約1週間でここまで作れました。次はdbtを使ってデータ基盤を構築するポートフォリオに挑戦します。

フリーランスAEを目指して引き続き発信していきます。