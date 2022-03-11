#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/median/;

die "perl 8.make_mgra_input_block_order.pl tel hv agk o7.CPG_newGID_newblockID_filter_newblockID.txt o8.mgra_input.txt" unless @ARGV;
my ($spe1, $spe2, $spe3,$infile, $outfile) = @ARGV;

make_block_order_file($infile, $outfile);
sub make_block_order_file {
  my $io_in = io("$infile")->chomp;
  my $io_out =io("$outfile");
  my (%aa, %bb, %dd, %tel, %hv);
  while (my $line = $io_in->getline) {
    my @cols = split /\t/, $line;
    my ($chr_dd) = $cols[1] =~/(\d)_\d+_/;
    my ($chr_aa) = $cols[2] =~/(\d)_\d+_/;
    my ($chr_bb) = $cols[3] =~/(\d)_\d+_/;

    push @{$dd{$chr_dd}{$cols[0]}}, $cols[1];
    push @{$aa{$chr_aa}{$cols[0]}}, $cols[2];
    push @{$bb{$chr_bb}{$cols[0]}}, $cols[3];
  }
  my $dd_order = block_order_genome(%dd);
  my $aa_order = block_order_genome(%aa);
  my $bb_order = block_order_genome(%bb);
  $io_out->println(">$spe1\n$dd_order");
  $io_out->println(">$spe2\n$aa_order");
  $io_out->println(">$spe3\n$bb_order");
}

sub block_order_genome {
  my %chr2block2genes = @_;
  my $spe_block_order;
  for my $chr (sort {$a <=> $b} keys %chr2block2genes) {
    my %block2genes = %{$chr2block2genes{$chr}};
    my @chr_block_order = block_order(%block2genes);
    #$spe_block_order .= join (" ", $chr,@chr_block_order, '$') . "\n";
    $spe_block_order .= join (" ", @chr_block_order, '$') . "\n";
  }
  return $spe_block_order;
}

sub block_order {
  my %block2genes = @_;
  my %block2median;
  # 1.get block to median value
  my @medians;
  for my $block ( keys %block2genes) {
    my @genes = @{$block2genes{$block}};
    say Dumper $block if $#genes == 0;
    say Dumper \%block2genes if $#genes == 0;
    next if $#genes == 0;
    #say Dumper \@genes;

    # 2. add minus strands 
    my $sum = 0;
    for (my $i = 1; $i < @genes; $i++) {
      my ($g1_index) = $genes[$i-1] =~/_.+_(\d+)$/;
      my ($g2_index) = $genes[$i] =~/_.+_(\d+)$/;
      my $sign = $g2_index - $g1_index;
      say $block if $sign ==0;
      $sign = $sign / abs($sign);
      $sum += $sign;
    }
    my @genes_index = map {my ($index) = $_ =~/_.+_(\d+)$/; $index} @genes;
    #say Dumper \@genes_index;
    #say "11";
    if ($sum == 0) {
      say Dumper \@genes;
      say Dumper \@genes_index;
    }

    
    $block2median{$block} = median(@genes_index) * ($sum / abs($sum));
    #say "$block \t $block2median{$block}";
  }

  # 3. get block new index and sign (reversal)
  my @sorted_indexs = map {
    my $median = $block2median{$_};
    my $sign = $median/ abs($median);
    $sign * $_;
  } sort {abs($block2median{$a}) <=> abs($block2median{$b})}  keys %block2median;
  return @sorted_indexs;
}

