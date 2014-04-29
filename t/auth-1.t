#!/usr/bin/env perl
use strict;
use warnings;
use lib qw< lib >;

use Test::More tests => 2;


BEGIN {
    #
    # values used are same as given in example of S3 Dev guide:
    #   http://s3.amazonaws.com/doc/s3-developer-guide/RESTAuthentication.html
    #
    $ENV{S3_SECRET_KEY} = 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV';
    $ENV{S3_ACCESS_KEY} = '44CF9590006BF252F707';
    $ENV{S3_BUCKET} = '';
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

my $should_be = 'https://s3.amazonaws.com/quotes/nelson?AWSAccessKeyId=44CF9590006BF252F707&Expires=1141889120&Signature=vjbyPxybdZaNmGa%2ByT272YEAiv4%3D';

# class method
{
    my $generated = S3::REST::Auth->TemporaryURL('quotes/nelson', 60);
    is($generated, $should_be, "class method, using envvars keys");
}

# object method
{
    my $obj = S3::REST::Auth->new();
    my $generated = $obj->TemporaryURL('quotes/nelson', 60);
    is($generated, $should_be, "object method using envvars for keys");
}

