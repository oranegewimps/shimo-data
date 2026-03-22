# 予実管理ダッシュボード

## 概要
中小企業の部門別・月次予実管理ダッシュボード。
経営層が予算vs実績を一目で把握し、意思決定できることを目的として設計。

## 技術スタック
- DuckDB（データ加工・集計）
- SQL（予実比較・前月比・累計）
- Looker Studio（可視化）

## データ
架空の中小企業データ（自作）
- budget.csv：部門別・月別予算
- actual.csv：部門別・月別実績

## SQLの構成
- 01_budget_vs_actual.sql：予実比較
- 02_achievement_rate.sql：達成率・ステータス
- 03_mom_comparison.sql：前月比
- 04_cumulative.sql：累計
- 05_department_ranking.sql：部門別ランキング

## ダッシュボードURL
[予実管理ダッシュボード（Looker Studio）](https://lookerstudio.google.com/reporting/39934e43-4a91-49ec-bde1-0b567c151398)

## このダッシュボードで何を意思決定できるか
- 全社・部門別の予算達成状況を一目で把握できる
- 月次推移から売上のトレンドを読み取れる
- 予算比率100.2%により、全社として予算をわずかに上回っていることが確認できる
- 部門別の棒グラフから、どの部門が牽引しているか・課題があるかを特定できる

## 前職との関連
前職の会計・戦略部門で経営会議向けに実際に作成していた
予実管理レポートをDuckDB・SQL・Looker Studioで再現したもの。