#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;

my ($infile, $outfile, $outpep) = @ARGV;
my $io_in = io("$infile")->chomp;
my $io_out = io("$outfile");

my %chr2pos;
my @gids;
my @gids_new;
while (defined (my $line = $io_in->getline)) {
  my @cols = split /\t/, $line;
  $chr2pos{$cols[0]}++;
  my $gid_new = "$cols[0]". "_$chr2pos{$cols[0]}";
  my $gid = $cols[2] ne 'NA' ? $cols[2]
          : $cols[3] ne 'NA' ? $cols[3]
          :                    $cols[4];
  $io_out->println(join "\t", $cols[0], $gid_new, $gid, $chr2pos{$cols[0]}, $chr2pos{$cols[0]}+1);
  push @gids, $gid;
  push @gids_new, $gid_new;
}

my %gene2fas;
get_fas("evaluation/tel.cds");
get_fas("evaluation/hv.cds");
get_fas("evaluation/awk.cds");

my $io_out2 = io("$outpep");

for (my $i = 0; $i < @gids; $i++) {
  $io_out2->println(">$gids_new[$i]   $gids[$i]\n$gene2fas{$gids[$i]}");
}




sub get_fas {
  my $io_in = io(shift)->chomp;
  my $name;
  while (my $line  = $io_in->getline) {
    if ($line =~/^>(.+)/) {
      $name = $1;
    } else {
      $gene2fas{$name} = $line;
    }
  }
}





