package Dungeon;

use strict;
use warnings;
use utf8;

sub new {
    my ($class, $width, $height) = @_;
    $width ||= 20;
    $height ||= 20;
    
    my $self = {
        width => $width,
        height => $height,
        floor => 1,
        player_x => 1,
        player_y => 1,
        map => [],
        rooms => [],
        stairs_up => undef,
        stairs_down => undef
    };
    bless $self, $class;
    
    $self->generate_floor();
    return $self;
}

sub generate_floor {
    my $self = shift;
    
    # マップを壁で初期化
    for my $y (0..$self->{height}-1) {
        for my $x (0..$self->{width}-1) {
            $self->{map}->[$y]->[$x] = '#';
        }
    }
    
    # 部屋を生成
    $self->generate_rooms();
    
    # 廊下で部屋を接続
    $self->connect_rooms();
    
    # 階段を配置
    $self->place_stairs();
    
    # プレイヤーを最初の部屋に配置
    if (@{$self->{rooms}}) {
        my $first_room = $self->{rooms}->[0];
        $self->{player_x} = $first_room->{x} + 1;
        $self->{player_y} = $first_room->{y} + 1;
    }
}

sub generate_rooms {
    my $self = shift;
    my $room_attempts = 10;
    
    for (1..$room_attempts) {
        my $width = 3 + int(rand(6));   # 3-8の幅
        my $height = 3 + int(rand(6));  # 3-8の高さ
        my $x = 1 + int(rand($self->{width} - $width - 2));
        my $y = 1 + int(rand($self->{height} - $height - 2));
        
        # 他の部屋と重複しないかチェック
        my $overlaps = 0;
        for my $room (@{$self->{rooms}}) {
            if ($self->rooms_overlap($x, $y, $width, $height, $room)) {
                $overlaps = 1;
                last;
            }
        }
        
        next if $overlaps;
        
        # 部屋を作成
        for my $ry ($y..$y+$height-1) {
            for my $rx ($x..$x+$width-1) {
                $self->{map}->[$ry]->[$rx] = '.';
            }
        }
        
        push @{$self->{rooms}}, {
            x => $x, y => $y,
            width => $width, height => $height,
            center_x => $x + int($width/2),
            center_y => $y + int($height/2)
        };
    }
}

sub rooms_overlap {
    my ($self, $x1, $y1, $w1, $h1, $room2) = @_;
    my ($x2, $y2, $w2, $h2) = ($room2->{x}, $room2->{y}, $room2->{width}, $room2->{height});
    
    return !($x1 + $w1 < $x2 || $x2 + $w2 < $x1 || $y1 + $h1 < $y2 || $y2 + $h2 < $y1);
}

sub connect_rooms {
    my $self = shift;
    
    for my $i (0..@{$self->{rooms}}-2) {
        my $room1 = $self->{rooms}->[$i];
        my $room2 = $self->{rooms}->[$i+1];
        
        $self->create_corridor(
            $room1->{center_x}, $room1->{center_y},
            $room2->{center_x}, $room2->{center_y}
        );
    }
}

sub create_corridor {
    my ($self, $x1, $y1, $x2, $y2) = @_;
    
    # L字型の廊下を作成
    my $current_x = $x1;
    my $current_y = $y1;
    
    # 横方向に移動
    while ($current_x != $x2) {
        $self->{map}->[$current_y]->[$current_x] = '.';
        $current_x += ($x2 > $current_x) ? 1 : -1;
    }
    
    # 縦方向に移動
    while ($current_y != $y2) {
        $self->{map}->[$current_y]->[$current_x] = '.';
        $current_y += ($y2 > $current_y) ? 1 : -1;
    }
    
    $self->{map}->[$current_y]->[$current_x] = '.';
}

