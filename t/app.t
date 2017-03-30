use strict;

use Test::More;
use Plack::Test;

use Try::Tiny;

use HTTP::Request::Common;

use JSON::MaybeXS qw/ decode_json encode_json /;

use Albatross::SocialNetwork;

my $sut = Plack::Test->create(Albatross::SocialNetwork->to_app);

subtest 'Fetch root dir' => sub {
    my $res = $sut->request(GET "/");
    ok $res->is_success, 'Fetching / succeeds';
    my $json = try { decode_json($res->decoded_content) };
    isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
    is_deeply $json, {}, '. . . and it returns the right JSON';
};

subtest 'Check login' => sub {
    my $res = $sut->request(GET '/ping');
    is $res->code, 403, 'The /ping path never returns a 401, to avoid the browser auth dialog';
};

subtest 'Successful login' => sub {
    my $params = {
    };

    subtest 'No login id' => sub {
        delete local $params->{login_id};

        my $res = $sut->request(POST '/login', ContentType => 'application/json', Content => encode_json($params));
        is $res->code, 403, 'Trying to login without a login_id fails';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json->{errors}, [ { code => 'badparams', msg => 'You must supply a login_id', } ], '. . . and it returns the right errors';
    };
};

done_testing();
