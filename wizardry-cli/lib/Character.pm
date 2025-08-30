package Character;
use strict;
use warnings;
use utf8;
use lib 'lib';
use StatusEffect;
use Spell;
use Item;
use Equipment;

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
        status_effects => [],  # StatusEffect objects
        alignment => 'neutral',  # good, neutral, evil
        position => 'front',  # front, back
        spell_points => {},  # 魔法レベル別の残り使用回数
        known_spells => [],  # 習得魔法名の配列
        equipment_manager => undef,  # Equipment object
        ac => 10,  # アーマークラス
        max_inventory => 20,  # 最大所持アイテム数
        equipment_bonuses => {}  # 装備ボーナス
    };
    
    $self = _calculate_initial_stats($self, $args{race}, $args{class});
    
    # Equipment manager initialization
    $self->{equipment_manager} = Equipment->new($self);
    
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
            
            # 初期魔法習得
            my @initial_spells = Spell->get_initial_spells_for_character($class, $self->{stats}{INT}, $self->{stats}{PIE});
            $self->{known_spells} = \@initial_spells;
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
    print "STR: " . sprintf("%2d", $self->{stats}->{STR}) . " / INT: " . sprintf("%2d", $self->{stats}->{INT}) . " / PIE: " . sprintf("%2d", $self->{stats}->{PIE}) . "\n";
    print "VIT: " . sprintf("%2d", $self->{stats}->{VIT}) . " / AGI: " . sprintf("%2d", $self->{stats}->{AGI}) . " / LUC: " . sprintf("%2d", $self->{stats}->{LUC}) . "\n";
    print "AC: " . $self->{ac} . "\n";
    
    if (@{$self->{known_spells}}) {
        print "\n習得魔法: " . join(", ", @{$self->{known_spells}}) . "\n";
    }
    
    if (@{$self->{status_effects}}) {
        print "\n状態異常: ";
        my @status_names = map { $_->get_name() } @{$self->{status_effects}};
        print join(", ", @status_names) . "\n";
    }
    
    # 装備表示
    $self->{equipment_manager}->display_equipment();
    
    # インベントリ表示
    if (@{$self->{inventory}}) {
        print "\n=== インベントリ ===\n";
        for my $item (@{$self->{inventory}}) {
            print $item->get_name();
            print " x" . $item->get_quantity() if $item->get_quantity() > 1;
            print "\n";
        }
    }
    print "\n";
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
        
        # 新しい魔法を習得できるかチェック
        $self->check_new_spells();
    }
}

