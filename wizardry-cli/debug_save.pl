#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use SaveData;
use Data::Dumper;

my $save_data = SaveData->new();
my $loaded_data = $save_data->load_game("test_save");

print "Loaded data:\n";
print Dumper($loaded_data);

if ($loaded_data && exists $loaded_data->{test}) {
    print "Test field exists: " . $loaded_data->{test} . "\n";
    print "Comparison result: " . ($loaded_data->{test} eq "テストデータ" ? "MATCH" : "NO MATCH") . "\n";
} else {
    print "Test field does not exist\n";
}