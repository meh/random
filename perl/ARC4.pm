# Copyleft meh.
# Released under the GNU General Public License v3

package ARC4;

use strict;
use warnings;

sub new {
    my $this = {};
    $this->{name}  = shift;
    $this->{key}   = undef;
    $this->{state} = undef;
    $this->{x}     = undef;
    $this->{y}     = undef;
    bless $this;

    $this->{state} = [0 .. 255];
    $this->{x}     = 0;
    $this->{y}     = 0;

    my $key = shift;
    if ($key) {
        $this->init($key);
    }

    return $this;
}

# KSA
sub init {
    my ($this, $tkey) = @_;
    my @key = split //, $tkey;
   
    for my $i (0 .. 255) {
        $this->{x} = (ord($key[$i % length $tkey])
                      + $this->{state}[$i]
                      + $this->{x})
                     & 0xFF;

        my $tmp = $this->{state}[$i];
        $this->{state}[$i]         = $this->{state}[$this->{x}];
        $this->{state}[$this->{x}] = $tmp;
    }

    $this->{x} = 0;
}

# PRGA
sub crypt {
    my ($this, $tinput) = @_;
    my @input = split //, $tinput;

    my @output;
    for (1 .. length $tinput) {
        push @output, undef;
    }
    
    for my $i (0 .. (length $tinput) - 1) {
        $this->{x} = ($this->{x} + 1) & 0xFF;
        $this->{y} = ($this->{state}[$this->{x}] + $this->{y}) & 0xFF;
        
        my $tmp = $this->{state}[$this->{x}];
        $this->{state}[$this->{x}] = $this->{state}[$this->{y}];
        $this->{state}[$this->{y}] = $tmp;
        
        my $r
            = $this->{state}[
                  ($this->{state}[$this->{x}] + $this->{state}[$this->{y}])
                & 0xFF
            ];
        $output[$i] = chr(ord($input[$i]) ^ $r);
    }

    my $output = '';
    for my $char (@output) {
        $output .= sprintf('%X', ord($char));
    }

    return $output;
}

1;

