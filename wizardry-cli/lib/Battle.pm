package Battle;

use strict;
use warnings;
use utf8;

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
        
        $self->display_party_status();
        
        print "\n" . $char->{name} . " のターン\n";
        print "1. 攻撃  2. 魔法  3. 防御  4. 逃走\n";
        print "コマンド？ ";
        chomp(my $command = <STDIN>);
        
        if ($command eq '1') {
            $self->character_attack($char);
        } elsif ($command eq '2') {
            $self->character_spell($char);
        } elsif ($command eq '3') {
            print $char->{name} . " は身を守っている...\n";
            # 防御効果は次の被ダメージ時に適用
        } elsif ($command eq '4') {
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
    
    my $hit_roll = int(rand(20)) + 1;
    my $ac_needed = $target->{ac};
    
    if ($hit_roll >= $ac_needed) {
        my $damage = int(rand(6)) + int($char->{str} / 3) + 1;
        print $char->{name} . " の攻撃！ " . $target->{name} . " に " . $damage . " のダメージ！\n";
        
        my $is_dead = $target->take_damage($damage);
        if ($is_dead) {
            print $target->{name} . " を倒した！\n";
        }
    } else {
        print $char->{name} . " の攻撃は外れた！\n";
    }
}

sub character_spell {
    my ($self, $char) = @_;
    
    if (!@{$char->{spells}}) {
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
    for my $i (0..@{$char->{spells}}-1) {
        print(($i + 1) . ". " . $char->{spells}->[$i] . "\n");
    }
    print "選択 (0=キャンセル): ";
    chomp(my $spell_choice = <STDIN>);
    
    if ($spell_choice == 0 || $spell_choice > @{$char->{spells}}) {
        $self->character_attack($char);
        return;
    }
    
    my $spell = $char->{spells}->[$spell_choice - 1];
    $self->cast_spell($char, $spell);
}

sub cast_spell {
    my ($self, $caster, $spell) = @_;
    
    if ($spell eq 'ハリト') {
        my @alive_monsters = grep { $_->is_alive() } @{$self->{monsters}};
        return unless @alive_monsters;
        
        my $target = $alive_monsters[int(rand(@alive_monsters))];
        my $damage = int(rand(8)) + int($caster->{int} / 4) + 1;
        
        print $caster->{name} . " はハリトを唱えた！\n";
        print "火球が " . $target->{name} . " に " . $damage . " のダメージ！\n";
        
        my $is_dead = $target->take_damage($damage);
        if ($is_dead) {
            print $target->{name} . " を倒した！\n";
        }
        $caster->{mp} -= 2;
        
    } elsif ($spell eq 'ディオス') {
        my @injured_chars = grep { $_->is_alive() && $_->{hp} < $_->{max_hp} } @{$self->{party}};
        
        if (@injured_chars) {
            my $target = $injured_chars[int(rand(@injured_chars))];
            my $heal = int(rand(8)) + int($caster->{pie} / 4) + 1;
            
            print $caster->{name} . " はディオスを唱えた！\n";
            $target->heal($heal);
            print $target->{name} . " は " . $heal . " 回復した！\n";
        } else {
            print $caster->{name} . " はディオスを唱えたが効果がなかった。\n";
        }
        $caster->{mp} -= 3;
        
    } else {
        print "その魔法は実装されていません。\n";
        $self->character_attack($caster);
        return;
    }
}

sub monster_turn {
    my $self = shift;
    
    print "\n--- モンスターのターン ---\n";
    
    for my $monster (@{$self->{monsters}}) {
        next unless $monster->is_alive();
        
        my @alive_party = grep { $_->is_alive() } @{$self->{party}};
        last unless @alive_party;
        
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

1;