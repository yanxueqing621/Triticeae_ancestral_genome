#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine ":all";

die "perl 11.enrichment_genome.pl o10.ancient_genome_oid.txt tel_hv.collinearity.5.500 o11.ancient_genome_oid_fill_telhv.txt" unless @ARGV;
my ($ancestral_genome_file, $synteny_file, $final_ancestral_genome) = @ARGV;
my @lines_ances_genome = io($ancestral_genome_file)->chomp->getlines;
my ($ref_spe, $hit_spe)  = io($synteny_file)->filename =~/(^.+?)_(\S+?)\./;
#make collinear lines
my @line_tmp = io($ancestral_genome_file)->chomp->getlines;
my ($ref_spe_index, $hit_spe_index);
my @cols_tmp = split /\t/, $line_tmp[0];
my @cols_tmp_na = map { 'NA' } @cols_tmp;
say Dumper \@cols_tmp;
for (my $i = 0; $i < @cols_tmp; $i++) {
  $ref_spe_index = $i if $cols_tmp[$i] =~/^$ref_spe/;
  $hit_spe_index = $i if $cols_tmp[$i] =~/^$hit_spe/;
} 
say "ref: $ref_spe_index \thit$hit_spe_index";

enrichment_ancestral_genome($ancestral_genome_file, $synteny_file, $final_ancestral_genome);
sub enrichment_ancestral_genome {
  my ($ancestral_genome_file, $synteny_file, $final_ancestral_genome) = @_;
  my %col_block2genepair = get_synteny($synteny_file);
  my %col_block2range = get_block_range(%col_block2genepair);
  my %ances_block2gene2lines = get_ancestral_genome($ancestral_genome_file, $synteny_file);
  my %ances_block2range = get_block_range(%ances_block2gene2lines);

  # enrichment ancestral genome
  for my $ances_block (keys %ances_block2range) {
    my ($ances_s, $ances_e, $ances_chr) = ($ances_block2range{$ances_block}{start}, $ances_block2range{$ances_block}{end}, $ances_block2range{$ances_block}{chr});
    my %ances_genes2lines = %{$ances_block2gene2lines{$ances_block}};
    for my $col_block (keys %col_block2range) {
      my ($col_s, $col_e, $col_chr) = ($col_block2range{$col_block}{start}, $col_block2range{$col_block}{end}, $col_block2range{$col_block}{chr});
      # if syntenic block intersect with ancestral block, we fill ancestral block;
      next if $ances_chr ne $col_chr;  # 以1号染色体进行测试

      if (max($ances_s, $col_s) < min($ances_e, $col_e)) {  # judge if intersect
        #say "$ances_block:$ances_s - $ances_e \t $col_block:$col_s - $col_e";
        my ($s, $e) = (max($ances_s, $col_s), min($ances_e, $col_e));  # get intersect regions
        my %col_gene2pair = %{$col_block2genepair{$col_block}};
        my %ances_gene2line = %{$ances_block2gene2lines{$ances_block}};
        for my $gene (keys %col_gene2pair) {
          my ($num) = $gene =~/_(\d+)/;
          if ($num <= $e and $num >= $s) {  # judge syntenic gene pair in intersect regions
            if (not exists $ances_block2gene2lines{$ances_block}{$gene}) {
              my @cols_tmp_na_new = @cols_tmp_na;
              $cols_tmp_na_new[0] = "chr$ances_chr";
              $cols_tmp_na_new[1] = $ances_block;
              $cols_tmp_na_new[$ref_spe_index] = $gene;
              $cols_tmp_na_new[$hit_spe_index] = $col_gene2pair{$gene};
              $ances_block2gene2lines{$ances_block}{$gene} = join "\t", @cols_tmp_na_new;
            }
          }
        }
      }
    }
  }
  #say Dumper \%ances_block2gene2lines;
 
  # get ancestral block order
  my @ances_block_order;
  my %hs_tmp;
  for my $line (@line_tmp) {
    my @cols = split /\t/, $line;
    if (not exists $hs_tmp{$cols[1]}) {
      push @ances_block_order, $cols[1];
      $hs_tmp{$cols[1]} = 1;
    } else {
      next;
    }
  }
  #say Dumper \@ances_block_order;
  # sort and output new ancestral genome
  my $io_out = io($final_ancestral_genome);
 
  for my $block (@ances_block_order) {
    my %ances_gene2line = %{$ances_block2gene2lines{$block}};
    #say $block;
    my %index2genes = map {
      my ($index) = $_ =~/_(\d+)/;
      $index => $_;
    } keys %ances_gene2line;

    my @index_sort = $block > 0 ? sort {$a <=> $b } keys %index2genes : sort {$b <=> $a } keys %index2genes;
    $io_out->println($ances_gene2line{$index2genes{$_}}) for @index_sort;
  }
}

sub get_ancestral_genome {
  my ($genome_f, $synteny_f) = @_;
  # get two genome and  index through synteny file and ancestral genome file
  my @lines = io($genome_f)->chomp->getlines;
  my %block2gene2lines;
  for my $line (@lines) {
    my @cols = split /\t/, $line;
    $block2gene2lines{$cols[1]}{$cols[$ref_spe_index]} = $line;
  }
  return %block2gene2lines;
}


sub get_synteny {
  my $col_file = shift;
  my $io_in = io($col_file)->chomp;
  my %col_block2genepair;
  my ($block, $normal);
  while (defined (my $line = $io_in->getline)) {
    if ($line =~/^#/) {
      if ($line =~/^## (Alignment \d+).+N=\d+\s+(\S+?)\d+&(\S+)\d+/) {
        $normal = $ref_spe eq $2 ? 1 : 0;
        $block = $normal == 1 ? "$2_$3_$1" : "$3_$2_$1";
      } else {
        next;
      }
    } else {
        my @cols = split /\t/, $line;
        my ($ref_gene, $hit_gene)  = $normal == 1 ? @cols[1,2] : @cols[2,1];
        $col_block2genepair{$block}{$ref_gene} = $hit_gene;
    }
  }
  return(%col_block2genepair);
}
 
 
sub get_block_range {
  my %block2genepair = @_;
  my %block2range;
  for my $block (keys %block2genepair) {
    my @genes = keys %{$block2genepair{$block}};
    my @genes_index = map {
      my ($index) = $_ =~/_(\d+)/;
      $index;
    } @genes;
    my @genes_sort = sort {$a <=> $b} @genes_index;
    my ($chr) = $genes[1] =~/^.+(\d)_/;
    $block2range{$block}{chr} = $chr;
    $block2range{$block}{start} = $genes_sort[0];
    $block2range{$block}{end} = $genes_sort[-1];
  }
  return %block2range;
}
