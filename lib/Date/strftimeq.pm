## no critic: Modules::ProhibitAutomaticExportation

package Date::strftimeq;

# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use POSIX ();
use Scalar::Util 'blessed';

use Exporter 'import';
our @EXPORT = qw(strftimeq);

our $regex = qr{
                   (?(DEFINE)
                       (?<def_code> ( [^()]+ | \((?&def_code)\) )*)
                   )
                   (?<all>

                       (?<convspec>
                           %
                           (?<flags> [_0^#-]+)?
                           (?<width> [0-9]+)?
                           (?<alt>[EO])?
                           (?<convletter> [%aAbBcCdDeEFgGhHIjklmMnOpPrRsStTuUVwWxXyYZz+])
                       )|
                       (?<qconvspec>
                           %\(
                           (?<code> (?&def_code))
                           \)q)
                   )
           }x;

# faster version, without using named capture
if (0) {
}

sub strftimeq {
    my ($format, @time) = @_;

    my ($caller_pkg) = caller();
    my %compiled_code;

    $format =~ s{$regex}{
        # for faster acccess
        my %m = %+;

        #use DD; dd \%m; # DEBUG

        if (exists $m{code}) {
            unless (defined $compiled_code{$m{code}}) {
                #say "D: compiling $m{code}"; # DEBUG
                $compiled_code{$m{code}} = eval "package $caller_pkg; no strict; no warnings; sub { $m{code} }";
                die "Can't compile code in $m{all}: $@" if $@;
            }
            my $code_res = $compiled_code{$m{code}}->(@time);
            $code_res //= "";
            $code_res =~ s/%/%%/g;
            $code_res;
        } else {
            $m{all};
        }
    }xego;

    POSIX::strftime($format, @time);
}

1;
# ABSTRACT: POSIX::strftime() with support for embedded perl code in %(...)q

=head1 SYNOPSIS

 use Date::strftimeq; # by default exports strftimeq()

 my @time = localtime();
 print strftimeq '<%-6Y-%m-%d>', @time; # <  2019-11-19>
 print strftimeq '<%-6Y-%m-%d%( require Date::DayOfWeek; Date::DayOfWeek::dayofweek($_[3], $_[4]+1, $_[5]+1900) == 0 ? "sun":"" )q>', @time; # <  2019-11-19>
 print strftimeq '<%-6Y-%m-%d%( require Date::DayOfWeek; Date::DayOfWeek::dayofweek($_[3], $_[4]+1, $_[5]+1900) == 2 ? "tue":"" )q>', @time; # <  2019-11-19tue>


=head1 DESCRIPTION

This module provides C<strftimeq()> which extends L<POSIX>'s C<strftime()> with
a conversion: C<%(...)q>. Inside the parenthesis, you can specify Perl code. The
Perl code will receive the arguments passed to strftimeq() except for the
first). The Perl code will be eval-ed in the caller's package, without L<strict>
and without L<warnings>.


=head1 FUNCTIONS

=head2 strftimeq

Usage:

 $str = strftimeq $fmt, $sec, $min, $hour, $mday, $mon, $year;


=head1 SEE ALSO

L<POSIX>'s C<strftime()>

L<DateTimeX::strftimeq>

=cut
