use v5.20;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

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

my $barney_login = {
    login_id => 'barney',
    password => 'xxxx5678',
};

my $fred = schema->resultset('User')->create({
    %$fred_login,
});

my $barney = schema->resultset('User')->create({
    %$barney_login,
});

my $blazey = schema->resultset('User')->create({
    login_id => 'blazey',
    password => 'xxxx9012',
});

$fred->add_to_friends({ friend => $barney->id, });
$blazey->add_to_friends({ friend => $fred->id, });

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

sub setup_login($params, $k) {
    my $jar = HTTP::Cookies->new();

    my $do_request = sub ($req, @args) {
        $req->uri($host.$req->uri);
        $jar->add_cookie_header($req);
        return $sut->request($req, @args);
    };

    my $res = $do_request->(POST '/login', ContentType => 'application/json', Content => encode_json($params));

    ok $res->is_success, 'Login was successful' or return 0;

    $jar->extract_cookies($res);

    try { $res = $k->($do_request); }
    catch { die $_ }
    finally { $do_request->(POST '/logout') };

    return $res;
}

subtest 'friends' => sub {
    setup_login($fred_login, sub ($do_request) {
        my $res = $do_request->(GET '/friend/outgoing');
        ok $res->is_success, 'You can get your list of outgoing friend requests';
        my $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json, { friend_requests => [ { login_id => 'barney', }, ], }, '. . . and it returns the right values' or diag explain $json;

        $res = $do_request->(GET '/friend/incoming');
        ok $res->is_success, 'You can get your list of incoming friend requests';
        $json = try { decode_json($res->decoded_content) };
        isnt $json, undef, '. . . and it returns JSON' or diag $res->decoded_content;
        is_deeply $json, { friend_requests => [ { login_id => 'blazey', }, ], }, '. . . and it returns the right values' or diag explain $json;
    });
};

done_testing();
