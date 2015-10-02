# formatMedSum.py v0.00          damiancclarke             yyyy-mm-dd:2015-10-02
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# Take files exported from medSum.do, and export as tex file.  To run, type:
#   python formatMedSum.py
#
#
#
#

import re
#-------------------------------------------------------------------------------
#--- (1) location
#-------------------------------------------------------------------------------
LOC = '/home/damiancclarke/investigacion/2014/MexAbort/Results/Summary/'

births  = open(LOC + 'birthSum.txt', 'r').readlines()
MMR     = open(LOC + 'MMRSum.txt'  , 'r').readlines()

outfile = open(LOC + 'Summary.tex', 'w')

#-------------------------------------------------------------------------------
#--- (2) Make files
#-------------------------------------------------------------------------------
outfile.write('\\begin{table}[htpb!]\n'
              '\\caption{Births and Maternal Deaths by Area and Characteristics}'
              '\n \\label{sumStats} \n \\begin{center} \n'
              '\\begin{tabular}{lccc}\\toprule\\toprule  \n'
              '& DF \& & Other & Full \\\\ \n&Mexico&States&Country \\\\ '
              '\\midrule \n \\textbf{Panel A: Births}&&&\\\\ \n')

for i,line in enumerate(births):
    if i>0 and i<3:
        line = line.replace('Births','Births (1000s)')
        line = line.replace('Rate','Rate (per 1000 women)')
        line = line.replace('&&','&')
        line = line.replace('\n',' ')
        outfile.write(line + '\\\\ \n')
    if i>=3 and i<7:
        if i==3:
            outfile.write("Maternal Age (years) &&&\\\\ \n")
        line = line.replace('Birth Rate&','')
        line = line.replace('\n',' ')
        outfile.write('\hspace{3mm}'+ line + '\\\\ \n')
    if i>=7 and i<9:
        if i==7:
            outfile.write("Time Period &&&\\\\ \n")
        line = line.replace('Birth Rate&','')
        line = line.replace('Pre','Pre-Reform')
        line = line.replace('Post','Post-Reform')
        line = line.replace('\n',' ')
        outfile.write('\hspace{3mm}'+ line + '\\\\ \n')

outfile.write('&&&\\\\ \\textbf{Panel B: Maternal Deaths}&&&\\\\ \n')
for i,line in enumerate(MMR):
    if i>0 and i<3:
        line = line.replace('Maternal Mortality Ratio','MMR (per 100,000 women)')
        line = line.replace('&&','&')
        line = line.replace('\n',' ')
        outfile.write(line + '\\\\ \n')
    if i>=3 and i<7:
        if i==3:
            outfile.write("Maternal Age (years) &&&\\\\ \n")
        line = line.replace('Maternal Mortality Ratio&','')
        line = line.replace('\n',' ')
        outfile.write('\hspace{3mm}'+ line + '\\\\ \n')
    if i>=7 and i<9:
        if i==7:
            outfile.write("Time Period &&&\\\\ \n")
        line = line.replace('Maternal Mortality Ratio&','')
        line = line.replace('Pre','Pre-Reform')
        line = line.replace('Post','Post-Reform')
        line = line.replace('\n',' ')
        outfile.write('\hspace{3mm}'+ line + '\\\\ \n')


outfile.write('\\bottomrule \n \\end{tabular}\\end{center}\\end{table}')
