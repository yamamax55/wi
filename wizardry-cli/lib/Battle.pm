package Battle;

use strict;
use warnings;
use utf8;
use lib 'lib';
use StatusEffect;
use Spell;
use Item;

sub new {
    my ($class, $party, $monsters) = @_;
    my $self = {
        party => $party,
        monsters => $monsters,
        round => 1,
        fleeing => 0
    };
    bless $self, $class;
    return $self;
}

sub start_battle {
    my $self = shift;
    
    print "\n" . "=" x 50 . "\n";
    print "*** 戦闘開始！ ***\n";
    $self->display_monsters();
    
    while ($self->battle_continues()) {
        print "\n--- ラウンド " . $self->{round} . " ---\n";
        
        # 状態異常の処理
        $self->process_status_effects();
        
        # プレイヤーターン
        $self->player_turn();
        last if $self->{fleeing} || !$self->monsters_alive();
        
        # モンスターターン
        $self->monster_turn();
        last if !$self->party_alive();
        
        $self->{round}++;
    }
    
    $self->end_battle();
}

sub display_monsters {
    my $self = shift;
    print "\n敵: ";
    my %monster_counts;
    for my $monster (@{$self->{monsters}}) {
        next unless $monster->is_alive();
        $monster_counts{$monster->{name}}++;
    }
    
    my @display;
    for my $name (keys %monster_counts) {
        if ($monster_counts{$name} > 1) {
            push @display, "$name x$monster_counts{$name}";
        } else {
            push @display, $name;
        }
    }
    print join(", ", @display) . "\n";
}

sub display_party_status {
    my $self = shift;
    
    print "\n";
    my (@front, @back);
    for my $char (@{$self->{party}}) {
        if ($char->{position} eq 'front') {
            push @front, $char;
        } else {
            push @back, $char;
        }
    }
    
    print "[前衛]\n";
    for my $i (0..$#front) {
        my $char = $front[$i];
        my $status = $char->is_alive() ? "" : " (死亡)";
        print(($i + 1) . ". " . $char->{name} . "  HP: " . $char->{hp} . "/" . $char->{max_hp} . 
              "  MP: " . $char->{mp} . "/" . $char->{max_mp} . $status . "\n");
    }
    
    if (@back) {
        print "\n[後衛]\n";
        my $start_num = @front + 1;
        for my $i (0..$#back) {
            my $char = $back[$i];
            my $status = $char->is_alive() ? "" : " (死亡)";
            print(($start_num + $i) . ". " . $char->{name} . "  HP: " . $char->{hp} . "/" . $char->{max_hp} . 
                  "  MP: " . $char->{mp} . "/" . $char->{max_mp} . $status . "\n");
        }
    }
}

sub player_turn {
    my $self = shift;
    
    for my $i (0..@{$self->{party}}-1) {
        my $char = $self->{party}->[$i];
        next unless $char->is_alive();
        
        # 行動不可状態のチェック
        if (!$char->can_act()) {
            print $char->{name} . " は行動できない！\n";
            $self->display_status_effects($char);
            next;
        }
        
        $self->display_party_status();
        
        print "\n" . $char->{name} . " のターン\n";
        print "1. 攻撃  2. 魔法  3. アイテム  4. 防御  5. 逃走\n";
        print "コマンド？ ";
        chomp(my $command = <STDIN>);
        
        if ($command eq '1') {
            $self->character_attack($char);
        } elsif ($command eq '2') {
            $self->character_spell($char);
        } elsif ($command eq '3') {
            $self->character_item($char);
        } elsif ($command eq '4') {
            print $char->{name} . " は身を守っている...\n";
            # 防御効果は次の被ダメージ時に適用
        } elsif ($command eq '5') {
            if (int(rand(3)) == 0) {  # 33%の確率で逃走成功
                print "パーティは戦闘から逃走した！\n";
                $self->{fleeing} = 1;
                return;
            } else {
                print "逃走に失敗した！\n";
            }
        } else {
            print "無効なコマンドです。攻撃します。\n";
            $self->character_attack($char);
        }
        
        last if !$self->monsters_alive();
    }
}

sub character_attack {
    my ($self, $char) = @_;
    
    my @alive_monsters = grep { $_->is_alive() } @{$self->{monsters}};
    return unless @alive_monsters;
    
    my $target = $alive_monsters[int(rand(@alive_monsters))];
    
    # 装備による攻撃力計算
    my $weapon_damage = 0;
    if ($char->{equipment_manager}) {
        $weapon_damage = $char->{equipment_manager}->calculate_total_damage($target->{ac});
    }
    
    if ($weapon_damage > 0) {
        print $char->{name} . " の攻撃！ " . $target->{name} . " に " . $weapon_damage . " のダメージ！\n";
        
        my $is_dead = $target->take_damage($weapon_damage);
        if ($is_dead) {
            print $target->{name} . " を倒した！\n";
            # ドロップアイテムの処理
            $self->handle_monster_drops($target);
        }
    } else {
        print $char->{name} . " の攻撃は外れた！\n";
    }
}

