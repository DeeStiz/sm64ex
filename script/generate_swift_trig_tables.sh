#!/usr/bin/env perl
use strict;
use warnings;

my ($source_path, $output_path) = @ARGV;
die "usage: generate_swift_trig_tables.sh SOURCE OUTPUT\n"
    unless defined $source_path && defined $output_path;

open my $source, '<', $source_path or die "open $source_path: $!\n";
local $/;
my $text = <$source>;
close $source or die "close $source_path: $!\n";

sub parse_values {
    my ($body, $integer) = @_;
    $body =~ s{//[^\n]*}{}g;
    my @values;
    for my $token (split /,/, $body) {
        $token =~ s/^\s+|\s+$//g;
        next unless length $token;
        $token =~ s/f$//;
        if ($integer) {
            push @values, "Int16(bitPattern: UInt16($token))";
        } else {
            push @values, $token;
        }
    }
    return @values;
}

$text =~ /f32\s+gSineTable\[\]\s*=\s*\{(.*?)\#ifndef\s+AVOID_UB/s
    or die "missing gSineTable body\n";
my @sine_prefix = parse_values($1, 0);

$text =~ /f32\s+gCosineTable\[0x1000\]\s*=\s*\{\s*\#endif\s*\/\/\s*cosine\s*(.*?)\n\};/s
    or die "missing gCosineTable body\n";
my @cosine = parse_values($1, 0);

$text =~ /s16\s+gArctanTable\[0x401\]\s*=\s*\{(.*?)\n\};/s
    or die "missing gArctanTable body\n";
my @arctan = parse_values($1, 1);

die "unexpected sine prefix count\n" unless @sine_prefix == 0x400;
die "unexpected cosine count\n" unless @cosine == 0x1000;
die "unexpected arctan count\n" unless @arctan == 0x401;

open my $output, '>', $output_path or die "open $output_path: $!\n";
print {$output} <<'HEADER';
// Generated from include/trig_tables.inc.c. Do not hand-edit.
// Regenerate with script/generate_swift_trig_tables.sh.
import Foundation

enum SM64CanonicalTrigTables {
HEADER

sub print_array {
    my ($handle, $name, $type, $values) = @_;
    print {$handle} "    static let $name: [$type] = [\n";
    for (my $index = 0; $index < @$values; $index += 8) {
        my $end = $index + 8;
        $end = @$values if $end > @$values;
        print {$handle} "        ", join(', ', @$values[$index .. $end - 1]), ",\n";
    }
    print {$handle} "    ]\n\n";
}

print_array($output, 'sinePrefix', 'Float', \@sine_prefix);
print_array($output, 'cosine', 'Float', \@cosine);
print_array($output, 'arctangent', 'Int16', \@arctan);
print {$output} <<'FOOTER';
    /// The C AVOID_UB build places cosine immediately after the 0x400-value
    /// sine prefix. Keep the combined indexing contract for `sins` intact.
    static let sine: [Float] = sinePrefix + cosine
}
FOOTER
close $output or die "close $output_path: $!\n";
