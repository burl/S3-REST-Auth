package S3::REST::Auth;
use 5.006;
use strict;
use warnings;
use Carp qw< croak >;
use Digest::SHA qw< hmac_sha1 >;
use URI::Escape qw< uri_escape >;
use MIME::Base64 qw< encode_base64 >;

# for more info, see:
#
#     http://s3.amazonaws.com/doc/s3-developer-guide/RESTAuthentication.html
#

our $VERSION = '0.1';

sub COMMON_ATTRS () {
    qw< secret_key access_key expire_seconds method bucket scheme >
};

sub AMAZON_S3_HOST () { "s3.amazonaws.com" }

# defaults
sub _dfl_attr_secret_key { $ENV{S3_SECRET_KEY} || die "no secret key" }
sub _dfl_attr_access_key { $ENV{S3_ACCESS_KEY} || die "no access key" }
sub _dfl_attr_bucket { $ENV{S3_BUCKET} || '' }
sub _dfl_attr_expire_seconds { 30 }
sub _dfl_attr_method { 'GET' }
sub _dfl_attr_scheme { 'https' }

# create getters
do {
    no strict 'refs';
    my $method = $_;
    *{$method} = sub {
        my($self, @bad) = @_;
        croak "method $method is a getter"
            if @bad;
        return ($self->{$method} && ref $self->{$method} eq 'CODE')
            ? $self->{$method}->()
            : $self->{$method};
    };
} for COMMON_ATTRS;

sub new {
    my($class, $args, @bad) = @_;
    croak "too many arguments passed"
        if @bad;
    $args ||= {};
    my %self = map {
        $_ => ((delete $args->{$_}) // $class->can("_dfl_attr_$_")->())
    } COMMON_ATTRS;
    die "unknown named arguments given: @{[sort keys %$args]}"
        if keys %$args;
    return bless {%self}, $class;
}

# only here b/c I dont like having to override CORE::GLOBAL::time in tests
sub _seconds_into_the_future {
    my($class, $seconds) = @_;
    return time() + $seconds;
}

sub TemporaryURL {
    my($self, $path, $expire_seconds, @bad) = @_;
    croak "too many arguments passed"
        if @bad;
    $self = $self->new()
        unless ref $self;
    croak "path is required"
        unless $path && length $path;

    $path = "/$path"
        unless $path =~ m|^/|;

    $expire_seconds ||= $self->expire_seconds();

    my $bucket = $self->bucket();

    my $signbucket = $bucket ? "/$bucket" : '';
    my $signpath = "$signbucket$path";

    my $then = $self->_seconds_into_the_future( $expire_seconds );

    my $material = join("\n",
        $self->method(),     # HTTP Verb
        '',                  # CONTENT-MD5 (optional)
        '',                  # CONTENT-TYPE (optional)
        "".$then,            # expire time, in seconds, since epoch
        $signpath);          # headers..., then resource location (path)

    # create HMAC SHA1 digest, encode base64 and trim possible line-feed
    chomp(my $sig = encode_base64(
        hmac_sha1($material, $self->secret_key)
    ));

    # allow an empty scheme, so that '//...' can work when used in
    # redirects from web pages, etc. and use the "current scheme"
    my $scheme = $self->scheme;
    $scheme .= ':' if $scheme && $scheme !~ /:$/;

    return sprintf("%s//%s%s%s?AWSAccessKeyId=%s&Expires=%s&Signature=%s",
        $scheme,
        ($bucket ? "$bucket." : ''),
        AMAZON_S3_HOST,
        $path,
        $self->access_key,
        $then,
        uri_escape($sig),
    );
}

1;

__END__

=pod

=head1 NAME

S3::REST::Auth - Create URLs for temporary anonymous access to S3 buckets

=head1 SYNOPSIS

  use S3::REST::Auth;

  my $generator = S3::REST::Auth->new({
    secret_key     => 'SecretKey',  # default: $ENV{S3_SECRET_KEY} || die
    access_key     => 'PublicKey',  # default: $ENV{S3_ACCESS_KEY} || die
    bucket         => 'mybucket',   # default: $ENV{S3_BUCKET} || ''
    expire_seconds => '30',         # default: 30
    method         => 'GET',        # default: GET
    scheme         => 'https',      # default: https -- use '' for //
  });

  # you may pass closures for any of these values:
  my $other_gen = S3::REST::Auth->new({
    secret_key => sub { return get_my_super_secret() },
    access_key => sub { return get_my_access_key() },
    ...,
  });

  my $url = $generator->TemporaryURL("/myfolder/myfile.mp3", 90);
  # $url can be accessed for the next 90 seconds...

  # may call as a class method if defaults for new() are available
  my $url = S3::REST::Auth->TemporaryURL("/myfolder/myfile.mp3", 90);


=head1 CAVEATS

=over 4

=item Time Synchronization

Times used for expiring URLs must be (GMT) the number of seconds that
have elapsed since the Unix epoch.  So, time() will work just fine on
most systems.

Note that the shorter the lifetime is, the more time-drift issues
can impact user experience.  Servers shoiuld be +/- 0.5 seconds if using
a good NTP server - but a drift of say, 10 seconds could be a problem
when using a 10 second lifetime.


=back

=cut