sub character_spell {
    my ($self, $char) = @_;
    
    if (!$char->can_cast_magic()) {
        print $char->{name} . " は魔法を使えない状態です！\n";
        $self->character_attack($char);
        return;
    }
    
    if (!@{$char->{known_spells}}) {
        print $char->{name} . " は魔法を知らない！\n";
        $self->character_attack($char);
        return;
    }
    
    if ($char->{mp} <= 0) {
        print $char->{name} . " のMPが足りない！\n";
        $self->character_attack($char);
        return;
    }
    
    print "使用する魔法:\n";
    my @castable_spells = ();
    
    for my $i (0..@{$char->{known_spells}}-1) {
        my $spell_name = $char->{known_spells}->[$i];
        if ($char->can_cast_spell($spell_name)) {
            push @castable_spells, $spell_name;
            print((scalar @castable_spells) . ". " . $spell_name . "\n");
        }
    }
    
    if (!@castable_spells) {
        print "使用可能な魔法がありません！\n";
        $self->character_attack($char);
        return;
    }
    
    print "選択 (0=キャンセル): ";
    chomp(my $spell_choice = <STDIN>);
    
    if ($spell_choice == 0 || $spell_choice > @castable_spells) {
        $self->character_attack($char);
        return;
    }
    
    my $spell_name = $castable_spells[$spell_choice - 1];
    $self->cast_spell_new($char, $spell_name);
}

sub cast_spell_new {
    my ($self, $caster, $spell_name) = @_;
    
    my $spell = Spell->new($spell_name);
    return unless $spell;
    
    print $caster->{name} . " は" . $spell_name . "を唱えた！\n";
    
    my @targets = $self->select_spell_targets($spell);
    return unless @targets;
    
    my @results = $caster->cast_spell($spell_name, \@targets);
    
    for my $result (@results) {
        print $result . "\n";
    }
    
    # 死亡したモンスターの処理
    for my $target (@targets) {
        if (ref($target) eq 'Monster' && !$target->is_alive()) {
            $self->handle_monster_drops($target);
        }
    }
}

sub monster_turn {
    my $self = shift;
    
    print "\n--- モンスターのターン ---\n";
    
    for my $monster (@{$self->{monsters}}) {
        next unless $monster->is_alive();
        
        my @alive_party = grep { $_->is_alive() } @{$self->{party}};
        last unless @alive_party;
        
        # 行動不可状態チェック
        if (!$monster->can_act()) {
            print $monster->{name} . " は行動できない！\n";
            next;
        }
        
        # 特殊攻撃を試行
        if ($monster->special_attack(\@alive_party)) {
            next;
        }
        
        # 通常攻撃
        my @front_line = grep { $_->{position} eq 'front' && $_->is_alive() } @{$self->{party}};
        my @targets = @front_line ? @front_line : @alive_party;
        
        if (@targets) {
            my $target = $targets[int(rand(@targets))];
            $monster->attack($target);
            
            if (!$target->is_alive()) {
                print $target->{name} . " は倒れた...\n";
            }
        }
    }
}

sub battle_continues {
    my $self = shift;
    return $self->party_alive() && $self->monsters_alive() && !$self->{fleeing};
}

sub party_alive {
    my $self = shift;
    return grep { $_->is_alive() } @{$self->{party}};
}

sub monsters_alive {
    my $self = shift;
    return grep { $_->is_alive() } @{$self->{monsters}};
}

sub end_battle {
    my $self = shift;
    
    if ($self->{fleeing}) {
        return;
    }
    
    if ($self->party_alive() && !$self->monsters_alive()) {
        print "\n*** 勝利！ ***\n";
        
        my $total_exp = 0;
        my $total_gold = 0;
        
        for my $monster (@{$self->{monsters}}) {
            my $treasure = $monster->get_treasure();
            $total_exp += $treasure->{exp};
            $total_gold += $treasure->{gold};
            
            # ドロップアイテムの最終処理
            my @drops = $monster->get_drops();
            for my $drop (@drops) {
                print "" . $drop->get_name() . "を見つけた！\n";
                # パーティの誰かのインベントリに追加
                for my $char (@{$self->{party}}) {
                    if ($char->is_alive() && $char->can_add_to_inventory($drop)) {
                        $char->add_to_inventory($drop);
                        print $char->{name} . "が" . $drop->get_name() . "を拾った。\n";
                        last;
                    }
                }
            }
        }
        
        print "獲得経験値: " . $total_exp . "\n";
        print "獲得ゴールド: " . $total_gold . "\n";
        
        for my $char (@{$self->{party}}) {
            if ($char->is_alive()) {
                $char->gain_exp($total_exp);
            }
        }
        
    } elsif (!$self->party_alive()) {
        print "\n*** 全滅... ***\n";
        print "ゲームオーバー\n";
    }
    
    print "\n" . "=" x 50 . "\n";
}

