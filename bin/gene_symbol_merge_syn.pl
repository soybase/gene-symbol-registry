#!/usr/bin/perl
use strict;
use warnings;

sub usage {
    print <<"USAGE";
Usage: $0 [input_file]
or: cat [input_file] | $0

Options:
  -h, --help   Show this help message and exit

DESCRIPTION
  gene_symbol_merge_syn.pl - Process a four-column file, pulling elements in the first column
                              into one row when they have a common third element. Example:

       from   #symbol  description   identifier  primary
              A        fedsa         gene1       1
              B        zxdf          gene1       0
              C        sdfb          gene1       0
              D        tbex          gene2       1
       
       to     #symbol  description   identifier  
              A, B, C  fedsa         gene1
              D        tbex          gene2

  The intended purpose is to produce a table with comma-separated gene symbols in column 1
  for symbols associated with the same gene; such symbols are typically synonyms.

  Note that for lines with multiple synonyms (such as A, B, C above), only the description
  for the first symbol is reported. Thus, put the "primary" symbol first in the list.
  
  To identify symbols to be used as the source of the description, use 1 or 0 in the fourth
  column. Sort the table by column 3, then by column 1 (reverse), e.g. ...

OUTPUT
    Input modified as described above -- but note that only the first three columns are reported.

USAGE
    exit(1);
}

# Check for help flags
if (@ARGV && ($ARGV[0] eq '-h' || $ARGV[0] eq '--help')) {
    usage();
}

my $FS = "\t";
my $OFS = "\t";

# Print header
print "#symbol${OFS}description${OFS}identifier\n";

my @data;
while (<>) {
    chomp;
    next if /^#/;
    my @fields = split /\t/, $_, -1;
    push @data, \@fields if @fields >= 4;
}

# Sort: first by $fields[2] (3rd field, lexically), then by $fields[3] (4th, numerically, reverse)
@data = sort {
    $a->[2] cmp $b->[2] ||
    $b->[3] <=> $a->[3]
} @data;

my ($prev, $cat, $desc, $id);
my $first_line = 1;

for my $fields (@data) {
    if ($first_line) {
        $cat = $fields->[0];
        $desc = $fields->[1];
        $id = $fields->[2];
        $prev = $id;
        $first_line = 0;
        next;
    }
    if ($fields->[2] eq $prev) {
        $cat .= ", $fields->[0]";
    } else {
        print join($OFS, $cat, $desc, $id), "\n";
        $cat = $fields->[0];
        $desc = $fields->[1];
        $id = $fields->[2];
        $prev = $id;
    }
}
print join($OFS, $cat, $desc, $id), "\n" if !$first_line;
