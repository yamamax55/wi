package StatusEffect;
use strict;
use warnings;
use utf8;

my %status_effects = (
    poison => {
        name => '毒',
        duration => 10,
        damage_per_turn => 2,
        message => 'は毒に侵されている！',
        color => "\033[32m"
    },
    paralysis => {
        name => '麻痺',
        duration => 3,
        skip_turn => 1,
        message => 'は麻痺して動けない！',
        color => "\033[33m"
    },
    sleep => {
        name => '睡眠',
        duration => 5,
        skip_turn => 1,
        wake_on_damage => 1,
        message => 'は眠っている...',
        color => "\033[36m"
    },
    silence => {
        name => '沈黙',
        duration => 5,
        block_magic => 1,
        message => 'は魔法を使えない！',
        color => "\033[35m"
    },
    stone => {
        name => '石化',
        duration => -1,
        skip_turn => 1,
        message => 'は石になっている！',
        color => "\033[37m"
    },
    curse => {
        name => '呪い',
        duration => -1,
        lock_equipment => 1,
        message => 'は呪われている！',
        color => "\033[31m"
    }
);

sub new {
    my ($class, $type, $duration) = @_;
    
    return undef unless exists $status_effects{$type};
    
    my $self = {
        type => $type,
        duration => $duration || $status_effects{$type}->{duration},
        data => { %{$status_effects{$type}} }
    };
    
    bless $self, $class;
    return $self;
}

sub get_effect_data {
    my ($self, $type) = @_;
    return $status_effects{$type} if $type;
    return $status_effects{$self->{type}};
}

sub get_name {
    my $self = shift;
    return $self->{data}->{name};
}

sub get_message {
    my $self = shift;
    return $self->{data}->{message};
}

sub get_color {
    my $self = shift;
    return $self->{data}->{color} || "\033[0m";
}

sub should_skip_turn {
    my $self = shift;
    return $self->{data}->{skip_turn} || 0;
}

sub blocks_magic {
    my $self = shift;
    return $self->{data}->{block_magic} || 0;
}

sub locks_equipment {
    my $self = shift;
    return $self->{data}->{lock_equipment} || 0;
}

sub wakes_on_damage {
    my $self = shift;
    return $self->{data}->{wake_on_damage} || 0;
}

sub get_damage_per_turn {
    my $self = shift;
    return $self->{data}->{damage_per_turn} || 0;
}

sub get_duration {
    my $self = shift;
    return $self->{duration};
}

sub is_permanent {
    my $self = shift;
    return $self->{duration} == -1;
}

sub tick {
    my $self = shift;
    return 0 if $self->{duration} == -1;
    
    $self->{duration}--;
    return $self->{duration} <= 0;
}

sub reset_duration {
    my ($self, $duration) = @_;
    $self->{duration} = $duration || $status_effects{$self->{type}}->{duration};
}

sub get_all_effect_types {
    return keys %status_effects;
}

sub is_valid_type {
    my ($class, $type) = @_;
    return exists $status_effects{$type};
}

sub apply_effect {
    my ($self, $character) = @_;
    
    my $damage = $self->get_damage_per_turn();
    if ($damage > 0 && $character->is_alive()) {
        $character->take_damage($damage);
        return "$character->{name} は毒で ${damage} のダメージを受けた！";
    }
    
    return "";
}

sub can_act {
    my ($self) = @_;
    return !$self->should_skip_turn();
}

sub can_cast_magic {
    my ($self) = @_;
    return !$self->blocks_magic();
}

sub can_change_equipment {
    my ($self) = @_;
    return !$self->locks_equipment();
}

sub should_wake_on_damage {
    my ($self) = @_;
    return $self->wakes_on_damage();
}

1;