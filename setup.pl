#!/usr/bin/perl

use strict;
use warnings;
use utf8;

# DB名
use constant DB_NAME => "auto_trading_system.db";

# DBバージョン
use constant DB_VERSION => 0;

# SQLファイル名
use constant TEMPLATE_MIGRATION_FILE_NAME => "up_%03d.sql";
use constant TEMPLATE_DOWN_SQL_FILE_NAME  => "down_%03d.sql";


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


sub main {
  my $version = 0;

  eval {
    # dbがある場合、最新バージョン情報を取得
    if (-f DB_NAME) {
      my ($cmd, $ver, $ret) = run_sql({ str => "select version from version order by version desc limit 1;" });
      if ($ret) {
        error_msg("fail - version:$_\n - $cmd");
        die;
      }
      info_msg("already - version:$_") for ((0..$ver));
      $version = $ver + 1;
    }

    # 順番に環境をセットアップ(マイグレーション)する
    for (($version..DB_VERSION)) {

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

exit main();
