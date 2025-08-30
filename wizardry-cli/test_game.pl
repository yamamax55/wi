#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 'lib';

binmode(STDOUT, ':encoding(utf8)');

use Character;
use Monster;
use Battle;
use Dungeon;
use SaveData;

print "=== Wizardry風CLIゲーム テスト ===\n\n";

# 1. キャラクター作成テスト
print "1. キャラクター作成テスト\n";
my $char = Character->new();
$char->{name} = "テスト戦士";
$char->{class} = "戦士";
$char->{race} = "人間";
$char->{alignment} = "善";
$char->generate_stats();
$char->calculate_hp_mp();

print "キャラクター作成完了:\n";
$char->display_status();

# 2. モンスター作成テスト
print "\n2. モンスター作成テスト\n";
my $monsters = Monster->create_encounter(1);
print "1階でのエンカウンター:\n";
for my $monster (@$monsters) {
    print "- " . $monster->{name} . " (HP: " . $monster->{hp} . ", STR: " . $monster->{str} . ")\n";
}

# 3. ダンジョン生成テスト
print "\n3. ダンジョン生成テスト\n";
my $dungeon = Dungeon->new(10, 10);
print "10x10のダンジョンを生成しました。\n";
print "部屋数: " . scalar(@{$dungeon->{rooms}}) . "\n";
print "プレイヤー位置: (" . $dungeon->{player_x} . ", " . $dungeon->{player_y} . ")\n";

# 4. セーブデータテスト
print "\n4. セーブ/ロードテスト\n";
my $save_data = SaveData->new();
my $test_data = {
    test => "テストデータ",
    timestamp => time()
};

if ($save_data->save_game("test_save", $test_data)) {
    print "セーブ成功\n";
    
    my $loaded_data = $save_data->load_game("test_save");
    if ($loaded_data && $loaded_data->{test} eq "テストデータ") {
        print "ロード成功 - データ確認OK\n";
    } else {
        print "ロード失敗またはデータ不一致\n";
    }
} else {
    print "セーブ失敗\n";
}

print "\n=== テスト完了 ===\n";
print "ゲームを開始するには: perl wizardry.pl\n";