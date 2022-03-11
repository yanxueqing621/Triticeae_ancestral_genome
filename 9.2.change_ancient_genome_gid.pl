#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;

my ($infile, $outfile) = @ARGV;
my $io_in = io("$infile")->chomp;
my $io_out =io("$outfile");

my @lines = $io_in->getlines;
my (@aa, @bb, @dd, );
for my $line (@lines) {
  my @cols = split /\t/, $line;
  push @dd, $cols[2];
  push @aa, $cols[3];
  push @bb, $cols[4];
}
my %old2new;
newid(@dd);
newid(@aa);
newid(@bb);
#say Dumper \%gene2num;

for my $line (@lines) {
  my @cols = split /\t/, $line;
  for (my $i = 2; $i < @cols; $i++) {
    $cols[$i] = $old2new{$cols[$i]};
  }
  $io_out->println(join("\t", @cols));
}


sub newid {
  my @arr = @_;
  my %chr2genes;
  for my $gene (@arr) {
    my ($chr) = $gene =~/(.+?)_\d+/;
    push @{$chr2genes{$chr}}, $gene;
  }

  
  for my $chr (keys %chr2genes) {
    my @chr_genes = @{$chr2genes{$chr}};
    my @chr_genes_sort = sort {
      my ($n1) = $a =~/_(\d+)$/;
      my ($n2) = $b =~/_(\d+)$/;
      say $a unless $n1;
      say $b unless $n2;
      $n1 <=> $n2;
    } @chr_genes;
    for (my $i = 0; $i < @chr_genes_sort; $i++) {
      my $raw = $chr_genes_sort[$i];
      my $new = $raw;
      $new =~s/\d+$/$i/g;
      $old2new{$raw} = $new;
    }
  }

}




