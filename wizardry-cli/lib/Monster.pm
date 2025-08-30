package Monster;

use strict;
use warnings;
use utf8;
use JSON;

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
        level => $data->{level} || 1
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
            "resistances" => []
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
            "resistances" => []
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
            "resistances" => ["睡眠", "毒"]
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
            "resistances" => ["睡眠", "毒", "麻痺"]
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
            "resistances" => []
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
            "resistances" => ["火"]
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

1;