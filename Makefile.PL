use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'S3::REST::Auth',
    AUTHOR           => q{Burl Nyswonger <bnyswonger@marchex.com>},
    VERSION_FROM     => 'lib/S3/REST/Auth.pm',
    ABSTRACT_FROM    => 'lib/S3/REST/Auth.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'URI' => 1.40,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'S3-REST-Auth-*' },
);
