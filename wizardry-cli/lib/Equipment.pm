package Equipment;
use strict;
use warnings;
use utf8;
use lib 'lib';
use Item;

sub new {
    my ($class, $character) = @_;
    
    my $self = {
        character => $character,
        weapon => undef,
        armor => undef,
        shield => undef,
        helmet => undef,
        accessory => undef
    };
    
    bless $self, $class;
    return $self;
}

sub equip_item {
    my ($self, $item) = @_;
    
    return "そのアイテムは装備できません。" unless $item->is_weapon() || $item->is_armor() || $item->is_accessory();
    
    return "その職業では装備できません。" unless $item->can_be_equipped_by($self->{character}->{class});
    
    if ($self->{character}->has_status('curse')) {
        return "呪われているため装備を変更できません！";
    }
    
    my $slot = $self->get_equipment_slot($item);
    return "装備スロットが見つかりません。" unless $slot;
    
    my $old_item = $self->{$slot};
    if ($old_item) {
        $self->{character}->add_to_inventory($old_item);
    }
    
    $self->{$slot} = $item;
    $self->{character}->remove_from_inventory($item->get_name());
    
    $self->update_character_stats();
    
    return $self->{character}->{name} . " は " . $item->get_name() . " を装備した。";
}

sub unequip_item {
    my ($self, $slot) = @_;
    
    return "無効な装備スロットです。" unless exists $self->{$slot};
    return "そのスロットには何も装備されていません。" unless $self->{$slot};
    
    if ($self->{character}->has_status('curse')) {
        return "呪われているため装備を外せません！";
    }
    
    my $item = $self->{$slot};
    
    return "インベントリがいっぱいです。" unless $self->{character}->can_add_to_inventory($item);
    
    $self->{$slot} = undef;
    $self->{character}->add_to_inventory($item);
    
    $self->update_character_stats();
    
    return $self->{character}->{name} . " は " . $item->get_name() . " を外した。";
}

sub get_equipment_slot {
    my ($self, $item) = @_;
    
    my $type = $item->get_type();
    
    if ($type eq 'weapon') {
        return 'weapon';
    } elsif ($type eq 'armor') {
        return 'armor';
    } elsif ($type eq 'shield') {
        return 'shield';
    } elsif ($type eq 'helmet') {
        return 'helmet';
    } elsif ($type eq 'accessory') {
        return 'accessory';
    }
    
    return undef;
}

sub get_equipped_item {
    my ($self, $slot) = @_;
    return $self->{$slot};
}

sub is_slot_empty {
    my ($self, $slot) = @_;
    return !defined $self->{$slot};
}

sub calculate_total_ac {
    my $self = shift;
    
    my $base_ac = 10;
    my $total_ac = $base_ac;
    
    for my $slot (qw(armor shield helmet)) {
        if (my $item = $self->{$slot}) {
            $total_ac += $item->get_ac_bonus();
        }
    }
    
    my $agi_bonus = int(($self->{character}->{stats}->{AGI} - 10) / 2);
    $total_ac += $agi_bonus;
    
    return $total_ac;
}

sub calculate_total_damage {
    my ($self, $target_ac) = @_;
    
    my $weapon = $self->{weapon};
    my $damage = 0;
    
    if ($weapon) {
        $damage = $weapon->calculate_weapon_damage($self->{character}->{stats}->{STR});
        $damage += $weapon->get_hit_bonus();
    } else {
        $damage = int(rand(4)) + 1 + int(($self->{character}->{stats}->{STR} - 10) / 3);
    }
    
    my $hit_roll = int(rand(20)) + 1;
    my $required_roll = $target_ac - int(($self->{character}->{stats}->{STR} - 10) / 2);
    
    if ($hit_roll >= $required_roll) {
        if ($hit_roll == 20) {
            $damage *= 2;
        }
        return $damage;
    }
    
    return 0;
}

