-----
-- DBバージョン:2 のマイグレーションファイル

-- 現在のバージョンを挿入する
INSERT INTO version(version) VALUES(2);

-----
-- 自動売買プログラム(bot)を管理するテーブル
CREATE TABLE IF NOT EXISTS bot(
  id            INTEGER   PRIMARY KEY,                        -- botID
  name          TEXT      NOT NULL,                           -- bot名
  description   TEXT      NOT NULL,                           -- botの説明文
  enable        BOOLEAN   NOT NULL CHECK(enable in (0, 1)),   -- botが有効かどうか
  registered    TIMESTAMP NOT NULL,                           -- 登録日時
  token         TEXT      NOT NULL CHECK(length(token) = 32), -- アクセス用トークン

  -- ロング注文可能かどうか
  long_order    BOOLEAN   NOT NULL DEFAULT 1 CHECK(enable in (0, 1)),

  -- ショート注文可能かどうか
  short_order   BOOLEAN   NOT NULL DEFAULT 0 CHECK(enable in (0, 1)),

  -- 運用段階(バックテスト、フォワードテスト、実運用)
  operate_type  TEXT      NOT NULL DEFAULT 'backtest' CHECK(operate_type in ('backtest', 'forwardtest', 'product')),

  unique(id)
);
