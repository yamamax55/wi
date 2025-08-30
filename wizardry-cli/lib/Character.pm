package Character;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, %args) = @_;
    my $self = {
        name => $args{name} || 'Unknown',
        class => $args{class} || 'Fighter',
        race => $args{race} || 'Human',
        level => 1,
        exp => 0,
        hp => 10,
        max_hp => 10,
        mp => 0,
        max_mp => 0,
        stats => {
            STR => 10,  # 力
            INT => 10,  # 知恵
            PIE => 10,  # 信仰心
            VIT => 10,  # 生命力
            AGI => 10,  # 素早さ
            LUC => 10,  # 幸運
        },
        equipment => {
            weapon => undef,
            armor => undef,
            shield => undef,
            helmet => undef,
            accessory => undef,
        },
        inventory => [],
        status => 'normal',  # normal, poison, paralyzed, stone, sleep, silence, dead
        alignment => 'neutral',  # good, neutral, evil
        position => 'front',  # front, back
        spell_points => {},  # 魔法レベル別の残り使用回数
        spells => {}  # 習得魔法
    };
    
    $self = _calculate_initial_stats($self, $args{race}, $args{class});
    
    bless $self, $class;
    return $self;
}

sub _calculate_initial_stats {
    my ($self, $race, $class) = @_;
    
    # 種族による能力値修正
    my %race_mods = (
        'Human' => {},
        'Elf' => { INT => 1, AGI => 1, VIT => -1 },
        'Dwarf' => { STR => 1, VIT => 1, INT => -1 },
        'Gnome' => { INT => 1, PIE => 1, STR => -1 },
        'Hobbit' => { AGI => 2, LUC => 1, STR => -2 },
    );
    
    # クラスによる基本能力値と成長
    my %class_stats = (
        'Fighter' => { STR => 15, VIT => 14, AGI => 12, hp_base => 10, mp_base => 0 },
        'Mage' => { INT => 15, AGI => 12, VIT => 8, hp_base => 4, mp_base => 4 },
        'Priest' => { PIE => 15, VIT => 12, INT => 10, hp_base => 8, mp_base => 2 },
        'Thief' => { AGI => 15, LUC => 12, STR => 11, hp_base => 6, mp_base => 0 },
        'Samurai' => { STR => 13, VIT => 13, AGI => 11, hp_base => 8, mp_base => 1 },
        'Ninja' => { AGI => 14, LUC => 11, STR => 12, hp_base => 6, mp_base => 1 },
    );
    
    # 能力値をランダムに振り分け（3d6）
    for my $stat (keys %{$self->{stats}}) {
        my $roll = 0;
        for (1..3) {
            $roll += int(rand(6)) + 1;
        }
        $self->{stats}{$stat} = $roll;
    }
    
    # 種族修正適用
    if ($race_mods{$race}) {
        for my $stat (keys %{$race_mods{$race}}) {
            $self->{stats}{$stat} += $race_mods{$race}{$stat};
        }
    }
    
    # クラス修正適用
    if ($class_stats{$class}) {
        my $class_data = $class_stats{$class};
        for my $stat (keys %{$self->{stats}}) {
            if ($class_data->{$stat}) {
                $self->{stats}{$stat} = $class_data->{$stat} if $self->{stats}{$stat} < $class_data->{$stat};
            }
        }
        
        # HP/MP計算
        $self->{max_hp} = $class_data->{hp_base} + int($self->{stats}{VIT} / 2);
        $self->{hp} = $self->{max_hp};
        
        if ($class eq 'Mage' || $class eq 'Priest' || $class eq 'Samurai' || $class eq 'Ninja') {
            $self->{max_mp} = $class_data->{mp_base} + int($self->{stats}{INT} / 3);
            $self->{mp} = $self->{max_mp};
            
            # 魔法使用回数初期化
            for my $level (1..7) {
                $self->{spell_points}{$level} = int($self->{max_mp} / $level) || 0;
            }
        }
    }
    
    return $self;
}

sub create_character {
    my $self = shift;
    
    print "=== キャラクター作成 ===\n\n";
    
    # 名前入力
    print "キャラクター名を入力してください: ";
    chomp(my $name = <STDIN>);
    $self->{name} = $name || "無名の冒険者";
    
    # 種族選択
    my @races = qw(人間 エルフ ドワーフ ノーム ホビット);
    print "\n種族を選択してください:\n";
    for my $i (0..$#races) {
        print(($i + 1) . ". $races[$i]\n");
    }
    print "選択 (1-" . scalar(@races) . "): ";
    chomp(my $race_choice = <STDIN>);
    $self->{race} = $races[$race_choice - 1] || '人間';
    
    # 職業選択
    my @classes = qw(戦士 魔法使い 僧侶 盗賊 侍 忍者);
    print "\n職業を選択してください:\n";
    for my $i (0..$#classes) {
        print(($i + 1) . ". $classes[$i]\n");
    }
    print "選択 (1-" . scalar(@classes) . "): ";
    chomp(my $class_choice = <STDIN>);
    $self->{class} = $classes[$class_choice - 1] || '戦士';
    
    # アライメント選択
    my @alignments = qw(善 中立 悪);
    print "\n性格を選択してください:\n";
    for my $i (0..$#alignments) {
        print(($i + 1) . ". $alignments[$i]\n");
    }
    print "選択 (1-" . scalar(@alignments) . "): ";
    chomp(my $align_choice = <STDIN>);
    $self->{alignment} = $alignments[$align_choice - 1] || '中立';
    
    # 能力値生成
    $self->generate_stats();
    
    # 初期HP/MP設定
    $self->calculate_hp_mp();
    
    print "\n" . "=" x 40 . "\n";
    print "キャラクター作成完了！\n";
    $self->display_status();
    
    return $self;
}

