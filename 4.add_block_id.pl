#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine qw/median/;


die "perl 4.add_block_id.pl o3.CPG_new_GID.txt o4.CPG_newGID_blockID.txt" unless @ARGV;
my ($infile, $outfile) = @ARGV;

sub get_chr2lines {
  my $io_in = io(shift)->chomp;
  my %chr2lines;
  while (defined (my $line = $io_in->getline)) {
    my ($chr) = $line =~/^(.+?)_/;
    push @{$chr2lines{$chr}}, $line;
  }
  return %chr2lines;
}
my %chr2lines = get_chr2lines($infile);

#say Dumper [sort keys %chr2lines];
for my $chr (sort keys %chr2lines) {
  my @chr_lines = @{$chr2lines{$chr}};
  add_blockID(@chr_lines);
  #filter_small_block();
}



sub add_blockID {
  my @lines = @_;
  my (@aa, @bb, @dd);
  for my $line (@lines) {
    my @cols = split /\t/, $line;
    push @dd, $cols[0];
    push @aa, $cols[1];
    push @bb, $cols[2];
  }
  my @breakpoints = get_boundary(\@dd, \@aa, \@bb);
  #say Dumper \@breakpoints;
  my %line2blockID = line2blockID(@breakpoints);
  #say Dumper \%line2blockID;
  my $io_out =io("$outfile");
  for (my $i = 0; $i < @lines; $i++) {
    $io_out->appendln("$line2blockID{$i}\t$lines[$i]");
  }
}

sub filter_small_block {
  my @lines = io("$outfile")->chomp->getlines;
  my $io_out = io("$outfile.filter");
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
    $io_out->println($line) if $block2num{$cols[0]} > 4;
  }

}

sub get_boundary {
  my ($dd, $aa, $bb) = @_;
  my @dds = @$dd;
  my @aas = @$aa;
  my @bbs = @$bb;
  my @breakpoints = (0);
  for (my $i = 1; $i < @dds; $i++) {
    my ($chr_a, $a_index) = $aas[$i] =~/(\d)_\d+_(\d+)/;
    my ($chr_b, $b_index) = $bbs[$i] =~/(\d)_\d+_(\d+)/;
    my ($chr_a_previous, $a_index_previous) = $aas[$i-1] =~/(\d)_\d+_(\d+)/;
    my ($chr_b_previous, $b_index_previous) = $bbs[$i-1] =~/(\d)_\d+_(\d+)/;
    #say "$chr_a\t$chr_b\t$chr_a_previous\t$chr_b_previous";
    #say "$a_index\t$a_index_previous\t$b_index\t$b_index_previous";
    # interchromosome translocation  is a block
    if ($chr_a_previous ne $chr_a  or $chr_b_previous ne $chr_b) {
      push @breakpoints,$i;
      next;
    }

    my $v_a = abs($a_index - $a_index_previous);
    my $v_b = abs($b_index - $b_index_previous);
    push @breakpoints,$i if ($v_a > 1 or $v_b > 1);
  }
  push @breakpoints, $#dds + 1;
  return  @breakpoints;
}

sub line2blockID {
  my @breakpoints = @_;
  my %line2id;
  my $block_id_tmp = 0;
  for (my $i = 0; $i < @breakpoints - 1; $i++) {
    $block_id_tmp++;
    my $start = $breakpoints[$i];
    my $end = $breakpoints[$i+1];
    for (my $j = $start; $j < $end; $j++) {
      $line2id{$j} = $block_id_tmp;
    }
  }
  return %line2id;
}


