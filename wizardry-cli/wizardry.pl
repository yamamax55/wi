#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use Encode qw(decode_utf8);
use Term::ANSIColor;

# UTF-8標準入出力設定
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');

# モジュールの読み込み
use Character;
use Monster;
use Battle;
use Dungeon;
use SaveData;

# ゲーム状態
my $party = [];
my $dungeon;
my $save_data = SaveData->new();
my $game_running = 1;

# メイン関数
sub main {
    print_title();
    
    while ($game_running) {
        if (@$party == 0) {
            party_creation_menu();
        } else {
            main_menu();
        }
    }
    
    print "ゲームを終了します。\n";
}

sub print_title {
    print "\n";
    print colored("=" x 60, 'bold yellow') . "\n";
    print colored("             WIZARDRY風 CLI RPG", 'bold cyan') . "\n";
    print colored("               〜 ダンジョン探索 〜", 'bold cyan') . "\n";
    print colored("=" x 60, 'bold yellow') . "\n";
    print "\n";
}

sub party_creation_menu {
    print "\n=== パーティ作成 ===\n";
    print "1. 新しいパーティを作成\n";
    print "2. セーブデータをロード\n";
    print "3. ゲーム終了\n";
    print "選択 > ";
    
    chomp(my $choice = <STDIN>);
    
    if ($choice eq '1') {
        create_new_party();
    } elsif ($choice eq '2') {
        load_game_menu();
    } elsif ($choice eq '3') {
        $game_running = 0;
    } else {
        print "無効な選択です。\n";
    }
}

sub create_new_party {
    print "\nパーティメンバーを作成します（最大4人）\n";
    
    for my $i (1..4) {
        print "\n--- " . $i . "人目のキャラクター ---\n";
        print "作成しますか？ (y/n): ";
        chomp(my $create = <STDIN>);
        
        if ($create =~ /^y/i) {
            my $character = Character->new();
            $character->create_character();
            
            # 隊列決定
            if (@$party < 2) {
                $character->{position} = 'front';
            } else {
                $character->{position} = 'back';
            }
            
            push @$party, $character;
        }
        
        last if @$party == 0 && $i == 1;  # 1人目を作成しない場合は終了
    }
    
    if (@$party > 0) {
        print "\nパーティが完成しました！\n";
        $dungeon = Dungeon->new(20, 20);
        display_party();
    } else {
        print "パーティが作成されませんでした。\n";
    }
}

sub main_menu {
    print "\n=== メインメニュー ===\n";
    print "1. ダンジョン探索\n";
    print "2. ステータス確認\n";
    print "3. 装備管理\n";
    print "4. アイテム管理\n";
    print "5. セーブ\n";
    print "6. ロード\n";
    print "7. 設定\n";
    print "8. ゲーム終了\n";
    print "選択 > ";
    
    chomp(my $choice = <STDIN>);
    
    if ($choice eq '1') {
        explore_dungeon();
    } elsif ($choice eq '2') {
        display_party();
        print "\nEnterキーで戻る...";
        <STDIN>;
    } elsif ($choice eq '3') {
        equipment_menu();
    } elsif ($choice eq '4') {
        item_menu();
    } elsif ($choice eq '5') {
        save_game_menu();
    } elsif ($choice eq '6') {
        load_game_menu();
    } elsif ($choice eq '7') {
        settings_menu();
    } elsif ($choice eq '8') {
        $game_running = 0;
    } else {
        print "無効な選択です。\n";
    }
}

