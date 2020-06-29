#!/usr/bin/perl

use strict;
use warnings;
use utf8;

# DB名
use constant DB_NAME => "auto_trading_system.db";

# DBバージョン
use constant DB_VERSION => 1;

# SQLファイル名
use constant DIR_SQL => "sql";
use constant TEMPLATE_MIGRATION_FILE_NAME => DIR_SQL."/up_%03d.sql";
use constant TEMPLATE_ROLLBACK_SQL_FILE_NAME  => DIR_SQL."/down_%03d.sql";

use Getopt::Long;

# コマンドライン引数を取得する
my $command = shift @ARGV if(@ARGV);

# オプションパラメータを取得する
my $options = {};
my $result = GetOptions($options, "version=i");

# 使用方法
sub usage {
  print << "USAGE";
db-setup-tool

  $0 [command] [options]
    command: [migration|rollback|check]
    options: --version [int]
USAGE
}

# コマンド文字列が指定されていない場合は正常終了
unless ($command) {
  usage();
  exit 0;
}

# 指定されたSQL(ファイル)を実行する
sub run_sql {
  my $sql_obj = shift;
  die unless(ref $sql_obj eq 'HASH' and (exists $sql_obj->{str} or exists $sql_obj->{file}));

  my $sql_option = undef;

  # SQL文字列
  if (exists $sql_obj->{str} and defined $sql_obj->{str}) {
    $sql_option = "\"$sql_obj->{str}\"";
  # SQLファイル
  } elsif (exists $sql_obj->{file} and defined $sql_obj->{file}) {
    $sql_option = "< $sql_obj->{file}";
  } else {
    die;
  }

  # SQLを実行する
  my $cmd = 'sqlite3 '.DB_NAME.' '.$sql_option;
  my $output = `$cmd`;

  # 実行結果を返す
  return ($cmd, $output, $?);
}


sub _msg {
  my $msg = shift;
  print $msg."\n";
}

sub error_msg {
  _msg("[ERROR] ".shift);
}

sub info_msg {
  _msg("[INFO] ".shift);
}

sub debug_msg {
  _msg("[DEBUG] ".shift);
}

# 最新バージョンをDBから取得し返す
sub _get_last_version {
  # dbがある場合、最新バージョン情報を取得
  my ($cmd, $ver, $ret) = run_sql({ str => "select version from version order by version desc limit 1;" });
  if ($ret) {
    error_msg("fail - version:$_\n - $cmd");
    die;
  }
  info_msg("installed - version:$_") for ((0..$ver));
  return $ver + 0;
}

sub _migration {
  eval {
    # バージョンオプションが指定されていて、0以下ならエラー
    if (exists($options->{version}) and defined($options->{version}) and $options->{version} <= 0) {
      error_msg("version must be one or more");
      die;
    }

    my $target_version = $options->{version} // DB_VERSION;

    # 最初にインストールするバージョン情報
    my $last_version = (-f DB_NAME) ? _get_last_version() + 1: 0;

    # 順番に環境をセットアップ(マイグレーション)する
    for (($last_version..$target_version)) {

      # マイグレーションファイル
      my $migration_file_name = sprintf( TEMPLATE_MIGRATION_FILE_NAME, $_ );

      # バージョン方法とマイグレーションファイル名
      my $output_msg = " - version:$_ - $migration_file_name";

      # マイグレーションファイルがない場合は終了する
      unless (-f $migration_file_name) {
        error_msg("fail".$output_msg);
        die;
      }

      # マイグレーションを実行する
      my ($cmd, $ver, $ret) = run_sql({ file => $migration_file_name });

      # 実行にした場合は終了する
      if ($ret) {
        error_msg("fail".$output_msg);
        die;
      }

      # 実行が正常した次へ
      info_msg("done".$output_msg);
    }
  };
  return 1 if($@);
  return 0;
}

sub _rollback {
  eval {
    # バージョンオプションが無指定などの場合はエラー
    unless(exists($options->{version}) and defined($options->{version})) {
      error_msg("version is not exists");
      die;
    }

    # 指定されたバージョンが0以下ならエラー
    unless(0 < $options->{version}) {
      error_msg("version must be one or more");
      die;
    }
    my $target_version = $options->{version};

    # 最初にインストールするバージョン情報
    my $last_version = (-f DB_NAME) ? _get_last_version() : 0;

    # 取得したバージョン情報が、指定されたバージョンより小さい場合はエラー
    unless( $target_version <= $last_version ) {
      error_msg("fail - db.version = ".$last_version.", options.version = ".$target_version);
      die;
    }

    # 順番に環境をセットアップ(ロールバック)する
    for (reverse($target_version..$last_version)) {

      # ロールバックファイル
      my $rollback_file_name = sprintf( TEMPLATE_ROLLBACK_SQL_FILE_NAME, $_ );

      # バージョン方法とロールバックファイル名
      my $output_msg = " - version:$_ - $rollback_file_name";

      # ロールバックファイルがない場合は終了する
      unless (-f $rollback_file_name) {
        error_msg("fail".$output_msg);
        die;
      }

      # ロールバックを実行する
      my ($cmd, $ver, $ret) = run_sql({ file => $rollback_file_name });

      # 実行にした場合は終了する
      if ($ret) {
        error_msg("fail".$output_msg);
        die;
      }

      # 実行が正常した次へ
      info_msg("done".$output_msg);
    }
  };
  return 1 if($@);
  return 0;
}

sub main {
  # マイグレーション
  if ($command eq 'migration') {
    return _migration();

  # ロールバック
  } elsif ($command eq 'rollback') {
    return _rollback();

  # テーブル構造のチェック
  } elsif ($command eq 'check') {
    return 0;

  # それ以外のコマンドの場合はエラー
  } else {
    error_msg("$command is not command");
    return 1;
  }
}

exit main();
