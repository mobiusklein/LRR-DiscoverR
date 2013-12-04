---------------------------
| How to use LRR Discoverr |
---------------------------

=Installation

==Requirements
Perl 5.12 or later @ http://perldoc.perl.org
HMMER 3.0 @ http://hmmer.janelia.org/
TMHMM 2.0 @ http://www.cbs.dtu.dk/services/TMHMM-2.0/ (TMHMM is not executed but its output is a parameter. 
As versions for different OS may have differences in output format, note we use decodeanhmm.Linux_x86_64 
with option model file tmhmm-2.0c/lib/TMHMM2.0.model)
==

This program requires no modification of the scripts to execute it. 

To make it possible to execute this program from locations other than its installation directory, make
sure to add the installation directory to your system path. Otherwise, it must be ran from its installation
directory. 

Unzip the compressed archive. Leave the underlying file structure intact. 
=

=Usage

To run the LRR_Discoverr.pl:
"perl LRR_Discoverr.pl <options> <query file> <tmhmm result file>"

==Options
-e	Sets the e value threshold for reporting domains for all models

-c	Sets the number of CPUs to run hmmscan with
==

==Query File
Contains one or more Amino Acid sequences in Fasta Format
==

==TMHMM Result File
The results of an execution of TMHMM 2.0  on the Query File

It should resemble below:
"
>a00136801.t1
%len 337
%lett A:29 C:9 D:3 E:22 F:22 G:21 H:6 I:24 K:16 L:30 M:10 N:11 P:16 Q:8 R:16 S:21 T:23 V:25 W:11 Y:14
%score BG 1433.732113 (4.254398 per character)
%score FW 1391.588186 (4.129342 per character)
%score NB(0) 1399.491262 (4.152793 per character)
%score LO(0) 34.240851 (0.101605 per character)
%pred NB(0): o 1 46, M 47 69, i 70 88, M 89 108, o 109 122, M 123 145, i 146 164, M 165 187, o 188 196, M 197 219, i 220 247, M 248 270, o 271 284, M 285 307, i 308 337
   MTSEPEPEHHYNHTSAPETEPESSVYEPTAEAEAEPLPEWSKATEEWGIAWDIHQYGLGGVYTLLFLFITMS
?0 ooooooooooooooooooooooooooooooooooooooooooooooMMMMMMMMMMMMMMMMMMMMMMMiii

   LIKRIKQGRTGGQGHKVPMVVLSLLGMFCLTRGLCLCIDAYRWKKIMPVFFVNVFWGIGQPCIISAYTLVFI
?0 iiiiiiiiiiiiiiiiMMMMMMMMMMMMMMMMMMMMooooooooooooooMMMMMMMMMMMMMMMMMMMMMM

   VMRNALTLKQNFRRWYTTRNIAIATLPYFIFAFGAELTLSFAPSFKGIAFTCQLLYILYGSSLSVFYSMISF
?0 MiiiiiiiiiiiiiiiiiiiMMMMMMMMMMMMMMMMMMMMMMMoooooooooMMMMMMMMMMMMMMMMMMMM

   LLWKKLKVATKNRWNSESANRCGKRTRTIFRTCVAAVFGGIAICAMQLFAMIGVYGIFSEARHVSAWPWWAF
?0 MMMiiiiiiiiiiiiiiiiiiiiiiiiiiiiMMMMMMMMMMMMMMMMMMMMMMMooooooooooooooMMMM

   QTLFRVVEIYMVVVLCYAVNDRNVEAKKGEIAPTSLNSETPVKPLEVEA
?0 MMMMMMMMMMMMMMMMMMMiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
"
==
=

=Output
In the directory the Query File is located in, you will find several files and directories are created.

==<query file>_NameToNumber.fa
The query file with each name translated into a unique integer code. 
This insures that HMMER does not remove vital identification information from the result file it produces.
==

==<query file>_NameToNumber.index
This file contains the relationship between query sequence names and the id assigned to them. This is used
for translating ids back into their given names for later result files.
==

==Toll-like_HMMDB_<query file>_NameToNumber.fa [Directory]
This directory contains the results of the scan of the Toll-like Hidden Markov Model Database over the query
file with encoded sequence names. It contains several files which are described below:

===Toll-like_HMMDB_<query file>_NameToNumber.fa/<query file>_NameToNumber.fa.hmmscan
This file contains the raw results of the execution of HMMSCAN from HMMER, query sequences against Toll-like
HMMDB. It contains all predicted domains for all sequences. Sequence names are encoded to insure they will
not be cut off.
===

===Toll-like_HMMDB_<query file>_NameToNumber.fa/<query file>_NameToNumber.fa_dom_table.hmmscan
This file contains only records of domains in compressed format. Used for reducing overlap between Models for 
each sequence queried. Sequence Names are encoded to insure they will not be cut off
===

===Toll-like_HMMDB_<query file>_NameToNumber.fa/<query file>_NameToNumber.fa_dom_table.hmmscan.reduced
This file contains only records of domains that do not overlap completely. Overlapping domains have their e values
compared, the greater's domain is discraded. Sequence Names are encoded to insure they will not be cut off.
===

===Toll-like_HMMDB_<query file>_NameToNumber.fa/<query file>_NameToNumber.fa_dom_table.hmmscan.reduced.reindexed
Decodes sequence names from <query file>_NameToNumber.fa_dom_table.hmmscan.reduced so that actual sequence names are 
present. Needed to cross-reference with TMHMM results.
===

===Toll-like_HMMDB_<query file>_NameToNumber.fa/<query file>_NameToNumber.fa_dom_table.hmmscan.reduced.reindexed.gpcr_predictions.tsv
Cross-reference TMHMM results with Toll-like HMMDB hits. If a sequence has 4 or more TMHMM transmembrane zones and one or more LRRs found, 
it will be reported in this file in the following format:
"
sequence name	# TM regions ~ First TM position ~ Last TM position: LRRs Domain Start	Domain End	E Value,
a00549601.t1	4~73~539:	864	878	0.00094,	806	820	0.0098,	770	792	0.0017,	833	850	0.0021,
"
Regex: /(.+)\t(([0-9]+)~([0-9]+)~([0-9]+)):\t((([0-9]+)\t([0-9]+)\t([0-9e-]+),)+)/

This is a specifically imperfect filtering process (accepting fewer than 7 TM regions) designed to allow possible hits not yet
classified or that are more distantly related to appear in our results. With that in mind, predictions can be strengthened by manually
examining the alignment.
===

===Toll-like_HMMDB_<query file>_NameToNumber.fa/<query file>_NameToNumber.fa_dom_table.hmmscan.reduced.reindexed.gpcr_predictions.tsv_hits_only.fa
Sequences which appear in <query file>_NameToNumber.fa_dom_table.hmmscan.reduced.reindexed.gpcr_predictions.tsv with resolved sequence names will appear in this file in Fasta format, for convenience. 
===

==FSHR_HMMDB_<query file>_NameToNumber.fa [Directory]
Like the Toll-like directory, this directory contains identical files except that they were derived from FSHR HMMDB scans. The same file types
appear within it.
==
=