sub explore_dungeon {
    unless ($dungeon) {
        $dungeon = Dungeon->new(20, 20);
    }
    
    my $exploring = 1;
    
    while ($exploring && party_alive()) {
        $dungeon->display();
        
        print "\nコマンド (w/a/s/d=移動, m=メニュー, q=戻る): ";
        chomp(my $command = <STDIN>);
        
        if ($command =~ /^[wasd]$/) {
            my $result = $dungeon->move_player($command);
            
            if ($result eq 'encounter') {
                my $monsters = Monster->create_encounter($dungeon->get_current_floor());
                if (@$monsters) {
                    my $battle = Battle->new($party, $monsters);
                    $battle->start_battle();
                    
                    unless (party_alive()) {
                        print "パーティが全滅しました...\n";
                        reset_game();
                        return;
                    }
                }
            } elsif ($result eq 'stairs_up') {
                print "上の階に行きますか？ (y/n): ";
                chomp(my $go_up = <STDIN>);
                if ($go_up =~ /^y/i) {
                    $dungeon->change_floor('up');
                }
            } elsif ($result eq 'stairs_down') {
                print "下の階に行きますか？ (y/n): ";
                chomp(my $go_down = <STDIN>);
                if ($go_down =~ /^y/i) {
                    $dungeon->change_floor('down');
                }
            }
            
        } elsif ($command eq 'm') {
            dungeon_menu();
        } elsif ($command eq 'q') {
            $exploring = 0;
        } else {
            print "無効なコマンドです。\n";
        }
    }
}

sub dungeon_menu {
    print "\n=== ダンジョンメニュー ===\n";
    print "1. ステータス確認\n";
    print "2. セーブ\n";
    print "3. 街に戻る\n";
    print "4. 探索を続ける\n";
    print "選択 > ";
    
    chomp(my $choice = <STDIN>);
    
    if ($choice eq '1') {
        display_party();
        print "\nEnterキーで戻る...";
        <STDIN>;
    } elsif ($choice eq '2') {
        save_game_menu();
    } elsif ($choice eq '3') {
        print "街に戻りました。\n";
        return 'town';
    }
    # その他の場合は探索を続ける
}

sub save_game_menu {
    print "\nセーブファイル名を入力してください: ";
    chomp(my $filename = <STDIN>);
    
    if ($filename) {
        my $game_data = {
            party => $party,
            dungeon => $dungeon,
            version => "1.0"
        };
        
        $save_data->save_game($filename, $game_data);
    } else {
        print "セーブをキャンセルしました。\n";
    }
}

sub load_game_menu {
    my $saves = $save_data->list_saves();
    
    return unless @$saves;
    
    print "ロードするファイルを選択してください (0=キャンセル): ";
    chomp(my $choice = <STDIN>);
    
    if ($choice > 0 && $choice <= @$saves) {
        my $filename = $saves->[$choice - 1];
        $filename =~ s/\.json$//;
        
        my $game_data = $save_data->load_game($filename);
        
        if ($game_data) {
            $party = $game_data->{party};
            $dungeon = $game_data->{dungeon};
            
            # オブジェクトの再blessing
            for my $char (@$party) {
                bless $char, 'Character';
            }
            
            if ($dungeon) {
                bless $dungeon, 'Dungeon';
            }
            
            print "ゲームをロードしました。\n";
        }
    }
}

sub settings_menu {
    print "\n=== 設定 ===\n";
    print "1. パーティ情報をJSONで出力\n";
    print "2. オートセーブ実行\n";
    print "3. セーブファイル管理\n";
    print "4. 戻る\n";
    print "選択 > ";
    
    chomp(my $choice = <STDIN>);
    
    if ($choice eq '1') {
        print "出力ファイル名を入力: ";
        chomp(my $filename = <STDIN>);
        $save_data->export_character_json($filename, $party) if $filename;
    } elsif ($choice eq '2') {
        my $game_data = {
            party => $party,
            dungeon => $dungeon,
            version => "1.0"
        };
        $save_data->create_backup($game_data);
    } elsif ($choice eq '3') {
        save_management_menu();
    }
}

