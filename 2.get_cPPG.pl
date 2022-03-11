#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;

die "perl 2.get_cPPG.pl hv agk o1.tel_vs_other.colinear.txt o2.cPG_genelist.txt" unless @ARGV;
my ($spe2, $spe3, $infile, $outfile) = @ARGV;
my $io_in = io("$infile")->chomp;
my $io_out = io("$outfile");

while (defined (my $line = $io_in->getline)) {
  my @cols = split /\t/, $line;
  next unless $cols[1] =~/^$spe2/;
  next unless $cols[2] =~/^$spe3/;
  $io_out->println($line);
}


