package Item;
use strict;
use warnings;
use utf8;
use JSON;

my $items_data;
my $weapons_data;
my $armors_data;

sub load_data {
    unless ($items_data) {
        my $items_file = 'data/items.json';
        if (-f $items_file) {
            open my $fh, '<:encoding(utf8)', $items_file or die "Cannot open $items_file: $!";
            local $/;
            my $json_text = <$fh>;
            close $fh;
            $items_data = decode_json($json_text);
        }
    }
    
    unless ($weapons_data) {
        my $weapons_file = 'data/weapons.json';
        if (-f $weapons_file) {
            open my $fh, '<:encoding(utf8)', $weapons_file or die "Cannot open $weapons_file: $!";
            local $/;
            my $json_text = <$fh>;
            close $fh;
            $weapons_data = decode_json($json_text);
        }
    }
    
    unless ($armors_data) {
        my $armors_file = 'data/armors.json';
        if (-f $armors_file) {
            open my $fh, '<:encoding(utf8)', $armors_file or die "Cannot open $armors_file: $!";
            local $/;
            my $json_text = <$fh>;
            close $fh;
            $armors_data = decode_json($json_text);
        }
    }
}

sub new {
    my ($class, $name, $quantity) = @_;
    
    load_data();
    $quantity ||= 1;
    
    my $data = $items_data->{$name} || $weapons_data->{$name} || $armors_data->{$name};
    return undef unless $data;
    
    my $self = {
        name => $name,
        quantity => $quantity,
        data => { %$data }
    };
    
    bless $self, $class;
    return $self;
}

sub get_name {
    my $self = shift;
    return $self->{name};
}

sub get_type {
    my $self = shift;
    return $self->{data}->{type};
}

sub get_price {
    my $self = shift;
    return $self->{data}->{price} || 0;
}

sub get_weight {
    my $self = shift;
    return $self->{data}->{weight} || 0;
}

sub get_quantity {
    my $self = shift;
    return $self->{quantity};
}

sub set_quantity {
    my ($self, $quantity) = @_;
    $self->{quantity} = $quantity;
}

sub add_quantity {
    my ($self, $amount) = @_;
    $self->{quantity} += $amount;
}

sub remove_quantity {
    my ($self, $amount) = @_;
    $self->{quantity} -= $amount;
    $self->{quantity} = 0 if $self->{quantity} < 0;
    return $self->{quantity};
}

sub get_total_weight {
    my $self = shift;
    return $self->get_weight() * $self->{quantity};
}

sub get_total_value {
    my $self = shift;
    return $self->get_price() * $self->{quantity};
}

sub is_weapon {
    my $self = shift;
    return $self->get_type() eq 'weapon';
}

sub is_armor {
    my $self = shift;
    my $type = $self->get_type();
    return $type eq 'armor' || $type eq 'shield' || $type eq 'helmet';
}

sub is_consumable {
    my $self = shift;
    return $self->get_type() eq 'consumable';
}

sub is_accessory {
    my $self = shift;
    return $self->get_type() eq 'accessory';
}

sub is_treasure {
    my $self = shift;
    return $self->get_type() eq 'treasure';
}

sub is_key {
    my $self = shift;
    return $self->get_type() eq 'key';
}

sub can_be_equipped_by {
    my ($self, $character_class) = @_;
    
    return 0 unless ($self->is_weapon() || $self->is_armor() || $self->is_accessory());
    
    my $required_classes = $self->{data}->{required_class};
    
    return 1 unless $required_classes && @$required_classes;
    
    for my $class (@$required_classes) {
        return 1 if $class eq $character_class;
    }
    
    return 0;
}

sub get_damage {
    my $self = shift;
    return $self->{data}->{damage} if $self->is_weapon();
    return undef;
}

sub get_hit_bonus {
    my $self = shift;
    return $self->{data}->{hit_bonus} || 0;
}

sub get_ac_bonus {
    my $self = shift;
    return $self->{data}->{ac_bonus} || 0;
}

sub get_special {
    my $self = shift;
    return $self->{data}->{special};
}

sub get_effect {
    my $self = shift;
    return $self->{data}->{effect};
}

sub get_power {
    my $self = shift;
    return $self->{data}->{power};
}

