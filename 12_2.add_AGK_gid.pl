#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;

my ($infile, $outfile) = @ARGV;
my $io_in = io("$infile")->chomp;
my $io_out = io("$outfile");

my %chr2pos;
while (defined (my $line = $io_in->getline)) {
  my @cols = split /\t/, $line;
  $chr2pos{$cols[0]}++;
  my $new_chr = $cols[0];
  $new_chr =~s/chr/tribe/;
  my $gid_new = "$new_chr". "_$chr2pos{$cols[0]}";
  say $gid_new;
  $io_out->println(join "\t", @cols[0..1], $gid_new, @cols[2..4]);
}

