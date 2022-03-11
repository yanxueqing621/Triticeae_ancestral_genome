#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/median/;

die "perl 10.convert_to_old_id.pl o9.ancient_genome.txt o10.ancient_genome_oid.txt" unless @ARGV;
# o8.ancient_genome.txt o9.ancient_genome.txt.oldID
my ($infile, $outfile) = @ARGV;
my @lines =  io($infile)->chomp->getlines;
my $io_out = io($outfile);
for my $line (@lines) {
  my @cols = split /\t/, $line;
  for (my $i = 0; $i < @cols; $i++) {
    if ($cols[$i] =~/_/) {
      $cols[$i] =~s/(.+_\d+)(_\d+)/$1/;
    }
  }
  $io_out->println(join "\t", @cols);
}

