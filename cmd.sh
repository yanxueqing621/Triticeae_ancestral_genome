perl 0.filter_collinear_by_geneNum.pl tel_hv.collinearity 5 500
perl 0.filter_collinear_by_geneNum.pl tel_awk.collinearity 5 500
perl 0.filter_collinear_by_geneNum.pl hv_awk.collinearity 5 500
perl 1.make_syntenic_list.pl tel hv awk tel.gff o1.tel_vs_other.colinear.txt
sed -i 's/chr/awk/g' o1.tel_vs_other.colinear.txt
perl 2.get_cPPG.pl hv awk o1.tel_vs_other.colinear.txt o2.cPG_genelist.txt
perl 3.change_gid_for_block.pl o2.cPG_genelist.txt o3.CPG_new_GID.txt
perl 4.add_block_id.pl o3.CPG_new_GID.txt o4.CPG_newGID_blockID.txt
perl 5.modified_block.pl o4.CPG_newGID_blockID.txt o5.CPG_newGID_newblockID.txt
perl 6.filter_small_block.pl o5.CPG_newGID_newblockID.txt o6.CPG_newGID_newblockID.filter.txt
perl 7.modified_blockid.pl o6.CPG_newGID_newblockID.filter.txt o7.CPG_newGID_newblockID_filter_newblockID.txt
perl 8.make_mgra_input_block_order.pl tel hv awk o7.CPG_newGID_newblockID_filter_newblockID.txt o8.mgra_input.txt
MGR -f o8.mgra_input.txt -o o8_out_mgra_H2.txt -H 2
tail -n 7 o8_out_mgra_H2.txt >o8_out_mgra_H2.txt7
perl 9.make_ancient_genome.pl o7.CPG_newGID_newblockID_filter_newblockID.txt o8_out_mgra_H2.txt7 o9.ancient_genome.txt
perl 10.convert_to_old_id.pl o9.ancient_genome.txt o10.ancient_genome_oid.txt
sed -i 's/chr/awk/g' *500
perl 11.enrichment_genome.pl o10.ancient_genome_oid.txt tel_hv.collinearity.5.500 o11.ancient_genome_oid_fill_telhv.txt
perl 11.enrichment_genome.pl o11.ancient_genome_oid_fill_telhv.txt tel_awk.collinearity.5.500 o11.ancient_genome_oid_fill_telhv_telawk.txt
perl 12.enrichment_other.pl o11.ancient_genome_oid_fill_telhv_telawk.txt hv_awk.collinearity.5.500 o11.ancient_genome_oid_fill_telhv_telawk_hvawk.txt
