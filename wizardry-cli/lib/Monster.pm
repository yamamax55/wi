package Monster;

use strict;
use warnings;
use utf8;
use JSON;
use lib 'lib';
use StatusEffect;
use Item;

sub new {
    my ($class, $name, $data) = @_;
    my $self = {
        name => $name,
        hp => $data->{hp} || 10,
        max_hp => $data->{hp} || 10,
        str => $data->{str} || 10,
        agi => $data->{agi} || 10,
        ac => $data->{ac} || 8,
        exp => $data->{exp} || 10,
        gold => $data->{gold} || 5,
        special_attacks => $data->{special_attacks} || [],
        resistances => $data->{resistances} || [],
        level => $data->{level} || 1,
        status_effects => [],
        drop_table => $data->{drop_table} || [],
        status_attacks => $data->{status_attacks} || []
    };
    bless $self, $class;
    return $self;
}

sub load_monsters {
    my $class = shift;
    my $file = shift || 'data/monsters.json';
    
    # モンスターデータファイルが存在しない場合、デフォルトデータを作成
    unless (-f $file) {
        $class->create_default_monster_data($file);
    }
    
    open my $fh, '<:encoding(UTF-8)', $file or die "モンスターデータファイルを開けません: $!";
    local $/;
    my $json_text = <$fh>;
    close $fh;
    
    my $data = decode_json($json_text);
    return $data;
}

sub create_default_monster_data {
    my ($class, $file) = @_;
    
    my $monster_data = {
        "ゴブリン" => {
            "hp" => 8,
            "str" => 12,
            "agi" => 11,
            "ac" => 8,
            "exp" => 15,
            "gold" => 8,
            "level" => 1,
            "special_attacks" => [],
            "resistances" => [],
            "drop_table" => [
                {"item" => "パン", "chance" => 30},
                {"item" => "短剣", "chance" => 5}
            ],
            "status_attacks" => []
        },
        "オーク" => {
            "hp" => 15,
            "str" => 15,
            "agi" => 9,
            "ac" => 6,
            "exp" => 25,
            "gold" => 15,
            "level" => 2,
            "special_attacks" => [],
            "resistances" => [],
            "drop_table" => [
                {"item" => "ポーション", "chance" => 20},
                {"item" => "革の鎧", "chance" => 10},
                {"item" => "金貨", "chance" => 15}
            ],
            "status_attacks" => [{"type" => "poison", "chance" => 15}]
        },
        "スケルトン" => {
            "hp" => 12,
            "str" => 13,
            "agi" => 8,
            "ac" => 7,
            "exp" => 20,
            "gold" => 10,
            "level" => 2,
            "special_attacks" => [],
            "resistances" => ["sleep", "poison"],
            "drop_table" => [
                {"item" => "骨", "chance" => 40},
                {"item" => "マナポーション", "chance" => 10}
            ],
            "status_attacks" => []
        },
        "ワイト" => {
            "hp" => 25,
            "str" => 16,
            "agi" => 10,
            "ac" => 5,
            "exp" => 50,
            "gold" => 25,
            "level" => 3,
            "special_attacks" => ["レベルドレイン"],
            "resistances" => ["sleep", "poison", "paralysis"],
            "drop_table" => [
                {"item" => "解毒剤", "chance" => 25},
                {"item" => "宝石", "chance" => 15},
                {"item" => "銀の鍵", "chance" => 5}
            ],
            "status_attacks" => [{"type" => "paralysis", "chance" => 20}]
        },
        "ミノタウロス" => {
            "hp" => 40,
            "str" => 18,
            "agi" => 12,
            "ac" => 4,
            "exp" => 80,
            "gold" => 40,
            "level" => 4,
            "special_attacks" => ["突進"],
            "resistances" => [],
            "drop_table" => [
                {"item" => "ハイポーション", "chance" => 30},
                {"item" => "チェインメイル", "chance" => 12},
                {"item" => "力の指輪", "chance" => 8}
            ],
            "status_attacks" => []
        },
        "ドラゴン" => {
            "hp" => 80,
            "str" => 20,
            "agi" => 14,
            "ac" => 2,
            "exp" => 200,
            "gold" => 100,
            "level" => 8,
            "special_attacks" => ["ブレス攻撃"],
            "resistances" => ["fire"],
            "drop_table" => [
                {"item" => "ダイヤモンド", "chance" => 15},
                {"item" => "フレイムソード", "chance" => 8},
                {"item" => "ドラゴンスケイル", "chance" => 12},
                {"item" => "エリクサー", "chance" => 3}
            ],
            "status_attacks" => [{"type" => "sleep", "chance" => 25}]
        }
    };
    
    # ディレクトリが存在しない場合は作成
    my $dir = $file;
    $dir =~ s/\/[^\/]*$//;
    unless (-d $dir) {
        mkdir $dir or die "ディレクトリを作成できません: $!";
    }
    
    open my $fh, '>:encoding(UTF-8)', $file or die "モンスターデータファイルを作成できません: $!";
    print $fh encode_json($monster_data);
    close $fh;
}

sub create_encounter {
    my ($class, $floor) = @_;
    $floor ||= 1;
    
    my $monster_data = $class->load_monsters();
    my @monster_names = keys %$monster_data;
    
    # フロアに応じたモンスター選択
    my @available_monsters = grep { 
        $monster_data->{$_}->{level} <= $floor + 1 
    } @monster_names;
    
    return [] unless @available_monsters;
    
    my @encounter = ();
    my $group_size = 1 + int(rand(3));  # 1-3体
    
    for (1..$group_size) {
        my $monster_name = $available_monsters[int(rand(@available_monsters))];
        my $monster = Monster->new($monster_name, $monster_data->{$monster_name});
        push @encounter, $monster;
    }
    
    return \@encounter;
}

