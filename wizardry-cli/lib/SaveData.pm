package SaveData;

use strict;
use warnings;
use utf8;
use JSON;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub save_game {
    my ($self, $filename, $game_data) = @_;
    
    unless (-d 'saves') {
        mkdir 'saves' or die "セーブディレクトリを作成できません: $!";
    }
    
    my $filepath = "saves/$filename.json";
    
    eval {
        open my $fh, '>:encoding(UTF-8)', $filepath or die $!;
        print $fh encode_json($game_data);
        close $fh;
        1;
    };
    
    if ($@) {
        print "セーブに失敗しました: $@\n";
        return 0;
    } else {
        print "ゲームをセーブしました: $filepath\n";
        return 1;
    }
}

sub load_game {
    my ($self, $filename) = @_;
    my $filepath = "saves/$filename.json";
    
    unless (-f $filepath) {
        print "セーブファイルが見つかりません: $filepath\n";
        return undef;
    }
    
    my $game_data;
    
    eval {
        open my $fh, '<:encoding(UTF-8)', $filepath or die $!;
        local $/;
        my $json_text = <$fh>;
        close $fh;
        $game_data = decode_json($json_text);
    };
    
    if ($@) {
        print "ロードに失敗しました: $@\n";
        return undef;
    } else {
        print "ゲームをロードしました: $filepath\n";
        return $game_data;
    }
}

sub list_saves {
    my $self = shift;
    
    unless (-d 'saves') {
        print "セーブファイルがありません。\n";
        return [];
    }
    
    opendir(my $dh, 'saves') or die "セーブディレクトリを開けません: $!";
    my @files = grep { /\.json$/ && !/^[^_]*_[^_]*\.json$/ } readdir($dh);  # Exclude character exports
    closedir($dh);
    
    if (@files) {
        print "\n=== セーブファイル一覧 ===\n";
        for my $i (0..$#files) {
            my $filename = $files[$i];
            $filename =~ s/\.json$//;
            print(($i + 1) . ". $filename\n");
        }
        print "\n";
    } else {
        print "セーブファイルがありません。\n";
    }
    
    return \@files;
}

sub delete_save {
    my ($self, $filename) = @_;
    my $filepath = "saves/$filename.json";
    
    unless (-f $filepath) {
        print "セーブファイルが見つかりません: $filepath\n";
        return 0;
    }
    
    if (unlink $filepath) {
        print "セーブファイルを削除しました: $filepath\n";
        return 1;
    } else {
        print "セーブファイルの削除に失敗しました: $!\n";
        return 0;
    }
}

sub export_character_json {
    my ($self, $filename, $party) = @_;
    
    my @char_data;
    for my $char (@$party) {
        push @char_data, {
            name => $char->{name},
            class => $char->{class},
            race => $char->{race},
            alignment => $char->{alignment},
            level => $char->{level},
            exp => $char->{exp},
            hp => $char->{hp},
            max_hp => $char->{max_hp},
            mp => $char->{mp},
            max_mp => $char->{max_mp},
            str => $char->{str},
            int => $char->{int},
            pie => $char->{pie},
            vit => $char->{vit},
            agi => $char->{agi},
            luc => $char->{luc},
            ac => $char->{ac},
            position => $char->{position},
            spells => $char->{spells}
        };
    }
    
    my $json_data = {
        export_date => scalar(localtime),
        party => \@char_data
    };
    
    my $filepath = "saves/$filename.json";
    
    eval {
        open my $fh, '>:encoding(UTF-8)', $filepath or die $!;
        print $fh encode_json($json_data);
        close $fh;
        print "パーティをJSONで出力しました: $filepath\n";
        return 1;
    };
    
    if ($@) {
        print "JSON出力に失敗しました: $@\n";
        return 0;
    }
}

sub create_backup {
    my ($self, $game_data) = @_;
    
    my $timestamp = time();
    my $backup_filename = "auto_backup_$timestamp";
    
    return $self->save_game($backup_filename, $game_data);
}

sub get_save_info {
    my ($self, $filename) = @_;
    my $filepath = "saves/$filename.json";
    
    unless (-f $filepath) {
        return undef;
    }
    
    my @stat = stat($filepath);
    my $size = $stat[7];
    my $mtime = $stat[9];
    
    return {
        filename => $filename,
        size => $size,
        last_modified => scalar(localtime($mtime))
    };
}

1;