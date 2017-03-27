use strict;

use Test::More;
use Plack::Test;

use Try::Tiny;

use HTTP::Request::Common;

use JSON::MaybeXS qw/ decode_json /;

use Albatross::SocialNetwork;

my $sut = Plack::Test->create(Albatross::SocialNetwork->to_app);

subtest 'Fetch root dir' => sub {
    my $res = $sut->request(GET "/");
    my $json = try { decode_json($res->decoded_content) };
    isnt $json, undef or diag $res->decoded_content;
    is_deeply $json, {};
};

done_testing();