sub generate_stats {
    my $self = shift;
    
    # 3d6でベース能力値生成
    $self->{str} = $self->roll_3d6();
    $self->{int} = $self->roll_3d6();
    $self->{pie} = $self->roll_3d6();
    $self->{vit} = $self->roll_3d6();
    $self->{agi} = $self->roll_3d6();
    $self->{luc} = $self->roll_3d6();
    
    # 種族ボーナス
    my %race_bonus = (
        'エルフ' => { int => 2, agi => 1, str => -1 },
        'ドワーフ' => { str => 2, vit => 1, agi => -1 },
        'ノーム' => { int => 1, luc => 1, str => -1 },
        'ホビット' => { agi => 2, luc => 1, str => -1 }
    );
    
    if (exists $race_bonus{$self->{race}}) {
        my $bonus = $race_bonus{$self->{race}};
        for my $stat (keys %$bonus) {
            $self->{$stat} += $bonus->{$stat};
        }
    }
    
    # 職業による初期魔法習得
    if ($self->{class} eq '魔法使い' || $self->{class} eq '僧侶') {
        push @{$self->{spells}}, $self->get_initial_spells();
    }
}

sub roll_3d6 {
    return int(rand(6)) + int(rand(6)) + int(rand(6)) + 3;
}

sub calculate_hp_mp {
    my $self = shift;
    
    # HPの計算（VIT基準）
    my $base_hp = 10 + int($self->{vit} / 2);
    $self->{max_hp} = $base_hp + ($self->{level} - 1) * int($self->{vit} / 3);
    $self->{hp} = $self->{max_hp};
    
    # MPの計算（職業とINT/PIE基準）
    my $mp_stat = 0;
    if ($self->{class} eq '魔法使い' || $self->{class} eq '忍者') {
        $mp_stat = $self->{int};
    } elsif ($self->{class} eq '僧侶' || $self->{class} eq '侍') {
        $mp_stat = $self->{pie};
    }
    
    if ($mp_stat > 0) {
        $self->{max_mp} = int($mp_stat / 2) + ($self->{level} - 1) * 2;
        $self->{mp} = $self->{max_mp};
    }
}

sub get_initial_spells {
    my $self = shift;
    my @spells = ();
    
    if ($self->{class} eq '魔法使い') {
        push @spells, 'ハリト' if $self->{int} >= 11;
    } elsif ($self->{class} eq '僧侶') {
        push @spells, 'ディオス' if $self->{pie} >= 11;
    }
    
    return @spells;
}

sub display_status {
    my $self = shift;
    
    print "\n=== " . $self->{name} . " のステータス ===\n";
    print "種族: " . $self->{race} . " / 職業: " . $self->{class} . " / 性格: " . $self->{alignment} . "\n";
    print "レベル: " . $self->{level} . " / 経験値: " . $self->{exp} . "\n";
    print "HP: " . $self->{hp} . "/" . $self->{max_hp} . " / MP: " . $self->{mp} . "/" . $self->{max_mp} . "\n";
    print "\n";
    print "STR: " . sprintf("%2d", $self->{str}) . " / INT: " . sprintf("%2d", $self->{int}) . " / PIE: " . sprintf("%2d", $self->{pie}) . "\n";
    print "VIT: " . sprintf("%2d", $self->{vit}) . " / AGI: " . sprintf("%2d", $self->{agi}) . " / LUC: " . sprintf("%2d", $self->{luc}) . "\n";
    print "AC: " . $self->{ac} . "\n";
    
    if (@{$self->{spells}}) {
        print "\n習得魔法: " . join(", ", @{$self->{spells}}) . "\n";
    }
    print "\n";
}

sub take_damage {
    my ($self, $damage) = @_;
    $self->{hp} -= $damage;
    $self->{hp} = 0 if $self->{hp} < 0;
    return $self->{hp} <= 0;
}

sub heal {
    my ($self, $amount) = @_;
    $self->{hp} += $amount;
    $self->{hp} = $self->{max_hp} if $self->{hp} > $self->{max_hp};
}

sub is_alive {
    my $self = shift;
    return $self->{hp} > 0;
}

sub gain_exp {
    my ($self, $exp) = @_;
    $self->{exp} += $exp;
    
    # レベルアップチェック（簡易版）
    my $next_level_exp = $self->{level} * 1000;
    if ($self->{exp} >= $next_level_exp) {
        $self->{level}++;
        my $old_hp = $self->{max_hp};
        my $old_mp = $self->{max_mp};
        $self->calculate_hp_mp();
        my $hp_gain = $self->{max_hp} - $old_hp;
        my $mp_gain = $self->{max_mp} - $old_mp;
        
        print "\n*** レベルアップ！ ***\n";
        print $self->{name} . " はレベル " . $self->{level} . " になった！\n";
        print "HP +" . $hp_gain . ", MP +" . $mp_gain . "\n";
        
        $self->{hp} += $hp_gain;
        $self->{mp} += $mp_gain;
    }
}

1;