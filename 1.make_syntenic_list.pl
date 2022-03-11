#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;

die "perl 1.make_syntenic_list.pl tel hv agk  tel.gff o1.tel_vs_other.colinear.txt\n" unless @ARGV;

my ($spe1, $spe2, $spe3, $spe1gff, $outfile) = @ARGV;
my %dd2others;

fill_col($spe1, $spe2, 5, 500);
fill_col($spe1, $spe3, 5, 500);

sub fill_col {
  my ($s1, $s2, $gene_num, $score) = @_;
  my $filename = $s1 . "_$s2.collinearity." . "$gene_num.$score";
  my $io_in = io("$filename")->chomp;
  say "$io_in";
  my ($block, $strand);
  while (my $line = $io_in->getline) {
    if ($line =~/^#/) {
      if ($line =~/Alignment/) {
        my ($block, $strand) = $line =~/Alignment\s+(\d+):.+\s+(\w+)$/;
        say "$block\t$strand";
      } else {
        next;
      }
    } else {
      my ($g1, $g2) = (split /\t/, $line)[1,2];
      my ($g11, $g22) = $g1 =~/$s1/ ? ($g1, $g2) : ($g2, $g1);
      if ($dd2others{$s2}{$g11}{gene}) {
        $dd2others{$s2}{$g11}{gene} .= ",$g22";
      } else {
        $dd2others{$s2}{$g11}{gene} = "$g22";
      }
    }
  }
}
 
# make ordered ddL genelist
my @dd_genelist = map {
  my @cols = split /\t/;
  $cols[1];
} io("$spe1gff")->chomp->getlines;
my $io_out = io("$outfile");
my @others = ($spe2, $spe3);
for my $gene (@dd_genelist) {
  my $newline = "$gene";
  for my $spe (@others) {
    my $g2 = $dd2others{$spe}{$gene}{gene} ? $dd2others{$spe}{$gene}{gene} : "NA";
    $newline .= "\t$g2";
  }
  $io_out->println("$newline");
}
 
