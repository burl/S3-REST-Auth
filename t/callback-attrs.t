#!/usr/bin/env perl
use strict;
use warnings;
use lib qw< lib >;

use Test::More tests => 4;


BEGIN {
    #
    # make sure no envvars exist that could mask proper behavior...

    delete $ENV{S3_SECRET_KEY};
    delete $ENV{S3_ACCESS_KEY};
    delete $ENV{S3_BUCKET};
}

use S3::REST::Auth;

{
    no warnings 'redefine';
    *S3::REST::Auth::_seconds_into_the_future = sub {
        my($class, $seconds) = @_;
        #
        # the example uses this time value
        #
        return 1141889060 + $seconds;
    };
}

our %GOT = ();
my $should_be = 'https://s3.amazonaws.com/quotes/nelson?AWSAccessKeyId=44CF9590006BF252F707&Expires=1141889120&Signature=vjbyPxybdZaNmGa%2ByT272YEAiv4%3D';


# object method - with keys given as values
{
    my $obj = S3::REST::Auth->new({
        secret_key => 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV',
        access_key => '44CF9590006BF252F707',
    });
    my $generated = $obj->TemporaryURL('quotes/nelson', 60);
    is($generated, $should_be, "object/provided-keys");
}

# object method - with keys given as values
{
    local $GOT{secret} = 0;
    local $GOT{access} = 0;
    my $obj = S3::REST::Auth->new({
        secret_key => sub { get_my_secret() },
        access_key => sub { get_my_access() },
    });
    my $generated = $obj->TemporaryURL('quotes/nelson', 60);
    is($generated, $should_be, "object/callbacks-for-keys");
    is($GOT{secret}, 1, "1 access of closure for secret_key");
    is($GOT{access}, 1, "1 access of closure for access_key");
}

sub get_my_secret {
    $GOT{secret}++;
    return 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV';
}

sub get_my_access {
    $GOT{access}++;
    return '44CF9590006BF252F707';
}