sub get_success_rate {
    my $self = shift;
    return $self->{data}->{success_rate} || 100;
}

sub get_description {
    my $self = shift;
    return $self->{data}->{description} || '';
}

sub use_item {
    my ($self, $target) = @_;
    
    return 0 unless $self->is_consumable();
    return 0 unless $self->{quantity} > 0;
    
    my $effect = $self->get_effect();
    my $result = '';
    
    if ($effect eq 'heal') {
        my $healing = $self->calculate_healing();
        $target->heal($healing);
        $result = "$target->{name} は ${healing} のHPを回復した！";
        
    } elsif ($effect eq 'restore_mp') {
        my $mp_restore = $self->calculate_mp_restore();
        $target->{mp} += $mp_restore;
        $target->{mp} = $target->{max_mp} if $target->{mp} > $target->{max_mp};
        $result = "$target->{name} は ${mp_restore} のMPを回復した！";
        
    } elsif ($effect eq 'cure_poison') {
        $target->remove_status('poison');
        $result = "$target->{name} の毒が治った！";
        
    } elsif ($effect eq 'cure_all_status') {
        $target->remove_all_status();
        $result = "$target->{name} の状態異常が全て治った！";
        
    } elsif ($effect eq 'resurrect') {
        if (!$target->is_alive() && $self->roll_success()) {
            $target->{hp} = 1;
            $target->remove_all_status();
            $result = "$target->{name} が蘇生した！";
        } else {
            $result = "蘇生に失敗した...";
        }
        
    } elsif ($effect eq 'full_restore') {
        $target->{hp} = $target->{max_hp};
        $target->{mp} = $target->{max_mp};
        $target->remove_all_status();
        $result = "$target->{name} が完全に回復した！";
    }
    
    $self->{quantity}--;
    return $result;
}

sub calculate_healing {
    my $self = shift;
    
    my $power = $self->get_power();
    return 0 unless $power;
    
    my $healing = 0;
    
    if ($power =~ /(\d+)d(\d+)(\+(\d+))?/) {
        my ($dice_count, $dice_size, $bonus) = ($1, $2, $4 || 0);
        
        for (1..$dice_count) {
            $healing += int(rand($dice_size)) + 1;
        }
        
        $healing += $bonus;
    }
    
    return $healing;
}

sub calculate_mp_restore {
    my $self = shift;
    return $self->calculate_healing();
}

sub roll_success {
    my $self = shift;
    my $rate = $self->get_success_rate();
    return (int(rand(100)) + 1) <= $rate;
}

sub calculate_weapon_damage {
    my ($self, $str_bonus) = @_;
    
    return 0 unless $self->is_weapon();
    
    my $damage_roll = $self->get_damage();
    return 0 unless $damage_roll;
    
    my $damage = 0;
    $str_bonus ||= 0;
    
    if ($damage_roll =~ /(\d+)d(\d+)(\+(\d+))?/) {
        my ($dice_count, $dice_size, $bonus) = ($1, $2, $4 || 0);
        
        for (1..$dice_count) {
            $damage += int(rand($dice_size)) + 1;
        }
        
        $damage += $bonus;
        $damage += int($str_bonus / 3);
    }
    
    return $damage;
}

sub get_all_items {
    my $class = shift;
    load_data();
    
    my @all_items = ();
    push @all_items, keys %$items_data if $items_data;
    push @all_items, keys %$weapons_data if $weapons_data;
    push @all_items, keys %$armors_data if $armors_data;
    
    return @all_items;
}

sub item_exists {
    my ($class, $name) = @_;
    load_data();
    
    return exists $items_data->{$name} || 
           exists $weapons_data->{$name} || 
           exists $armors_data->{$name};
}

sub get_items_by_type {
    my ($class, $type) = @_;
    load_data();
    
    my @items = ();
    
    for my $name (keys %$items_data) {
        push @items, $name if $items_data->{$name}->{type} eq $type;
    }
    
    for my $name (keys %$weapons_data) {
        push @items, $name if $weapons_data->{$name}->{type} eq $type;
    }
    
    for my $name (keys %$armors_data) {
        push @items, $name if $armors_data->{$name}->{type} eq $type;
    }
    
    return @items;
}

1;