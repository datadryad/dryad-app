# A Test README to check outputs

This dataset checks that complex output works in the Markdown parser.

## Description of the data and file structure

### Data list

Example datalist that has caused issues in markdown parsers.

**DATA**        *each directory compressed separately*
\|- **raw_data/**
\|  |- R1_89_S1_R1_001.fastq.gz        *71-89 branch Round 1 HHR- paired end reads*
\|  |- R1_89_S1_R2_001.fastq.gz
\|  |- R1_89_E1_S2_R1_001.fastq.gz        *71-89 branch Round 1 HHR+ pre-cleaved paired end reads*
\|  |- R1_89_E1_S2_R2_001.fastq.gz
\|  |- R1_89_E2_S3_R1_001.fastq.gz        *71-89 branch Round 1 HHR+ cleaved paired end reads*
\|  |- R1_89_E2_S3_R2_001.fastq.gz
\|  |- R1_52_2_S5_R1_001.fastq.gz        *52-2 branch Round 1 HHR- paired end reads*
\|  |- R1_52_2_S5_R2_001.fastq.gz
\|  |- R1_52_2_E1_S6_R1_001.fastq.gz        *52-2 branch Round 1 HHR+ pre-cleaved paired end reads*
\|  |- R1_52_2_E1_S6_R2_001.fastq.gz
\|  |- R1_52_2_E2_S7_R1_001.fastq.gz        *52-2 branch Round 1 HHR+ cleaved paired end reads*
\|  |- R1_52_2_E2_S7_R2_001.fastq.gz
\|  |- R2_89_S9_R1_001.fastq.gz        *71-89 branch Round 2 HHR- paired end reads*
\|  |- R2_89_S9_R2_001.fastq.gz
\|  |- R2_89_E1_S10_R1_001.fastq.gz        *71-89 branch Round 2 HHR+ pre-cleaved paired end reads*
\|  |- R2_89_E1_S10_R2_001.fastq.gz
\|  |- R2_89_E2_S11_R1_001.fastq.gz        *71-89 branch Round 2 HHR+ cleaved paired end reads*
\|  |- R2_89_E2_S11_R2_001.fastq.gz
\|  |- R2_52_2_S13_R1_001.fastq.gz        *52-2 branch Round 2 HHR- paired end reads*
\|  |- R2_52_2_S13_R2_001.fastq.gz
\|  |- R2_52_2_E1_S14_R1_001.fastq.gz        *52-2 branch Round 2 HHR+ pre-cleaved paired end reads*
\|  |- R2_52_2_E1_S14_R2_001.fastq.gz
\|  |- R2_52_2_E2_S15_R1_001.fastq.gz        *52-2 branch Round 2 HHR+ cleaved paired end reads*
\|  |- R2_52_2_E2_S15_R2_001.fastq.gz
\|  |- R3_89_S17_R1_001.fastq.gz        *71-89 branch Round 3 HHR- paired end reads*
\|  |- R3_89_S17_R2_001.fastq.gz
\|  |- R3_89_E1_S18_R1_001.fastq.gz        *71-89 branch Round 3 HHR+ pre-cleaved paired end reads*
\|  |- R3_89_E1_S18_R2_001.fastq.gz
\|  |- R3_89_E2_S19_R1_001.fastq.gz        *71-89 branch Round 3 HHR+ cleaved paired end reads*
\|  |- R3_89_E2_S19_R2_001.fastq.gz
\|  |- R3_52_2_S21_R1_001.fastq.gz        *52-2 branch Round 3 HHR- paired end reads*
\|  |- R3_52_2_S21_R2_001.fastq.gz
\|  |- R3_52_2_E1_S22_R1_001.fastq.gz        *52-2 branch Round 3 HHR+ pre-cleaved paired end reads*
\|  |- R3_52_2_E1_S22_R2_001.fastq.gz
\|  |- R3_52_2_E2_S23_R1_001.fastq.gz        *52-2 branch Round 3 HHR+ cleaved paired end reads*
\|  |- R3_52_2_E2_S23_R2_001.fastq.gz
\|  |- R4_89_S25_R1_001.fastq.gz        *71-89 branch Round 4 HHR- paired end reads*
\|  |- R4_89_S25_R2_001.fastq.gz
\|  |- R4_89_E1_S26_R1_001.fastq.gz        *71-89 branch Round 4 HHR+ pre-cleaved paired end reads*
\|  |- R4_89_E1_S26_R2_001.fastq.gz
\|  |- R4_89_E2_S27_R1_001.fastq.gz        *71-89 branch Round 4 HHR+ cleaved paired end reads*
\|  |- R4_89_E2_S27_R2_001.fastq.gz
\|  |- R4_52_2_S29_R1_001.fastq.gz        *52-2 branch Round 4 HHR- paired end reads*
\|  |- R4_52_2_S29_R2_001.fastq.gz
\|  |- R4_52_2_E1_S30_R1_001.fastq.gz        *52-2 branch Round 4 HHR+ pre-cleaved paired end reads*
\|  |- R4_52_2_E1_S30_R2_001.fastq.gz
\|  |- R4_52_2_E2_S31_R1_001.fastq.gz        *52-2 branch Round 4 HHR+ cleaved paired end reads*
\|  |- R4_52_2_E2_S31_R2_001.fastq.gz
\|  |- R5_89_S33_R1_001.fastq.gz        *71-89 branch Round 5 HHR- paired end reads*
\|  |- R5_89_S33_R2_001.fastq.gz
\|  |- R5_89_E1_S34_R1_001.fastq.gz        *71-89 branch Round 5 HHR+ pre-cleaved paired end reads*
\|  |- R5_89_E1_S34_R2_001.fastq.gz
\|  |- R5_89_E2_S35_R1_001.fastq.gz        *71-89 branch Round 5 HHR+ cleaved paired end reads*
\|  |- R5_89_E2_S35_R2_001.fastq.gz
\|  |- R5_52_2_S37_R1_001.fastq.gz        *52-2 branch Round 5 HHR- paired end reads*
\|  |- R5_52_2_S37_R2_001.fastq.gz
\|  |- R5_52_2_E1_S38_R1_001.fastq.gz        *52-2 branch Round 5 HHR+ pre-cleaved paired end reads*
\|  |- R5_52_2_E1_S38_R2_001.fastq.gz
\|  |- R5_52_2_E2_S39_R1_001.fastq.gz        *52-2 branch Round 5 HHR+ cleaved paired end reads*
\|  |- R5_52_2_E2_S39_R2_001.fastq.gz
\|  |- R6_89_S41_R1_001.fastq.gz        *71-89 branch Round 6 HHR- paired end reads*
\|  |- R6_89_S41_R2_001.fastq.gz
\|  |- R6_89_E1_S42_R1_001.fastq.gz        *71-89 branch Round 6 HHR+ pre-cleaved paired end reads*
\|  |- R6_89_E1_S42_R2_001.fastq.gz
\|  |- R6_89_E2_S43_R1_001.fastq.gz        *71-89 branch Round 6 HHR+ cleaved paired end reads*
\|  |- R6_89_E2_S43_R2_001.fastq.gz
\|  |- R6_52_2_S45_R1_001.fastq.gz        *52-2 branch Round 6 HHR- paired end reads*
\|  |- R6_52_2_S45_R2_001.fastq.gz
\|  |- R6_52_2_E1_S46_R1_001.fastq.gz        *52-2 branch Round 6 HHR+ pre-cleaved paired end reads*
\|  |- R6_52_2_E1_S46_R2_001.fastq.gz
\|  |- R6_52_2_E2_S47_R1_001.fastq.gz        *52-2 branch Round 6 HHR+ cleaved paired end reads*
\|  |- R6_52_2_E2_S47_R2_001.fastq.gz
\|  |- R7_89_S49_R1_001.fastq.gz        *71-89 branch Round 7 HHR- paired end reads*
\|  |- R7_89_S49_R2_001.fastq.gz
\|  |- R7_89_E1_S50_R1_001.fastq.gz        *71-89 branch Round 7 HHR+ pre-cleaved paired end reads*
\|  |- R7_89_E1_S50_R2_001.fastq.gz
\|  |- R7_89_E2_S51_R1_001.fastq.gz        *71-89 branch Round 7 HHR+ cleaved paired end reads*
\|  |- R7_89_E2_S51_R2_001.fastq.gz
\|  |- R7_52_2_S53_R1_001.fastq.gz        *52-2 branch Round 7 HHR- paired end reads*
\|  |- R7_52_2_S53_R2_001.fastq.gz
\|  |- R7_52_2_E1_S54_R1_001.fastq.gz        *52-2 branch Round 7 HHR+ pre-cleaved paired end reads*
\|  |- R7_52_2_E1_S54_R2_001.fastq.gz
\|  |- R7_52_2_E2_S55_R1_001.fastq.gz        *52-2 branch Round 7 HHR+ cleaved paired end reads*
\|  |- R7_52_2_E2_S55_R2_001.fastq.gz
\|  |- R8_89_S57_R1_001.fastq.gz        *71-89 branch Round 8 HHR- paired end reads*
\|  |- R8_89_S57_R2_001.fastq.gz
\|  |- R8_89_E1_S58_R1_001.fastq.gz        *71-89 branch Round 8 HHR+ pre-cleaved paired end reads*
\|  |- R8_89_E1_S58_R2_001.fastq.gz
\|  |- R8_89_E2_S59_R1_001.fastq.gz        *71-89 branch Round 8 HHR+ cleaved paired end reads*
\|  |- R8_89_E2_S59_R2_001.fastq.gz
\|  |- R8_52_2_S61_R1_001.fastq.gz        *52-2 branch Round 8 HHR- paired end reads*
\|  |- R8_52_2_S61_R2_001.fastq.gz
\|  |- R8_52_2_E1_S62_R1_001.fastq.gz        *52-2 branch Round 8 HHR+ pre-cleaved paired end reads*
\|  |- R8_52_2_E1_S62_R2_001.fastq.gz
\|  |- R8_52_2_E2_S63_R1_001.fastq.gz        *52-2 branch Round 8 HHR+ cleaved paired end reads*
\|  |- R8_52_2_E2_S63_R2_001.fastq.gz
\|  |- HHR_E1_wt_S9_R1_001.fastq.gz        *re-selection branch wild-type alone HHR+ pre-cleaved paired end reads*
\|  |- HHR_E1_wt_S9_R2_001.fastq.gz
\|  |- HHR_E1_3_S10_R1_001.fastq.gz        *re-selection branch Seq3 alone HHR+ pre-cleaved paired end reads*
\|  |- HHR_E1_3_S10_R2_001.fastq.gz
\|  |- HHR_E1_2_S11_R1_001.fastq.gz        *re-selection branch Seq2 alone HHR+ pre-cleaved paired end reads*
\|  |- HHR_E1_2_S11_R2_001.fastq.gz
\|  |- HHR_E1_5_S12_R1_001.fastq.gz        *re-selection branch Seq5 alone HHR+ pre-cleaved paired end reads*
\|  |- HHR_E1_5_S12_R2_001.fastq.gz
\|  |- HHR_E1_15_S13_R1_001.fastq.gz        *re-selection branch Seq15 alone HHR+ pre-cleaved paired end reads*
\|  |- HHR_E1_15_S13_R2_001.fastq.gz
\|  |- HHR_E1_35_S15_R1_001.fastq.gz        *re-selection branch Seq35 alone HHR+ pre-cleaved paired end reads*
\|  |- HHR_E1_35_S15_R2_001.fastq.gz
\|  |- HHR_E1_c_S16_R1_001.fastq.gz        *re-selection branch wt+Seq3+Seq2+Seq5+Seq15+Seq35 HHR+ pre-cleaved paired end reads*
\|  |- HHR_E1_c_S16_R2_001.fastq.gz
\|  |- HHR_E2_wt_S17_R1_001.fastq.gz        *re-selection branch wild-type alone HHR+ cleaved paired end reads*
\|  |- HHR_E2_wt_S17_R2_001.fastq.gz
\|  |- HHR_E2_3_S18_R1_001.fastq.gz        *re-selection branch Seq3 alone HHR+ cleaved paired end reads*
\|  |- HHR_E2_3_S18_R2_001.fastq.gz
\|  |- HHR_E2_2_S19_R1_001.fastq.gz        *re-selection branch Seq2 alone HHR+ cleaved paired end reads*
\|  |- HHR_E2_2_S19_R2_001.fastq.gz
\|  |- HHR_E2_5_S20_R1_001.fastq.gz        *re-selection branch Seq5 alone HHR+ cleaved paired end reads*
\|  |- HHR_E2_5_S20_R2_001.fastq.gz
\|  |- HHR_E2_15_S21_R1_001.fastq.gz        *re-selection branch Seq15 alone HHR+ cleaved paired end reads*
\|  |- HHR_E2_15_S21_R2_001.fastq.gz
\|  |- HHR_E2_35_S23_R1_001.fastq.gz        *re-selection branch Seq35 alone HHR+ cleaved paired end reads*
\|  |- HHR_E2_35_S23_R2_001.fastq.gz
\|  |- HHR_E2_c_S24_R1_001.fastq.gz        *re-selection branch wt+Seq3+Seq2+Seq5+Seq15+Seq35 HHR+ cleaved paired end reads*
\|  |- HHR_E2_c_S24_R2_001.fastq.gz
\|  |- R8_89_m_S25_R1_001.fastq.gz        *71-89 branch Round 8 HHR+ mock selection paired end reads*
\|  |- R8_89_m_S25_R2_001.fastq.gz
\|  |- R8_52_m_S26_R1_001.fastq.gz        *52-2 branch Round 8 HHR+ mock selection paired end reads*
\|  |- R8_52_m_S26_R2_001.fastq.gz
\|  |- CT_S27_R1_001.fastq.gz        *re-selection branch wt+Seq3+Seq2+Seq5+Seq15+Seq35 HHR+ starting mixture paired end reads*
\|  |- CT_S27_R2_001.fastq.gz
\|- **processed_data/**
\|  |- HH_p52and71_m_n0_abd_aln_R1_52_2_muts.txt        *Base calls for HHR- RNA from Round 1 of 52-2 branch*
\|  |- HH_p52and71_m_n0_abd_aln_R1_89_muts.txt        *Base calls for HHR- RNA from Round 1 of 71-89 branch*
\|  |- HH_p52and71_E1_n0_abd_aln_R1_52_2_muts.txt        *Base calls for HHR+ pre-cleaved RNA from Round 1 of 52-2 branch*
\|  |- HH_p52and71_E1_n0_abd_aln_R1_89_muts.txt        *Base calls for HHR+ pre-cleaved RNA from Round 1 of 71-89 branch*
\|  |- HH_p52_n0_abd_clst_more_M_dist_refs_dists.txt        *Sequence-Frequency table for 52-2 branch*
\|  |- HH_p71_n0_abd_clst_more_M_dist_refs_dists.txt        *Sequence-Frequency table for 71-89 and re-selection branches*
\|  |- HH_p52and71_n0_abd_M_dist_refs_dists.txt        *Sequence-Frequency table for HHR+ cleaved RNA only from 52-2 and 71-89 branches*
\|  |- dist_refs.fasta        *fasta file for 4 reference sequences for Levenshtein distance calculations*
\|- **figure_data/**
\|  |- Papastavrou_23_fidelity_Table_S2_and_S3.xlsx        *Excel spreadsheet for calculating fidelity table and average fidelity from base call tables*
\|  |- Papastavrou_23_fig_2_and_S2_data.xlsx        *Excel spreadsheet with underlying data for figure 2 and S2*
\|  |- Papastavrou_23_fig_3_data.xlsx        *Excel spreadsheet with underlying data for figure 3*
\|  |- Papastavrou_23_fig_S3_data.xlsx        *Excel spreadsheet with underlying data for figure S3*
\|  |- Papastavrou_23_fig_4B_data.xlsx        *Excel spreadsheet with underlying data for figure 4B*

### Data description

We should also have a table, and some ^superscript^ and ~subscript~.

| Test   | Table  | Heading |
| :----- | :----- | :------ |
| Cell 1 | Cell 2 | Cell 3  |
| Cell 3 | Cell 5 | Cell 6  |