sub apply_status_effect {
    my ($self, $effect_type, $duration) = @_;
    
    return 0 unless StatusEffect->is_valid_type($effect_type);
    
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

sub remove_all_status_effects {
    my $self = shift;
    $self->{status_effects} = [];
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

sub can_cast_magic {
    my $self = shift;
    
    for my $effect (@{$self->{status_effects}}) {
        return 0 unless $effect->can_cast_magic();
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

sub learn_spell {
    my ($self, $spell_name) = @_;
    
    return 0 unless Spell->spell_exists($spell_name);
    
    my $spell = Spell->new($spell_name);
    return 0 unless $spell->can_be_learned_by($self->{class});
    
    # 既に習得済みかチェック
    for my $known (@{$self->{known_spells}}) {
        return 0 if $known eq $spell_name;
    }
    
    push @{$self->{known_spells}}, $spell_name;
    return 1;
}

sub can_cast_spell {
    my ($self, $spell_name) = @_;
    
    return 0 unless $self->can_cast_magic();
    
    # 魔法を知っているかチェック
    my $knows_spell = 0;
    for my $known (@{$self->{known_spells}}) {
        if ($known eq $spell_name) {
            $knows_spell = 1;
            last;
        }
    }
    return 0 unless $knows_spell;
    
    my $spell = Spell->new($spell_name);
    return 0 unless $spell;
    
    # MPをチェック
    return $self->{mp} >= $spell->get_mp_cost();
}

sub cast_spell {
    my ($self, $spell_name, $targets) = @_;
    
    return "魔法を使用できません。" unless $self->can_cast_spell($spell_name);
    
    my $spell = Spell->new($spell_name);
    $self->{mp} -= $spell->get_mp_cost();
    
    my @results = ();
    
    if ($spell->is_damage_spell()) {
        for my $target (@$targets) {
            my $damage = $spell->calculate_damage($self->{level}, $self->get_effective_stat('INT'));
            $target->take_damage($damage);
            push @results, "$target->{name} に ${damage} のダメージ！";
        }
    } elsif ($spell->is_healing_spell()) {
        for my $target (@$targets) {
            my $healing = $spell->calculate_healing($self->{level}, $self->get_effective_stat('PIE'));
            $target->heal($healing);
            push @results, "$target->{name} のHPが ${healing} 回復！";
        }
    } elsif ($spell->is_status_spell()) {
        for my $target (@$targets) {
            if ($spell->roll_success($target->{level})) {
                $target->apply_status_effect($spell->get_status());
                push @results, "$target->{name} は " . $spell->get_status() . " 状態になった！";
            } else {
                push @results, "$target->{name} は魔法に抵抗した！";
            }
        }
    }
    
    return @results;
}

sub add_to_inventory {
    my ($self, $item) = @_;
    
    return 0 if @{$self->{inventory}} >= $self->{max_inventory};
    
    # 既に同じアイテムがある場合は数量を増やす
    for my $inv_item (@{$self->{inventory}}) {
        if ($inv_item->get_name() eq $item->get_name()) {
            $inv_item->add_quantity($item->get_quantity());
            return 1;
        }
    }
    
    # 新しいアイテムとして追加
    push @{$self->{inventory}}, $item;
    return 1;
}

sub remove_from_inventory {
    my ($self, $item_name, $quantity) = @_;
    $quantity ||= 1;
    
    for my $i (0..$#{$self->{inventory}}) {
        my $item = $self->{inventory}[$i];
        if ($item->get_name() eq $item_name) {
            if ($item->get_quantity() <= $quantity) {
                splice @{$self->{inventory}}, $i, 1;
            } else {
                $item->remove_quantity($quantity);
            }
            return 1;
        }
    }
    
    return 0;
}

sub can_add_to_inventory {
    my ($self, $item) = @_;
    
    return 1 if @{$self->{inventory}} < $self->{max_inventory};
    
    # 同じアイテムがある場合はスタック可能
    for my $inv_item (@{$self->{inventory}}) {
        return 1 if $inv_item->get_name() eq $item->get_name();
    }
    
    return 0;
}

sub get_inventory_item {
    my ($self, $item_name) = @_;
    
    for my $item (@{$self->{inventory}}) {
        return $item if $item->get_name() eq $item_name;
    }
    
    return undef;
}

sub use_item {
    my ($self, $item_name) = @_;
    
    my $item = $self->get_inventory_item($item_name);
    return "そのアイテムを持っていません。" unless $item;
    return "そのアイテムは使用できません。" unless $item->is_consumable();
    
    my $result = $item->use_item($self);
    
    # アイテムを使い切った場合は削除
    if ($item->get_quantity() <= 0) {
        $self->remove_from_inventory($item_name);
    }
    
    return $result;
}

sub equip_item {
    my ($self, $item_name) = @_;
    
    my $item = $self->get_inventory_item($item_name);
    return "そのアイテムを持っていません。" unless $item;
    
    return $self->{equipment_manager}->equip_item($item);
}

sub unequip_item {
    my ($self, $slot) = @_;
    return $self->{equipment_manager}->unequip_item($slot);
}

sub get_effective_stat {
    my ($self, $stat) = @_;
    
    my $base_stat = $self->{stats}->{$stat} || 0;
    my $bonus = $self->{equipment_bonuses}->{$stat} || 0;
    
    return $base_stat + $bonus;
}

sub check_new_spells {
    my $self = shift;
    
    my $spell_type = ($self->{class} eq '魔法使い' || $self->{class} eq '忍者') ? 'mage' : 'priest';
    return unless $spell_type;
    
    my @available_spells = Spell->get_spells_by_level_and_type($self->{level}, $spell_type);
    
    for my $spell_name (@available_spells) {
        my $already_known = 0;
        for my $known (@{$self->{known_spells}}) {
            if ($known eq $spell_name) {
                $already_known = 1;
                last;
            }
        }
        
        unless ($already_known) {
            if ($self->learn_spell($spell_name)) {
                print $self->{name} . " は新しい魔法 『" . $spell_name . "』 を習得した！\n";
            }
        }
    }
}

sub display_inventory {
    my $self = shift;
    
    print "\n=== インベントリ (" . @{$self->{inventory}} . "/" . $self->{max_inventory} . ") ===\n";
    
    if (@{$self->{inventory}}) {
        for my $i (0..$#{$self->{inventory}}) {
            my $item = $self->{inventory}[$i];
            print ($i + 1) . ". " . $item->get_name();
            print " x" . $item->get_quantity() if $item->get_quantity() > 1;
            print " (" . $item->get_description() . ")" if $item->get_description();
            print "\n";
        }
    } else {
        print "アイテムを持っていません。\n";
    }
}

sub get_total_inventory_weight {
    my $self = shift;
    
    my $total_weight = 0;
    for my $item (@{$self->{inventory}}) {
        $total_weight += $item->get_total_weight();
    }
    
    return $total_weight;
}

1;