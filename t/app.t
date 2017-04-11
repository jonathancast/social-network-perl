use strict;

use Test::More;
use Plack::Test;

use Try::Tiny;

use HTTP::Request::Common;

use JSON::MaybeXS qw/ decode_json encode_json /;

use lib 't/lib';

use T::TestDB;

use Albatross::SocialNetwork;

my $sut = Plack::Test->create(Albatross::SocialNetwork->to_app);

schema->resultset('User')->create({
    login_id => 'fred',
    password => 'xxxx1234',
});

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

subtest 'Login' => sub {
    my $params = {
        login_id => 'fred',
        password => 'xxxx1234',
    };

    subtest 'No login id' => sub {
        delete local $params->{login_id};

        my $res = $sut->request(POST '/login', ContentType => 'application/json', Content => encode_json($params));
        is $res->code, 403, 'Trying to login without a login_id fails';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json->{errors}, [ { code => 'badparams', missing => [ 'login_id', ], msg => 'You must supply a login_id', } ], '. . . and it returns the right errors';
    };

    subtest 'No password' => sub {
        delete local $params->{password};

        my $res = $sut->request(POST '/login', ContentType => 'application/json', Content => encode_json($params));
        is $res->code, 403, 'Trying to login without a password fails';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json->{errors}, [ { code => 'badparams', missing => [ 'password', ], msg => 'You must supply a password', } ], '. . . and it returns the right errors';
    };

    subtest 'Invalid user' => sub {
        local $params->{login_id} = 'george';

        my $res = $sut->request(POST '/login', ContentType => 'application/json', Content => encode_json($params));
        is $res->code, 403, 'Trying to login with the wrong user fails';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json->{errors}, [ { code => 'badlogin', msg => 'The username or password you supplied is incorrect', } ], '. . . and it returns the right errors';
    };

    subtest 'Invalid password' => sub {
        local $params->{password} = 'yyyy1234';

        my $res = $sut->request(POST '/login', ContentType => 'application/json', Content => encode_json($params));
        is $res->code, 403, 'Trying to login with the wrong password fails';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json->{errors}, [ { code => 'badlogin', msg => 'The username or password you supplied is incorrect', } ], '. . . and it returns the right errors';
    };

    subtest 'Valid login' => sub {
        my $res = $sut->request(POST '/login', ContentType => 'application/json', Content => encode_json($params));
        is $res->code, 200, 'Trying to login with valid info succeeds';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json, { login_id => 'fred', }, '. . . and it returns the right value' or diag explain $json
    };
};

done_testing();
