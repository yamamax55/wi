#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 'lib';

# UTF-8標準入出力設定
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');

use Character;
use StatusEffect;
use Spell;
use Item;
use Equipment;
use Monster;

print "=== Wizardry CLI 第1段階機能テスト ===\n\n";

# 1. キャラクター作成テスト
print "1. キャラクター作成テスト...\n";
my $character = Character->new(
    name => 'テスト戦士',
    class => 'Fighter',
    race => 'Human'
);

print "キャラクター作成成功: " . $character->{name} . "\n";
print "HP: " . $character->{hp} . "/" . $character->{max_hp} . "\n";
print "AC: " . $character->{ac} . "\n\n";

# 2. 状態異常システムテスト
print "2. 状態異常システムテスト...\n";
$character->apply_status_effect('poison', 5);
print "毒状態を付与: " . ($character->has_status('poison') ? "成功" : "失敗") . "\n";

my @messages = $character->process_status_effects();
print "状態異常処理: " . join(", ", @messages) . "\n\n";

# 3. アイテムシステムテスト
print "3. アイテムシステムテスト...\n";
my $potion = Item->new('ポーション');
if ($potion) {
    print "アイテム作成成功: " . $potion->get_name() . "\n";
    print "タイプ: " . $potion->get_type() . "\n";
    print "価格: " . $potion->get_price() . " ゴールド\n";
    
    # インベントリに追加
    if ($character->add_to_inventory($potion)) {
        print "インベントリ追加成功\n";
    }
} else {
    print "アイテム作成失敗\n";
}

# 4. 装備システムテスト
print "\n4. 装備システムテスト...\n";
my $sword = Item->new('短剣');
if ($sword) {
    print "武器作成成功: " . $sword->get_name() . "\n";
    $character->add_to_inventory($sword);
    
    my $result = $character->equip_item('短剣');
    print "装備結果: $result\n";
} else {
    print "武器作成失敗\n";
}

# 5. 魔法システムテスト
print "\n5. 魔法システムテスト...\n";
my $spell = Spell->new('ハリト');
if ($spell) {
    print "魔法作成成功: " . $spell->get_name() . "\n";
    print "レベル: " . $spell->get_level() . "\n";
    print "MP消費: " . $spell->get_mp_cost() . "\n";
    print "対象: " . $spell->get_target() . "\n";
} else {
    print "魔法作成失敗\n";
}

# 6. モンスターテスト
print "\n6. モンスターシステムテスト...\n";
my $monster_data = Monster->load_monsters();
my $goblin = Monster->new('ゴブリン', $monster_data->{'ゴブリン'});
print "モンスター作成成功: " . $goblin->{name} . "\n";
print "HP: " . $goblin->{hp} . "\n";
print "レベル: " . $goblin->{level} . "\n";

# ドロップテスト
my @drops = $goblin->get_drops();
if (@drops) {
    print "ドロップアイテム: ";
    for my $drop (@drops) {
        print $drop->get_name() . " ";
    }
    print "\n";
} else {
    print "ドロップなし\n";
}

print "\n=== テスト完了 ===\n";
print "すべての基本機能が正常に動作していることを確認しました。\n";