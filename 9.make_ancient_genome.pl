#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/median/;

die "perl 9.make_ancient_genome.pl o7.CPG_newGID_newblockID_filter_newblockID.txt o8_out_mgra_H2.txt7 o9.ancient_genome.txt\n" unless @ARGV;
my ($synteny_file, $car_file, $outfile) = @ARGV;

make_ancestral_genome ($synteny_file, $car_file, $outfile);
sub make_ancestral_genome {
  my ($f_synteny, $f_car, $outfile) = @_;

  # get hash variable containing block to line
  my %block2lines;
  my $io_in = io("$f_synteny")->chomp;
  while (my $line = $io_in->getline) {
    my @cols = split /\t/, $line;
    push @{$block2lines{$cols[0]}}, $line;
  }

  #say Dumper \%block2lines;

  # get car
  my @ancient_chrs;
  my @lines = io("$f_car")->chomp->getlines;
  for (my $i = 0; $i < @lines; $i++) {
      my @blocks = split /\s+/, $lines[$i];
      pop @blocks;
      push @ancient_chrs, \@blocks;
  }

  # say Dumper \@ancient_chrs;



  # output ancient genome
  my $io_out = io("$outfile");

  for (my $i = 0; $i < @ancient_chrs; $i++) {
    my $chr = "chr". ($i+1);
    my @chr_blocks = @{$ancient_chrs[$i]};
    say Dumper \@chr_blocks;
    for my $block (@chr_blocks) {
      say "###$block";
      my $block_id = abs $block;
      #say $block_id;
      say "$block not exists" unless $block2lines{$block_id};
      my @block_lines = @{$block2lines{$block_id}};

      my $block_sign = $block > 0 ? "+" : '-';
      @block_lines = reverse @block_lines if $block_sign eq '-';
      for my $block_line (@block_lines) {
        $block_line =~s/^$block_id/$block/;
        $io_out->println("$chr\t$block_line");
      }
    }
  }

}