sub attack {
    my ($self, $target) = @_;
    
    my $hit_roll = int(rand(20)) + 1;
    my $ac_needed = $target->{ac} || 10;
    
    if ($hit_roll >= $ac_needed) {
        my $damage = int(rand(6)) + int($self->{str} / 3);
        $damage = 1 if $damage < 1;
        
        print $self->{name} . " の攻撃！ " . $target->{name} . " に " . $damage . " のダメージ！\n";
        
        my $is_dead = $target->take_damage($damage);
        
        # 状態異常攻撃の試行
        $self->try_status_attack($target) unless $is_dead;
        
        return ($damage, $is_dead);
    } else {
        print $self->{name} . " の攻撃は外れた！\n";
        return (0, 0);
    }
}

sub special_attack {
    my ($self, $targets) = @_;
    
    return 0 unless @{$self->{special_attacks}};
    return 0 if int(rand(4)) != 0;  # 25%の確率
    
    my $attack = $self->{special_attacks}->[0];
    
    if ($attack eq "レベルドレイン") {
        my $target = $targets->[int(rand(@$targets))];
        print $self->{name} . " のレベルドレイン攻撃！\n";
        if ($target->{level} > 1 && int(rand(4)) == 0) {
            $target->{level}--;
            print $target->{name} . " のレベルが下がった！\n";
        }
        return 1;
    } elsif ($attack eq "ブレス攻撃") {
        print $self->{name} . " のブレス攻撃！\n";
        my $damage = int(rand(20)) + 10;
        for my $target (@$targets) {
            if ($target->is_alive()) {
                print $target->{name} . " に " . $damage . " のダメージ！\n";
                $target->take_damage($damage);
            }
        }
        return 1;
    }
    
    return 0;
}

sub take_damage {
    my ($self, $damage) = @_;
    $self->{hp} -= $damage;
    $self->{hp} = 0 if $self->{hp} < 0;
    
    # 睡眠状態の場合はダメージで起きる
    if ($self->has_status('sleep')) {
        for my $effect (@{$self->{status_effects}}) {
            if ($effect->{type} eq 'sleep' && $effect->should_wake_on_damage()) {
                $self->remove_status_effect('sleep');
                last;
            }
        }
    }
    
    return $self->{hp} <= 0;
}

sub is_alive {
    my $self = shift;
    return $self->{hp} > 0;
}

sub get_treasure {
    my $self = shift;
    my $gold = $self->{gold} + int(rand($self->{gold}));
    return { gold => $gold, exp => $self->{exp} };
}

sub apply_status_effect {
    my ($self, $effect_type, $duration) = @_;
    
    return 0 unless StatusEffect->is_valid_type($effect_type);
    
    # 耐性チェック
    for my $resistance (@{$self->{resistances}}) {
        return 0 if $resistance eq $effect_type;
    }
    
    # 既に同じ状態異常がある場合は持続時間を更新
    for my $effect (@{$self->{status_effects}}) {
        if ($effect->{type} eq $effect_type) {
            $effect->reset_duration($duration);
            return 1;
        }
    }
    
    # 新しい状態異常を追加
    my $effect = StatusEffect->new($effect_type, $duration);
    push @{$self->{status_effects}}, $effect if $effect;
    
    return 1;
}

sub remove_status_effect {
    my ($self, $effect_type) = @_;
    @{$self->{status_effects}} = grep { $_->{type} ne $effect_type } @{$self->{status_effects}};
}

sub has_status {
    my ($self, $effect_type) = @_;
    
    for my $effect (@{$self->{status_effects}}) {
        return 1 if $effect->{type} eq $effect_type;
    }
    
    return 0;
}

sub can_act {
    my $self = shift;
    
    return 0 unless $self->is_alive();
    
    for my $effect (@{$self->{status_effects}}) {
        return 0 unless $effect->can_act();
    }
    
    return 1;
}

sub process_status_effects {
    my $self = shift;
    my @messages = ();
    
    my @active_effects = @{$self->{status_effects}};
    $self->{status_effects} = [];
    
    for my $effect (@active_effects) {
        # ダメージ効果の処理
        my $message = $effect->apply_effect($self);
        push @messages, $message if $message;
        
        # 持続時間の減少
        unless ($effect->tick()) {
            push @{$self->{status_effects}}, $effect;
        }
    }
    
    return @messages;
}

sub get_drops {
    my $self = shift;
    my @drops = ();
    
    for my $drop_entry (@{$self->{drop_table}}) {
        my $chance = $drop_entry->{chance} || 0;
        if (int(rand(100)) + 1 <= $chance) {
            my $item = Item->new($drop_entry->{item});
            push @drops, $item if $item;
        }
    }
    
    return @drops;
}

sub try_status_attack {
    my ($self, $target) = @_;
    
    return 0 unless @{$self->{status_attacks}};
    
    for my $attack (@{$self->{status_attacks}}) {
        my $chance = $attack->{chance} || 0;
        if (int(rand(100)) + 1 <= $chance) {
            my $status_type = $attack->{type};
            if ($target->apply_status_effect($status_type)) {
                print $target->{name} . " は " . $status_type . " 状態になった！\n";
                return 1;
            }
        }
    }
    
    return 0;
}

1;