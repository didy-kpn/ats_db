-----
-- DBバージョン:1 のマイグレーションファイル

-- 現在のバージョンを挿入する
INSERT INTO version(version) VALUES(1);

-----
-- 取引所から取得したマーケットデータを格納するテーブル。
CREATE TABLE IF NOT EXISTS ohlc(
  id        INTEGER PRIMARY KEY, -- データID
  market    TEXT      NOT NULL,  -- 取得先の取引所
  pair      TEXT      NOT NULL,  -- 取引通貨
  periods   INTEGER   NOT NULL,  -- 足の期間
  open      INTEGER   NOT NULL,  -- 始値
  high      INTEGER   NOT NULL,  -- 高値
  low       INTEGER   NOT NULL,  -- 安値
  close     INTEGER   NOT NULL,  -- 終値
  volume    INTEGER   NOT NULL,  -- 出来高
  unixtime  TIMESTAMP NOT NULL   -- UNIX時間
);

-- INDEXを設定する
CREATE INDEX IF NOT EXISTS idx_market_unixtime ON ohlc(market, pair, periods, unixtime);
