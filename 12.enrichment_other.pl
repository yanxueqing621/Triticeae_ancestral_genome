#!/usr/bin/env perl
use Modern::Perl;
use IO::All;
use Data::Dumper;
use Common::Routine ":all";

my ($ancestral_genome_file, $synteny_file, $final_ancestral_genome) = @ARGV;
 
enrichment_ancestral_genome($ancestral_genome_file, $synteny_file, $final_ancestral_genome);
sub enrichment_ancestral_genome {
  my ($ancestral_genome_file, $synteny_file, $final_ancestral_genome) = @_;
  my %col_block2genepair = get_synteny($synteny_file);
  say scalar keys %col_block2genepair;
  my %col_block2range = get_block_range(%col_block2genepair);
  say Dumper \%col_block2range;
  say scalar keys %col_block2range;
  my ($ances_block2gene2lines_t, $block2chr)  = get_ancestral_genome($ancestral_genome_file, $synteny_file);
  my %ances_block2gene2lines = %$ances_block2gene2lines_t;
  my %ances_block2range = get_block_range(%ances_block2gene2lines);
  my %ances_block2lines;
  
  #say Dumper \%col_block2range;
  #say Dumper \%ances_block2range;
  
  #make collinear lines
  my ($ref_spe, $hit_spe)  = io($synteny_file)->filename =~/(^.+?)_(\S+?)\./;
  my @line_tmp = io($ancestral_genome_file)->chomp->getlines;
  my ($ref_spe_index, $hit_spe_index);
  my @cols_tmp = split /\t/, $line_tmp[0];
  my @cols_tmp_na = map { 'NA' } @cols_tmp;
  #say Dumper \@cols_tmp;
  # get index of reference species and hit species
  for (my $i = 0; $i < @cols_tmp; $i++) {
    $ref_spe_index = $i if $cols_tmp[$i] =~/^$ref_spe/;
    $hit_spe_index = $i if $cols_tmp[$i] =~/^$hit_spe/;
  } 
  say "ref: $ref_spe_index \thit$hit_spe_index";
  
  # links block to lines  for ancestral genome file
  my %ances_genes;
  for my $line (@line_tmp) {
    my @cols = split /\t/,$line;
    push @{$ances_block2lines{$cols[1]}}, $line;
    $ances_genes{$cols[1]}{$cols[$ref_spe_index]} = 1;
    $ances_genes{$cols[1]}{$cols[$hit_spe_index]} = 1;
  }
  
  # enrichment ancestral genome
  for my $ances_block (keys %ances_block2range) {
    my ($ances_s, $ances_e, $ances_chr) = ($ances_block2range{$ances_block}{start}, $ances_block2range{$ances_block}{end}, $ances_block2range{$ances_block}{chr});
    my $ances_chr_final = $block2chr->{$ances_block};
    say "ances_chr$ances_chr\tances_chr_final:$ances_chr_final";
    #my %ances_genes2lines = %{$ances_block2gene2lines{$ances_block}};
    for my $col_block (keys %col_block2range) {
      my ($col_s, $col_e, $col_chr) = ($col_block2range{$col_block}{start}, $col_block2range{$col_block}{end}, $col_block2range{$col_block}{chr});
      next if $ances_chr ne $col_chr;  # 以1号染色体进行测试
      # if syntenic block intersect with ancestral block, we fill ancestral block;
      if (max($ances_s, $col_s) < min($ances_e, $col_e)) {  # judge if intersect
        #say "$ances_block:$ances_s - $ances_e \t $col_block:$col_s - $col_e";
        my ($s, $e) = (max($ances_s, $col_s), min($ances_e, $col_e));  # get intersect regions
        my %col_gene2pair = %{$col_block2genepair{$col_block}};
        
        my @newlines = ();
        for my $gene (keys %col_gene2pair) {
          my $gene_hit = $col_gene2pair{$gene};
          my ($num) = $gene =~/_(\d+)/;
          if ($num <= $e and $num >= $s) {  # judge syntenic gene pair in intersect regions
            if (not exists $ances_genes{$ances_block}{$gene} and not exists $ances_genes{$ances_block}{$gene_hit}) {
              my @cols_tmp_na_new = @cols_tmp_na;
              #$cols_tmp_na_new[0] = "chr$ances_chr";
              $cols_tmp_na_new[0] = "$ances_chr_final";
              $cols_tmp_na_new[1] = $ances_block;
              $cols_tmp_na_new[$ref_spe_index] = $gene;
              $cols_tmp_na_new[$hit_spe_index] = $col_gene2pair{$gene};
              push @newlines, join("\t", @cols_tmp_na_new);
            }
          }
        }
        $ances_block2lines{$ances_block} = dual_sort($ances_block2lines{$ances_block}, \@newlines,$ref_spe_index, $hit_spe_index);
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
  say Dumper \@ances_block_order;
  # sort and output new ancestral genome
  my $io_out = io($final_ancestral_genome);
  for my $block (@ances_block_order) {
    my @block_lines = @{$ances_block2lines{$block}};
    $io_out->println($_) for @block_lines;
  }

}

sub dual_sort {
  my ($ref_line, $insert_line, $ref_col, $hit_col) = @_;
  say Dumper $ref_line;
  say Dumper $insert_line;
  my @ref_lines = @$ref_line;
  my @insert_lines = @$insert_line;
  for my $line (@insert_lines) {
    my %ref_index2distance;
    my %hit_index2distance;
    my ($insert_ref_gene) = (split /\t/, $line)[$ref_col] =~/_(\d+)/;
    my ($insert_hit_gene) = (split /\t/, $line)[$hit_col] =~/_(\d+)/;

    say "insert:index:$insert_ref_gene, hit:$insert_hit_gene";
    my (@ref_genes, @hit_genes);
    for (my $i = 0; $i < @ref_lines; $i++) {
      my @cols = split /\t/, $ref_lines[$i];
      push @ref_genes, $cols[$ref_col];
      push @hit_genes, $cols[$hit_col];
    }
    
    my $ref_insert_pos = '';
    for (my $i = 1; $i < @ref_genes; $i++) {
      next if $ref_genes[$i-1] eq 'NA' or $ref_genes[$i] eq 'NA';
      my ($up_id) = $ref_genes[$i-1] =~/_(\d+)/;
      my ($down_id) = $ref_genes[$i] =~/_(\d+)/;
      #say "$i\t$ref_genes[$i-1]\t $ref_genes[$i]($down_id -  $insert_ref_gene) * ($up_id -  $insert_ref_gene)";
      if (($down_id - $insert_ref_gene) * ($up_id - $insert_ref_gene) < 0) {
        #say "pos: " . $ref_genes[$i];
        $ref_insert_pos = $i;
        last;
      }
    }
    say "ref_pos $ref_insert_pos  \t ";
    my $hit_insert_pos = '';
    for (my $i = 1; $i < @hit_genes; $i++) {
      next if $hit_genes[$i-1] eq 'NA' or $hit_genes[$i] eq 'NA';
      my ($up_id) = $hit_genes[$i-1] =~/_(\d+)/;
      my ($down_id) = $hit_genes[$i] =~/_(\d+)/;
      #say "$i\t$hit_genes[$i-1]\t $hit_genes[$i]($down_id -  $insert_hit_gene) * ($up_id -  $insert_hit_gene)";

      if (($down_id - $insert_hit_gene) * ($up_id - $insert_hit_gene) < 0) {
        #say "pos: " . $hit_genes[$i];
        $hit_insert_pos = $i;
        last;
      }
    }

    say "hit pos $hit_insert_pos";
    if ($ref_insert_pos) {
      splice @ref_lines, $ref_insert_pos, 0, $line;
    } elsif ($hit_insert_pos) {
      splice @ref_lines, $hit_insert_pos, 0, $line;
    } else {
      say "$line are error";
    }
  }
  return \@ref_lines;
}

sub get_ancestral_genome {
  my ($ances_genome_f, $synteny_f) = @_;
  # get two genome and  index through synteny file and ancestral genome file
  my ($ref_spe, $hit_spe)  = io($synteny_f)->filename =~/(^.+?)_(\S+?)\./;
  my @lines = io($ances_genome_f)->chomp->getlines;
  my ($ref_spe_index);
  my @cols_tmp = split /\t/, $lines[0];
  my @cols_tmp_na = map { 'NA' } @cols_tmp;
  for (my $i = 0; $i < @cols_tmp; $i++) {
    $ref_spe_index = $i if $cols_tmp[$i] =~/^$ref_spe/;
  } 

  my %ances_block2gene2lines;
  my %block2chr;
  for my $line (@lines) {
    my @cols = split /\t/, $line;
    $ances_block2gene2lines{$cols[1]}{$cols[$ref_spe_index]} = $line;
    $block2chr{$cols[1]} = $cols[0];
  }
  return (\%ances_block2gene2lines, \%block2chr);
}


sub get_synteny {
  my $col_file = shift;
  my $io_in = io($col_file)->chomp;
  my ($ref_spe, $hit_spe) = $io_in->filename =~/(^.+?)_(\S+?)\./;
  say $io_in->filename;
  say "#:$ref_spe \t $hit_spe";
  my %col_block2genepair;
  my ($block, $normal);
  while (defined (my $line = $io_in->getline)) {
    if ($line =~/^#/) {
      if ($line =~/^## (Alignment \d+).+N=\d+\s+(\S+?)&(\S+)/) {
        my ($align, $chr_up, $chr_down) = ($1, $2, $3);
        #$block = $1;
        $normal = $chr_up =~/$ref_spe/ ? 1 : 0;
        $block = $normal == 1 ? "${chr_up}_${chr_down}_$align" : "${chr_down}_${chr_up}_$align";

      } else {
        next;
      }
    } else {
        my @cols = split /\t/, $line;
        #say Dumper \@cols;
        my ($ref_gene, $hit_gene)  = $normal == 1 ? @cols[1,2] : @cols[2,1];
        #say "$ref_gene, $hit_gene";
        $col_block2genepair{$block}{$ref_gene} = $hit_gene;
    }
  }
  return(%col_block2genepair);
}
 
sub get_block_range {
  my %block2genepair = @_;
  my %block2range;
  for my $block (keys %block2genepair) {
    my @genes = grep { $_ ne "NA"}  keys %{$block2genepair{$block}};
    my @genes_index;
    for my $gene (@genes) {
      my ($index) = $gene =~/_(\d+)/;
      push @genes_index, $index;
    }
    my @genes_sort = sort {$a <=> $b} @genes_index;
    my ($chr) = $genes[1] =~/^.+(\d)_/;
    $block2range{$block}{chr} = $chr;
    $block2range{$block}{start} = $genes_sort[0];
    $block2range{$block}{end} = $genes_sort[-1];
  }
  return %block2range;
}
