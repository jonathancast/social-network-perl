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
    ok $res->is_success, 'Fetching / succeeds';
    my $json = try { decode_json($res->decoded_content) };
    isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
    is_deeply $json, {}, '. . . and it returns the right JSON';
};

done_testing();
