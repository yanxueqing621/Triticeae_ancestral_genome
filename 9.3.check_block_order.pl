#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use List::Util 'uniq';

my ($infile, $outfile) = ($ARGV[0], $ARGV[1]);
my $io_in = io($infile)->chomp;
my $io_out = io("$outfile");
my %chr2lines;
while (defined (my $line = $io_in->getline)) {
  my @cols = split /\t/, $line;
  push @{$chr2lines{$cols[0]}}, $line;
}

for my $chr (sort keys %chr2lines) {
  my @lines = @{$chr2lines{$chr}};
  my @blocks_order;
  my %block2lines;

  for my $line (@lines) {
    my @cols = split /\t/, $line;
    push @blocks_order, $cols[1];
    push @{$block2lines{$cols[1]}}, $line;
  }

  @blocks_order = uniq @blocks_order;
  my %block2range = get_block_range(%block2lines);

  for my $block (@blocks_order) {
    my $dd_start = $block2range{$block}{dd}{start};
    my $dd_end = $block2range{$block}{dd}{end};
    my $dd_chr = $block2range{$block}{dd}{chr};
    my $aa_start = $block2range{$block}{aa}{start};
    my $aa_end = $block2range{$block}{aa}{end};
    my $aa_chr = $block2range{$block}{aa}{chr};
    my $bb_start = $block2range{$block}{bb}{start};
    my $bb_end = $block2range{$block}{bb}{end};
    my $bb_chr = $block2range{$block}{bb}{chr};
    $io_out->println("$chr\t$block\t$dd_chr:$dd_start-$dd_end\t$aa_chr:$aa_start-$aa_end\t$bb_chr:$bb_start-$bb_end");
  }

}

sub get_block_range {
  my %block2lines = @_;
  my %block2range;
  for my $block (keys %block2lines) {
    my @lines = @{$block2lines{$block}};
    my (@dd, @aa, @bb, @tel, @hv);
    for my $line (@lines) {
      my @cols = split /\t/, $line;
      push @dd, $cols[2] if $cols[2] ne 'NA';
      push @aa, $cols[3] if $cols[3] ne 'NA';
      push @bb, $cols[4] if $cols[4] ne 'NA';
    }
    $block2range{$block}{dd} = get_range(@dd);
    $block2range{$block}{aa} = get_range(@aa);
    $block2range{$block}{bb} = get_range(@bb);
  }
  return %block2range;
}


sub get_range {
    my @genes = @_;
    my %range;
    my ($chr) = $genes[0] =~/^(.+?)_/;
    my ($start) = $genes[0] =~/.+_(\d+)/;
    my ($end) = $genes[-1] =~/.+_(\d+)/;

    $range{chr} = defined $chr ? $chr : 'NA';
    $range{start} = defined $start ? $start : 'NA';
    $range{end} = defined $end ? $end : 'NA';
    say Dumper \%range unless $genes[0] =~/^(.+\d)_/;
    return \%range;
}

=cut

sub get_range {
    my @genes = @_;
    my @genes_index = map {
      my ($index) = $_ =~/_(\d+)/;
      $index;
    } @genes;
    my %range;
    my @genes_sort = sort {$a <=> $b} @genes_index;
    my ($chr) = $genes[0] =~/^(.+\d)_/;
    $range{chr} = $chr || 'NA';
    $range{start} = $genes_sort[0] || 'NA';
    $range{end} = $genes_sort[-1] || 'NA';
    say Dumper \%range unless $genes[0] =~/^(.+\d)_/;
    return \%range;
}