sub save_management_menu {
    while (1) {
        my $saves = $save_data->list_saves();
        
        print "\n=== セーブファイル管理 ===\n";
        print "1. セーブファイル情報表示\n";
        print "2. セーブファイル削除\n";
        print "3. 戻る\n";
        print "選択 > ";
        
        chomp(my $choice = <STDIN>);
        
        if ($choice eq '1') {
            return unless @$saves;
            print "情報を表示するファイルを選択: ";
            chomp(my $file_choice = <STDIN>);
            
            if ($file_choice > 0 && $file_choice <= @$saves) {
                my $filename = $saves->[$file_choice - 1];
                $filename =~ s/\.json$//;
                my $info = $save_data->get_save_info($filename);
                
                if ($info) {
                    print "\nファイル名: " . $info->{filename} . "\n";
                    print "サイズ: " . $info->{size} . " bytes\n";
                    print "最終更新: " . $info->{last_modified} . "\n";
                }
            }
        } elsif ($choice eq '2') {
            return unless @$saves;
            print "削除するファイルを選択: ";
            chomp(my $file_choice = <STDIN>);
            
            if ($file_choice > 0 && $file_choice <= @$saves) {
                my $filename = $saves->[$file_choice - 1];
                $filename =~ s/\.json$//;
                
                print "本当に削除しますか？ (y/n): ";
                chomp(my $confirm = <STDIN>);
                if ($confirm =~ /^y/i) {
                    $save_data->delete_save($filename);
                }
            }
        } elsif ($choice eq '3') {
            last;
        }
    }
}

sub display_party {
    print "\n=== パーティステータス ===\n";
    
    for my $i (0..@$party-1) {
        my $char = $party->[$i];
        print "\n" . ($i + 1) . ". ";
        $char->display_status();
    }
}

sub party_alive {
    return grep { $_->is_alive() } @$party;
}

sub reset_game {
    $party = [];
    $dungeon = undef;
    print "ゲームをリセットしました。\n";
}

# エラーハンドリング
$SIG{__DIE__} = sub {
    my $error = shift;
    print colored("エラーが発生しました: $error", 'bold red') . "\n";
    print "ゲームを安全に終了します。\n";
    exit 1;
};

sub equipment_menu {
    while (1) {
        print "\n=== 装備管理 ===\n";
        print "キャラクターを選択してください:\n";
        
        for my $i (0..$#{$party}) {
            my $char = $party->[$i];
            print ($i + 1) . ". " . $char->{name} . " (" . $char->{class} . ")\n";
        }
        print "0. 戻る\n";
        print "選択 > ";
        
        chomp(my $choice = <STDIN>);
        
        if ($choice eq '0') {
            return;
        } elsif ($choice > 0 && $choice <= @$party) {
            character_equipment_menu($party->[$choice - 1]);
        } else {
            print "無効な選択です。\n";
        }
    }
}

sub character_equipment_menu {
    my $char = shift;
    
    while (1) {
        print "\n=== " . $char->{name} . " の装備管理 ===\n";
        $char->{equipment_manager}->display_equipment();
        
        print "\n1. 装備する\n";
        print "2. 装備を外す\n";
        print "3. インベントリ表示\n";
        print "0. 戻る\n";
        print "選択 > ";
        
        chomp(my $choice = <STDIN>);
        
        if ($choice eq '0') {
            return;
        } elsif ($choice eq '1') {
            equip_item_menu($char);
        } elsif ($choice eq '2') {
            unequip_item_menu($char);
        } elsif ($choice eq '3') {
            $char->display_inventory();
            print "\nEnterキーで戻る...";
            <STDIN>;
        } else {
            print "無効な選択です。\n";
        }
    }
}

sub equip_item_menu {
    my $char = shift;
    
    $char->display_inventory();
    
    if (@{$char->{inventory}} == 0) {
        print "装備できるアイテムがありません。\n";
        print "\nEnterキーで戻る...";
        <STDIN>;
        return;
    }
    
    print "\n装備するアイテムの番号を選択 (0=戻る): ";
    chomp(my $choice = <STDIN>);
    
    if ($choice > 0 && $choice <= @{$char->{inventory}}) {
        my $item = $char->{inventory}->[$choice - 1];
        my $result = $char->equip_item($item->get_name());
        print $result . "\n";
        print "\nEnterキーで戻る...";
        <STDIN>;
    }
}