sub place_stairs {
    my $self = shift;
    return unless @{$self->{rooms}};
    
    # 上り階段（1階以外）
    if ($self->{floor} > 1) {
        my $room = $self->{rooms}->[0];
        my $x = $room->{x} + int(rand($room->{width}));
        my $y = $room->{y} + int(rand($room->{height}));
        $self->{map}->[$y]->[$x] = '<';
        $self->{stairs_up} = { x => $x, y => $y };
    }
    
    # 下り階段（10階以外）
    if ($self->{floor} < 10) {
        my $room = $self->{rooms}->[-1];  # 最後の部屋
        my $x = $room->{x} + int(rand($room->{width}));
        my $y = $room->{y} + int(rand($room->{height}));
        $self->{map}->[$y]->[$x] = '>';
        $self->{stairs_down} = { x => $x, y => $y };
    }
}

sub display {
    my $self = shift;
    
    print "\n=== " . $self->{floor} . "階 ===\n";
    
    my $view_size = 7;  # 表示範囲（7x7）
    my $start_x = $self->{player_x} - int($view_size / 2);
    my $start_y = $self->{player_y} - int($view_size / 2);
    
    $start_x = 0 if $start_x < 0;
    $start_y = 0 if $start_y < 0;
    $start_x = $self->{width} - $view_size if $start_x + $view_size > $self->{width};
    $start_y = $self->{height} - $view_size if $start_y + $view_size > $self->{height};
    
    for my $y ($start_y..$start_y + $view_size - 1) {
        for my $x ($start_x..$start_x + $view_size - 1) {
            if ($x == $self->{player_x} && $y == $self->{player_y}) {
                print '@';
            } elsif ($x >= 0 && $x < $self->{width} && $y >= 0 && $y < $self->{height}) {
                print $self->{map}->[$y]->[$x];
            } else {
                print ' ';
            }
        }
        print "\n";
    }
    
    print "\n方向キー: w(北) s(南) a(西) d(東) / <(上り階段) >(下り階段)\n";
    print "現在地: (" . $self->{player_x} . ", " . $self->{player_y} . ")\n";
}

sub move_player {
    my ($self, $direction) = @_;
    
    my ($new_x, $new_y) = ($self->{player_x}, $self->{player_y});
    
    if ($direction eq 'w') { $new_y--; }      # 北
    elsif ($direction eq 's') { $new_y++; }   # 南
    elsif ($direction eq 'a') { $new_x--; }   # 西
    elsif ($direction eq 'd') { $new_x++; }   # 東
    else { return 0; }
    
    # 境界チェック
    if ($new_x < 0 || $new_x >= $self->{width} || 
        $new_y < 0 || $new_y >= $self->{height}) {
        print "そこは壁だ！\n";
        return 0;
    }
    
    # 壁チェック
    if ($self->{map}->[$new_y]->[$new_x] eq '#') {
        print "そこは壁だ！\n";
        return 0;
    }
    
    $self->{player_x} = $new_x;
    $self->{player_y} = $new_y;
    
    # 階段チェック
    if ($self->{map}->[$new_y]->[$new_x] eq '<') {
        return 'stairs_up';
    } elsif ($self->{map}->[$new_y]->[$new_x] eq '>') {
        return 'stairs_down';
    }
    
    # ランダムエンカウント（15%の確率）
    if (int(rand(100)) < 15) {
        return 'encounter';
    }
    
    return 1;
}

sub change_floor {
    my ($self, $direction) = @_;
    
    if ($direction eq 'up' && $self->{floor} > 1) {
        $self->{floor}--;
        print "階段を上って " . $self->{floor} . "階に到着した。\n";
    } elsif ($direction eq 'down' && $self->{floor} < 10) {
        $self->{floor}++;
        print "階段を下りて " . $self->{floor} . "階に到着した。\n";
    } else {
        return 0;
    }
    
    # 新しい階を生成
    $self->generate_floor();
    return 1;
}

sub get_current_floor {
    my $self = shift;
    return $self->{floor};
}

sub is_on_stairs {
    my $self = shift;
    my $current = $self->{map}->[$self->{player_y}]->[$self->{player_x}];
    return $current eq '<' || $current eq '>';
}

1;