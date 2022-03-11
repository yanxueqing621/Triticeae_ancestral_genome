#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/sum median mean/;
use Statistics::R;

die "stat_collinearity_block_ks_notype.pl collinearity 5(genenum) 500(score)\n" unless @ARGV;
my ($col_file, $gene_n, $score_filter) = @ARGV;
$gene_n ||= 5;
$score_filter ||= 500;

say $gene_n;
say $score_filter;

my $io_collinearity = io("$col_file");
my ($header, %block2content);
my $block;
my %block2header;
while (defined (my $line = $io_collinearity->getline)) {
  if ($line =~/^#/) {
    if ($line =~/^## (Alignment \d+)/) {
      $block = $1;
      $block2content{$block} = $line;
      $block2header{$block} = $line;
    } else {
      $header .= $line;
    }
  } else {
    $block2content{$block} .= $line;
  }
}

my $total_block = 0;
my $io_out = io("$io_collinearity.$gene_n.$score_filter");
for my $block (sort keys %block2content) {
  my $header = $block2header{$block};
  my ($score, $gene_num, $chr1, $chr2) = $header =~/score=(.+?)\s+e_value.+N=(\d+)\s+(\S+)&(\S+)/;

  # check content
  #next if ($chr1 =~/Un/);
  #next if ($chr2 =~/Un/);
  next if ($gene_num < $gene_n or $score < $score_filter);
  $io_out->print($block2content{$block});
}
