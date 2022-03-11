#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/median/;


die "perl 5.modified_block.pl o4.CPG_newGID_blockID.txt o5.CPG_newGID_newblockID.txt" unless @ARGV;
my ($infile, $outfile) = @ARGV;

sub get_chr2lines {
  my $io_in = io(shift)->chomp;
  my %chr2lines;
  while (defined (my $line = $io_in->getline)) {
    my ($chr) = $line =~/^\d+\s+(.+?)_/;
    push @{$chr2lines{$chr}}, $line;
  }
  return %chr2lines;
}

my %chr2lines = get_chr2lines($infile);
my $block_max = 0;
my $io_out = io("$outfile");
for my $chr (sort keys %chr2lines) {
  my @chr_lines = @{$chr2lines{$chr}};
  my $bid;
  for my $line (@chr_lines) {
    ($bid) = $line =~/^(\d+)/;
    $bid += $block_max;
    $line =~s/^(\d+)/$bid/;
    $io_out->println($line);
  }
  $block_max = $bid;
}
