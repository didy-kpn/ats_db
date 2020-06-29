-----
-- DBバージョン:1 のロールバックファイル

-----
-- マーケットデータ格納テーブルを削除する
DROP TABLE ohlc;

-- バージョン情報を削除する
DELETE FROM version WHERE version = 1;
