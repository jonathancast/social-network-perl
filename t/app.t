use strict;
use warnings;

use Test::More;
use Plack::Test;

use Try::Tiny;

use HTTP::Cookies;
use HTTP::Request::Common;

use JSON::MaybeXS qw/ decode_json encode_json /;

use lib 't/lib';

use T::TestDB;

use Albatross::SocialNetwork;

my $host = 'https://albatross.localdomain:8080';

my $sut = Plack::Test->create(Albatross::SocialNetwork->to_app);

my $fred_login = {
    login_id => 'fred',
    password => 'xxxx1234',
};

schema->resultset('User')->create({
    %$fred_login,
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
    my $params = $fred_login;

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
        my $jar = HTTP::Cookies->new();

        my $res = $sut->request(POST "$host/login", ContentType => 'application/json', Content => encode_json($params));
        is $res->code, 200, 'Trying to login with valid info succeeds';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json, { login_id => 'fred', }, '. . . and it returns the right value' or diag explain $json;

        $jar->extract_cookies($res);

        my $req = GET "$host/ping";
        $jar->add_cookie_header($req);
        $res = $sut->request($req);
        is $res->code, 200, 'Checking for a valid session after logging in succeeds';
        $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json, {}, '. . . and it returns the right value' or diag explain $json;
    };
};

subtest 'logout' => sub {
    my $jar = HTTP::Cookies->new();

    my $res = $sut->request(POST "$host/login", ContentType => 'application/json', Content => encode_json($fred_login));
    is $res->code, 200, 'Trying to login with valid info succeeds';
    $jar->extract_cookies($res);

    my $req = GET "$host/ping";
    $jar->add_cookie_header($req);
    $res = $sut->request($req);
    is $res->code, 200, 'Checking for a valid session after logging in succeeds';

    $req = POST "$host/logout";
    $jar->add_cookie_header($req);
    $res = $sut->request($req);
    is $res->code, 200, 'You can logout if you have logged in successfully';
    my $json = try { decode_json($res->decoded_content) };
    isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
    is_deeply $json, {}, '. . . and it returns the right value' or diag explain $json;

    $req = GET "$host/ping";
    $jar->add_cookie_header($req);
    $res = $sut->request($req);
    is $res->code, 403, 'Checking the session after logging out fails';
};

done_testing();
