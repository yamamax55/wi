package Spell;
use strict;
use warnings;
use utf8;
use JSON;

my $spells_data;

sub load_spells {
    my $file = 'data/spells.json';
    
    if (-f $file) {
        open my $fh, '<:encoding(utf8)', $file or die "Cannot open $file: $!";
        local $/;
        my $json_text = <$fh>;
        close $fh;
        
        $spells_data = decode_json($json_text);
    } else {
        die "Spells data file not found: $file";
    }
}

sub get_spells_data {
    load_spells() unless $spells_data;
    return $spells_data;
}

sub new {
    my ($class, $name) = @_;
    
    load_spells() unless $spells_data;
    
    return undef unless exists $spells_data->{$name};
    
    my $self = {
        name => $name,
        data => { %{$spells_data->{$name}} }
    };
    
    bless $self, $class;
    return $self;
}

sub get_name {
    my $self = shift;
    return $self->{name};
}

sub get_level {
    my $self = shift;
    return $self->{data}->{level};
}

sub get_type {
    my $self = shift;
    return $self->{data}->{type};
}

sub get_mp_cost {
    my $self = shift;
    return $self->{data}->{mp_cost};
}

sub get_target {
    my $self = shift;
    return $self->{data}->{target};
}

sub get_effect {
    my $self = shift;
    return $self->{data}->{effect};
}

sub get_power {
    my $self = shift;
    return $self->{data}->{power};
}

sub get_element {
    my $self = shift;
    return $self->{data}->{element};
}

sub get_status {
    my $self = shift;
    return $self->{data}->{status};
}

sub get_success_rate {
    my $self = shift;
    return $self->{data}->{success_rate} || 100;
}

sub get_description {
    my $self = shift;
    return $self->{data}->{description};
}

sub is_damage_spell {
    my $self = shift;
    return $self->get_effect() eq 'damage';
}

sub is_healing_spell {
    my $self = shift;
    return $self->get_effect() eq 'heal';
}

sub is_status_spell {
    my $self = shift;
    return $self->get_effect() eq 'status';
}

sub is_cure_spell {
    my $self = shift;
    return $self->get_effect() eq 'cure_status';
}

sub is_resurrect_spell {
    my $self = shift;
    return $self->get_effect() eq 'resurrect';
}

sub targets_enemy {
    my $self = shift;
    my $target = $self->get_target();
    return $target =~ /enemy/;
}

sub targets_ally {
    my $self = shift;
    my $target = $self->get_target();
    return $target =~ /ally/;
}

sub targets_single {
    my $self = shift;
    my $target = $self->get_target();
    return $target =~ /single/;
}

sub targets_group {
    my $self = shift;
    my $target = $self->get_target();
    return $target =~ /group/;
}

sub targets_all {
    my $self = shift;
    my $target = $self->get_target();
    return $target =~ /all/;
}

sub can_be_learned_by {
    my ($self, $character_class) = @_;
    my $spell_type = $self->get_type();
    
    if ($spell_type eq 'mage') {
        return $character_class eq '魔法使い' || $character_class eq '忍者';
    } elsif ($spell_type eq 'priest') {
        return $character_class eq '僧侶' || $character_class eq '侍';
    }
    
    return 0;
}

sub calculate_damage {
    my ($self, $caster_level, $int_bonus) = @_;
    
    return 0 unless $self->is_damage_spell();
    
    my $power = $self->get_power();
    my $damage = 0;
    
    if ($power =~ /(\d+)d(\d+)(\+(\d+))?/) {
        my ($dice_count, $dice_size, $bonus) = ($1, $2, $4 || 0);
        
        for (1..$dice_count) {
            $damage += int(rand($dice_size)) + 1;
        }
        
        $damage += $bonus;
        $damage += int($int_bonus / 3);
        $damage += int($caster_level / 2);
    }
    
    return $damage;
}

sub calculate_healing {
    my ($self, $caster_level, $pie_bonus) = @_;
    
    return 0 unless $self->is_healing_spell();
    
    my $power = $self->get_power();
    my $healing = 0;
    
    if ($power =~ /(\d+)d(\d+)(\+(\d+))?/) {
        my ($dice_count, $dice_size, $bonus) = ($1, $2, $4 || 0);
        
        for (1..$dice_count) {
            $healing += int(rand($dice_size)) + 1;
        }
        
        $healing += $bonus;
        $healing += int($pie_bonus / 3);
        $healing += int($caster_level / 2);
    }
    
    return $healing;
}

sub get_spells_by_level_and_type {
    my ($class, $level, $type) = @_;
    
    load_spells() unless $spells_data;
    
    my @spells = ();
    
    for my $spell_name (keys %$spells_data) {
        my $spell_data = $spells_data->{$spell_name};
        
        if ($spell_data->{level} <= $level && $spell_data->{type} eq $type) {
            push @spells, $spell_name;
        }
    }
    
    return @spells;
}

sub get_initial_spells_for_character {
    my ($class, $character_class, $int, $pie) = @_;
    
    my @spells = ();
    my $stat = $character_class eq '魔法使い' || $character_class eq '忍者' ? $int : $pie;
    my $type = $character_class eq '魔法使い' || $character_class eq '忍者' ? 'mage' : 'priest';
    
    if ($stat >= 11) {
        my @available = $class->get_spells_by_level_and_type(1, $type);
        push @spells, @available[0..0] if @available;
    }
    
    return @spells;
}

sub roll_success {
    my ($self, $target_level) = @_;
    
    my $base_rate = $self->get_success_rate();
    my $level_modifier = $target_level * 5;
    my $final_rate = $base_rate - $level_modifier;
    
    $final_rate = 5 if $final_rate < 5;
    $final_rate = 95 if $final_rate > 95;
    
    return (int(rand(100)) + 1) <= $final_rate;
}

sub get_all_spell_names {
    my $class = shift;
    load_spells() unless $spells_data;
    return keys %$spells_data;
}

sub spell_exists {
    my ($class, $name) = @_;
    load_spells() unless $spells_data;
    return exists $spells_data->{$name};
}

1;