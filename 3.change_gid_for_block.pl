#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;

my ($infile, $outfile) = @ARGV;
my $io_in = io("$infile")->chomp;
my $io_out =io("$outfile");


my @lines = $io_in->getlines;
my (@aa, @bb, @dd);
for my $line (@lines) {
  my @cols = split /\t/, $line;
  say $line unless $cols[1];
  say $line unless $cols[2];
  push @dd, $cols[0];
  push @aa, $cols[1];
  push @bb, $cols[2];
}
my %old2new;
newid( @dd);
newid(  @aa);
newid(  @bb);
#say Dumper \%gene2num;

for my $line (@lines) {
  my @cols = split /\t/, $line;
  for (my $i = 0; $i < @cols; $i++) {
    $cols[$i] = $cols[$i] =~/_/ ? $old2new{$cols[$i]} : "NA";
  }
  $io_out->println(join("\t", @cols));
  
}


sub newid {
  my @arr = @_;
  my %chr2genes;
  for my $gene (@arr) {
    my ($chr) = $gene =~/(.+)_\d+/;
    push @{$chr2genes{$chr}}, $gene;
  }

  
  for my $chr (keys %chr2genes) {
    my @chr_genes = @{$chr2genes{$chr}};
    my @chr_genes_sort = sort {
      my ($n1) = $a =~/_(\d+)/;
      my ($n2) = $b =~/_(\d+)/;
      say $a unless $n1;
      say $b unless $n2;
      $n1 <=> $n2;
    } @chr_genes;
    for (my $i = 0; $i < @chr_genes_sort; $i++) {
      $old2new{$chr_genes_sort[$i]} = $chr_genes_sort[$i] . "_$i";
    }
  }

}




