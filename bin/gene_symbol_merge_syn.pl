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
  column. For maintaing versions of the gene_symbols_maintenance.tsv file, it is good practice
  to keep the file sorted by column 3, then by column 4 (reverse):
    cat gene_symbols_maintenance.tsv | sort -t $'\t' -k3,3 -k4nr,4nr > sorted
    mv sorted gene_symbols_maintenance.tsv
    
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
print "gene_symbol${OFS}gene_symbol_long${OFS}identifier\n";

my @data;
my %seen_id_and_symbol;
while (<>) {
    chomp;
    next if (/^#/ || /gene_symbol/);
    my @fields = split /\t/, $_, -1;
    if (scalar(@fields) < 4) {
      print "== 1 ==\n";
      die "\nDIED at line $., which has only " . scalar(@fields) . " fields, but at least 4 are required:\n" .
          "gene_symbol	gene_symbol_long	identifier	primary\n\n";
    }

    my ($gene_symbol, $gene_symbol_long, $identifier, $primary) = @fields;

    if ($primary ne 0 && $primary ne 1) {
      print "== 2 ==\n";
      die "\nDIED at line $. The fourth field must be 1 or 0, but in line $. is " . $primary . "\n\n";
    }
    if ($identifier =~ /glyma.Wm82.gnm1.ann\d.Glyma\.\d\dg/i) {
      print "== 3 ==\n";
      die "\nDIED at line $. The identifier has the form of an Wms82 2+ gene ID, but is from gnm1:\n" .
          "\n  $identifier\n\n";
    }
    if ($identifier =~ /glyma.Wm82.gnm[23456789].ann\d.Glyma\d\dg/i) {
      print "== 4 ==\n";
      die "\nDIED at line $. The identifier has the form of a Wms82 assembly 1 gene ID, but is from a later assembly:" .
          "\n  $identifier\n\n";
    }
    if ($identifier =~ / /) {
      print "== 5 ==\n";
      die "\nDIED at line $. The identifier contains one or more spaces.\n\n"
    }

    # Change to canonical case for glyma.Wm82 gene IDs (lc "g" for ann1; uc "G" for ann2,3,4,5,6,...
    $identifier =~ s/glyma.Wm82.gnm1.ann1.Glyma(\d\d)G/glyma.Wm82.gnm1.ann1.Glyma$1g/i;
    $identifier =~ s/glyma.Wm82.gnm1.ann1.Glyma(\d+)S/glyma.Wm82.gnm1.ann1.Glyma$1s/i;

    $identifier =~ s/(glyma.Wm82.gnm[23456789]\.ann\d.Glyma)\.(\d\d)g/$1.$2G/i;
    $identifier =~ s/(glyma.Wm82.gnm[23456789]\.ann\d.Glyma)\.u/$1.$2.U/i;
    $identifier =~ s/(glyma.Wm82.gnm[23456789]\.ann\d.Glyma)\.(\d+)s/$1.$2S/i;

    if ($seen_id_and_symbol{$identifier.$gene_symbol}){ # Skip this line if we've already seen this ID & symbol
      next
    }
    else { 
      $seen_id_and_symbol{$identifier.$gene_symbol}++;
      my @canonicalized_data = ($gene_symbol, $gene_symbol_long, $identifier, $primary);
      push @data, \@canonicalized_data;
    }
}

# Sort: first by $fields[2] (3rd field, lexically), then by $fields[3] (4th, numerically, reverse)
@data = sort {
    $a->[2] cmp $b->[2] ||
    $b->[3] <=> $a->[3]
} @data;
print "=====\n";
print Dumper(@data), "\n";

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

__END__
Version
2025-07-25 Initial version
2025-09-01 Add some error checking, and canonicalize case for Wm82 annotations
2025-09-25 Change header line (no leading pound sign). Add check for space within IDs.
           Bug fix in prefix for gnm2 annotations. Add comments about sorting the input file.