sub unequip_item_menu {
    my $char = shift;
    
    print "\n外す装備を選択してください:\n";
    print "1. 武器\n";
    print "2. 鎧\n";
    print "3. 盾\n";
    print "4. 兜\n";
    print "5. 装飾品\n";
    print "0. 戻る\n";
    print "選択 > ";
    
    chomp(my $choice = <STDIN>);
    
    my %slot_map = (
        '1' => 'weapon',
        '2' => 'armor',
        '3' => 'shield',
        '4' => 'helmet',
        '5' => 'accessory'
    );
    
    if ($choice eq '0') {
        return;
    } elsif (exists $slot_map{$choice}) {
        my $result = $char->unequip_item($slot_map{$choice});
        print $result . "\n";
        print "\nEnterキーで戻る...";
        <STDIN>;
    } else {
        print "無効な選択です。\n";
    }
}

sub item_menu {
    while (1) {
        print "\n=== アイテム管理 ===\n";
        print "キャラクターを選択してください:\n";
        
        for my $i (0..$#{$party}) {
            my $char = $party->[$i];
            print ($i + 1) . ". " . $char->{name} . " (" . $char->{class} . ")\n";
        }
        print "0. 戻る\n";
        print "選択 > ";
        
        chomp(my $choice = <STDIN>);
        
        if ($choice eq '0') {
            return;
        } elsif ($choice > 0 && $choice <= @$party) {
            character_item_menu($party->[$choice - 1]);
        } else {
            print "無効な選択です。\n";
        }
    }
}

sub character_item_menu {
    my $char = shift;
    
    while (1) {
        print "\n=== " . $char->{name} . " のアイテム管理 ===\n";
        $char->display_inventory();
        
        print "\n1. アイテムを使用\n";
        print "2. アイテム詳細表示\n";
        print "0. 戻る\n";
        print "選択 > ";
        
        chomp(my $choice = <STDIN>);
        
        if ($choice eq '0') {
            return;
        } elsif ($choice eq '1') {
            use_item_menu($char);
        } elsif ($choice eq '2') {
            item_details_menu($char);
        } else {
            print "無効な選択です。\n";
        }
    }
}

sub use_item_menu {
    my $char = shift;
    
    if (@{$char->{inventory}} == 0) {
        print "使用できるアイテムがありません。\n";
        print "\nEnterキーで戻る...";
        <STDIN>;
        return;
    }
    
    print "\n使用するアイテムの番号を選択 (0=戻る): ";
    chomp(my $choice = <STDIN>);
    
    if ($choice > 0 && $choice <= @{$char->{inventory}}) {
        my $item = $char->{inventory}->[$choice - 1];
        
        if ($item->is_consumable()) {
            my $result = $char->use_item($item->get_name());
            print $result . "\n";
        } else {
            print "そのアイテムは使用できません。\n";
        }
        
        print "\nEnterキーで戻る...";
        <STDIN>;
    }
}

sub item_details_menu {
    my $char = shift;
    
    if (@{$char->{inventory}} == 0) {
        print "アイテムがありません。\n";
        print "\nEnterキーで戻る...";
        <STDIN>;
        return;
    }
    
    print "\n詳細を表示するアイテムの番号を選択 (0=戻る): ";
    chomp(my $choice = <STDIN>);
    
    if ($choice > 0 && $choice <= @{$char->{inventory}}) {
        my $item = $char->{inventory}->[$choice - 1];
        
        print "\n=== " . $item->get_name() . " の詳細 ===\n";
        print "種類: " . $item->get_type() . "\n";
        print "価格: " . $item->get_price() . " ゴールド\n";
        print "重量: " . $item->get_weight() . "\n";
        print "説明: " . $item->get_description() . "\n";
        
        if ($item->is_weapon()) {
            print "ダメージ: " . $item->get_damage() . "\n";
            print "命中修正: " . $item->get_hit_bonus() . "\n";
        } elsif ($item->is_armor()) {
            print "AC修正: +" . $item->get_ac_bonus() . "\n";
        }
        
        if (my $special = $item->get_special()) {
            print "特殊効果: " . $special . "\n";
        }
        
        print "\nEnterキーで戻る...";
        <STDIN>;
    }
}

# メイン実行
if ($0 eq __FILE__) {
    main();
}

1;