sub get_stat_bonuses {
    my $self = shift;
    
    my %bonuses = (
        STR => 0,
        INT => 0,
        PIE => 0,
        VIT => 0,
        AGI => 0,
        LUC => 0,
        MP => 0
    );
    
    for my $slot (qw(weapon armor shield helmet accessory)) {
        if (my $item = $self->{$slot}) {
            my $special = $item->get_special();
            next unless $special;
            
            if ($special =~ /str_bonus_\+(\d+)/) {
                $bonuses{STR} += $1;
            } elsif ($special =~ /int_bonus_\+(\d+)/) {
                $bonuses{INT} += $1;
            } elsif ($special =~ /pie_bonus_\+(\d+)/) {
                $bonuses{PIE} += $1;
            } elsif ($special =~ /vit_bonus_\+(\d+)/) {
                $bonuses{VIT} += $1;
            } elsif ($special =~ /agi_bonus_\+(\d+)/) {
                $bonuses{AGI} += $1;
            } elsif ($special =~ /luck_bonus_\+(\d+)/) {
                $bonuses{LUC} += $1;
            } elsif ($special =~ /mp_bonus_\+(\d+)/) {
                $bonuses{MP} += $1;
            }
        }
    }
    
    return %bonuses;
}

sub has_special_effect {
    my ($self, $effect_name) = @_;
    
    for my $slot (qw(weapon armor shield helmet accessory)) {
        if (my $item = $self->{$slot}) {
            my $special = $item->get_special();
            return 1 if $special && $special =~ /$effect_name/;
        }
    }
    
    return 0;
}

sub get_resistance {
    my ($self, $element) = @_;
    
    my $resistance = 0;
    
    for my $slot (qw(weapon armor shield helmet accessory)) {
        if (my $item = $self->{$slot}) {
            my $special = $item->get_special();
            next unless $special;
            
            if ($special =~ /${element}_resistance_(\d+)%/) {
                $resistance += $1;
            }
        }
    }
    
    return $resistance;
}

sub update_character_stats {
    my $self = shift;
    
    my %bonuses = $self->get_stat_bonuses();
    
    $self->{character}->{equipment_bonuses} = \%bonuses;
    
    $self->{character}->{ac} = $self->calculate_total_ac();
    
    if ($bonuses{MP} > 0) {
        $self->{character}->{max_mp} += $bonuses{MP};
        $self->{character}->{mp} = $self->{character}->{max_mp} 
            if $self->{character}->{mp} > $self->{character}->{max_mp};
    }
}

sub display_equipment {
    my $self = shift;
    
    print "\n=== 装備状況 ===\n";
    
    my @slots = (
        ['武器', 'weapon'],
        ['鎧', 'armor'],
        ['盾', 'shield'],
        ['兜', 'helmet'],
        ['装飾品', 'accessory']
    );
    
    for my $slot_info (@slots) {
        my ($display_name, $slot_name) = @$slot_info;
        my $item = $self->{$slot_name};
        
        if ($item) {
            print sprintf("%-8s: %s", $display_name, $item->get_name());
            
            if ($item->is_weapon()) {
                print " (ダメージ: " . $item->get_damage() . ")";
            } elsif ($item->is_armor()) {
                print " (AC: +" . $item->get_ac_bonus() . ")";
            }
            
            if (my $special = $item->get_special()) {
                print " [" . $special . "]";
            }
            
            print "\n";
        } else {
            print sprintf("%-8s: なし\n", $display_name);
        }
    }
    
    print "\n総合AC: " . $self->calculate_total_ac() . "\n";
}

sub get_all_equipment {
    my $self = shift;
    
    my @equipment = ();
    
    for my $slot (qw(weapon armor shield helmet accessory)) {
        push @equipment, $self->{$slot} if $self->{$slot};
    }
    
    return @equipment;
}

sub get_total_weight {
    my $self = shift;
    
    my $total_weight = 0;
    
    for my $item ($self->get_all_equipment()) {
        $total_weight += $item->get_weight();
    }
    
    return $total_weight;
}

sub serialize {
    my $self = shift;
    
    my %data = ();
    
    for my $slot (qw(weapon armor shield helmet accessory)) {
        if (my $item = $self->{$slot}) {
            $data{$slot} = {
                name => $item->get_name(),
                quantity => $item->get_quantity()
            };
        }
    }
    
    return \%data;
}

sub deserialize {
    my ($self, $data) = @_;
    
    for my $slot (qw(weapon armor shield helmet accessory)) {
        if (my $item_data = $data->{$slot}) {
            my $item = Item->new($item_data->{name}, $item_data->{quantity});
            $self->{$slot} = $item if $item;
        }
    }
    
    $self->update_character_stats();
}

1;