#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/median/;
use List::Util 'uniq';

die "perl 7.modified_blockid.pl o6.CPG_newGID_newblockID.filter.txt o7.CPG_newGID_newblockID_filter_newblockID.txt" unless @ARGV;
my ($infile, $outfile) = @ARGV;
my @lines = io($infile)->getlines;
my @bid = map {
  my @cols = split /\t/, $_;
  $cols[0];
} @lines;


my @bid_sort = sort {$a <=> $b} uniq(@bid);
my %old2new;

for (my $i = 0; $i < @bid_sort; $i++) {
  $old2new{$bid_sort[$i]} = $i+1;
}

my $io_out = io($outfile);
for my $line (@lines) {
  my @cols = split /\t/, $line;
  $cols[0] = $old2new{$cols[0]};
  $io_out->println(join "\t", @cols);
}

