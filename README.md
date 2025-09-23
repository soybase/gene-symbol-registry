# gene-symbol-registry

## Introduction

This little repository holds a table of gene symbols, descriptions, and gene IDs, and a script for processing them for display at SoyBase.

The intent is for the tsv file in this repository, `gene_symbols_maintenance.tsv`, to be the working version, from which a file is derived for display at SoyBase, at https://www.soybase.org/tools/gene-symbols/. The derived file `gene_symbols.tsv` is held as static data in the jekyll-soybase `_data/` directory.

When new gene symbols need to be added, they would first be added to the file `gene_symbols_maintenance.tsv`; then the script would be applied:

```
bin/gene_symbol_merge_syn.pl gene_symbols_maintenance.tsv > gene_symbols.tsv
```

Then the derived `gene_symbols.tsv` would be moved into the jekyll-soybase `_data/` directory.
There should be no reason to maintain the derived file within the present repository.


## Important details

### File format

* File is supposed to be Tab seprated (.tsv) 
* If __Microsoft Excel__ is used to generate the *.tsv file, there are hidden (non-printed) characters in the file. 
  - To remove these hidden (non-printed) characters open the file in vim and enter the following commands

```
       
       :%s/[[:cntrl:]]/^I/g  # removes all 'end of cell hidden characters' and replace with tab (Control+V, Control+I)
       :wq    #write and close file
```

### Perl Script

The only purpose of the `gene_symbol_merge_syn.pl` script is to merge synonyms for a given gene into one field, for display.

For example:

```
       from   gene_symbol       gene_symbol_long     identifier                            primary
              A                 fedsa                glyma.Wm82.gnm#.ann#.Glyma.gene1       1
              B                 zxdf                 glyma.Wm82.gnm#.ann#.Glyma.gene1       0
              C                 sdfb                 glyma.Wm82.gnm#.ann#.Glyma.gene1       0
              D                 tbex                 glyma.Wm82.gnm#.ann#.Glyma.gene2       1


       to     gene_symbol       gene_symbol_long     identifier 
              A, B, C           fedsa                glyma.Wm82.gnm#.ann#.Glyma.gene1
              D                 tbex                 glyma.Wm82.gnm#.ann#.Glyma.gene2
```

The intended purpose is to produce a table with comma-separated gene symbols in column 1
for symbols associated with the same gene; such symbols are typically synonyms.

Note that for lines with multiple synonyms (such as A, B, C above), only the description
for the first symbol is reported. Thus, put the "primary" symbol first in the list.

The script will sort the data first by the gene ID (lexically), then by the forth column 
(numerically, in reverse). Thus, only rows marked with 1 in the fourth column will be used
as the source of a description for the group of synonyms (or for the single symbol, if
there are no synonyms).

Note that only the first three columns are reported.

