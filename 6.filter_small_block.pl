#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/median/;

die "perl 6.filter_small_block.pl o5.CPG_newGID_newblockID.txt o6.CPG_newGID_newblockID.filter.txt" unless @ARGV;
my ($infile, $outfile) = @ARGV;
filter_small_block($infile, $outfile);

sub filter_small_block {
  my ($infile, $outfile) = @_;
  my @lines = io($infile)->chomp->getlines;
  my $io_out = io($outfile);
  my %block2num;
  for my $line (@lines) {
    my @cols = split /\t/, $line;
    $block2num{$cols[0]}++;
  }

  # block 2 num
  #print genes number in each block
  say "Block ID\tGene Num";
  for my $key (sort {abs($block2num{$a}) <=> abs($block2num{$b})} keys %block2num) {
    say "$key\t$block2num{$key}";
  }

  for my $line (@lines) {
    my @cols = split /\t/, $line;
    $io_out->println($line) if $block2num{$cols[0]} >=5 ;
  }

}