sub process_status_effects {
    my $self = shift;
    
    print "\n--- 状態異常処理 ---\n";
    
    # パーティメンバーの状態異常処理
    for my $char (@{$self->{party}}) {
        next unless $char->is_alive();
        my @messages = $char->process_status_effects();
        for my $message (@messages) {
            print $message . "\n";
        }
    }
    
    # モンスターの状態異常処理
    for my $monster (@{$self->{monsters}}) {
        next unless $monster->is_alive();
        my @messages = $monster->process_status_effects();
        for my $message (@messages) {
            print $message . "\n";
        }
    }
}

sub display_status_effects {
    my ($self, $character) = @_;
    
    if (@{$character->{status_effects}}) {
        print $character->{name} . " の状態異常: ";
        my @status_names = map { $_->get_name() } @{$character->{status_effects}};
        print join(", ", @status_names) . "\n";
    }
}

sub character_item {
    my ($self, $char) = @_;
    
    $char->display_inventory();
    
    if (!@{$char->{inventory}}) {
        print "使用できるアイテムがありません。\n";
        $self->character_attack($char);
        return;
    }
    
    print "\n使用するアイテムの番号を入力 (0=キャンセル): ";
    chomp(my $choice = <STDIN>);
    
    if ($choice == 0 || $choice > @{$char->{inventory}}) {
        $self->character_attack($char);
        return;
    }
    
    my $item = $char->{inventory}->[$choice - 1];
    
    if (!$item->is_consumable()) {
        print "そのアイテムは戦闘中に使用できません。\n";
        $self->character_attack($char);
        return;
    }
    
    # 対象選択（回復アイテムなど）
    my $target = $char; # デフォルトは自分
    if ($item->get_effect() eq 'heal' || $item->get_effect() eq 'cure_poison' || 
        $item->get_effect() eq 'cure_all_status' || $item->get_effect() eq 'resurrect') {
        
        print "\n対象を選択してください:\n";
        my @party_targets = ();
        for my $i (0..@{$self->{party}}-1) {
            my $member = $self->{party}->[$i];
            push @party_targets, $member;
            my $status = $member->is_alive() ? "" : " (死亡)";
            print ($i + 1) . ". " . $member->{name} . $status . "\n";
        }
        
        print "選択 (0=自分): ";
        chomp(my $target_choice = <STDIN>);
        
        if ($target_choice > 0 && $target_choice <= @party_targets) {
            $target = $party_targets[$target_choice - 1];
        }
    }
    
    my $result = $char->use_item($item->get_name());
    print $result . "\n";
}

sub select_spell_targets {
    my ($self, $spell) = @_;
    
    my @targets = ();
    
    if ($spell->targets_enemy()) {
        my @alive_monsters = grep { $_->is_alive() } @{$self->{monsters}};
        
        if ($spell->targets_single()) {
            if (@alive_monsters) {
                my $target = $alive_monsters[int(rand(@alive_monsters))];
                push @targets, $target;
            }
        } elsif ($spell->targets_group() || $spell->targets_all()) {
            @targets = @alive_monsters;
        }
    } elsif ($spell->targets_ally()) {
        my @alive_party = grep { $_->is_alive() } @{$self->{party}};
        
        if ($spell->targets_single()) {
            if ($spell->is_healing_spell()) {
                my @injured = grep { $_->{hp} < $_->{max_hp} } @alive_party;
                if (@injured) {
                    my $target = $injured[int(rand(@injured))];
                    push @targets, $target;
                } elsif (@alive_party) {
                    my $target = $alive_party[int(rand(@alive_party))];
                    push @targets, $target;
                }
            } elsif ($spell->is_resurrect_spell()) {
                my @dead = grep { !$_->is_alive() } @{$self->{party}};
                if (@dead) {
                    my $target = $dead[int(rand(@dead))];
                    push @targets, $target;
                }
            }
        } elsif ($spell->targets_group() || $spell->targets_all()) {
            if ($spell->is_healing_spell()) {
                @targets = @alive_party;
            } elsif ($spell->is_resurrect_spell()) {
                @targets = grep { !$_->is_alive() } @{$self->{party}};
            }
        }
    }
    
    return @targets;
}

sub handle_monster_drops {
    my ($self, $monster) = @_;
    
    return unless $monster->can('get_drops');
    
    my @drops = $monster->get_drops();
    for my $drop (@drops) {
        print $monster->{name} . " が " . $drop->get_name() . " を落とした！\n";
        
        # パーティの生きているメンバーのインベントリに追加を試行
        for my $char (@{$self->{party}}) {
            if ($char->is_alive() && $char->can_add_to_inventory($drop)) {
                $char->add_to_inventory($drop);
                print $char->{name} . " が " . $drop->get_name() . " を拾った。\n";
                last;
            }
        }
    }
}

1;