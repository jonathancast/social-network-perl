package Albatross::SocialNetwork;

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::DBIC;

use Try::Tiny;

set serializer => 'JSON';

any '/**' => sub {
    pass if request->path eq '/';

    if (!session('user') && request->path !~ m{^/login\b}) {
        if (request->path =~ m{^/ping}) { # special '/ping' path: allows front-end to test for a valid login
            status 'forbidden';
        } else {
            status 'unauthorized';
        }
        return {
            errors => [ { code => 'forbidden', msg => 'You need to log in to access this page', }, ],
        };
    }

    pass;
};

get '/' => sub {
    return {};
};

post '/login' => sub {
    my $login_id = params->{login_id};
    unless ($login_id) {
        status 'forbidden';
        return { errors => [ { code => 'badparams', missing => [ 'login_id', ], msg => 'You must supply a login_id', }, ], };
    }

    my $password = params->{password};
    unless ($password) {
        status 'forbidden';
        return { errors => [ { code => 'badparams', missing => [ 'password', ], msg => 'You must supply a password', }, ], };
    }

    my $user = schema->resultset('User')->find({ login_id => $login_id, });
    unless ($user && $user->check_password($password)) {
        status 'forbidden';
        return { errors => [ { code => 'badlogin', msg => 'The username or password you supplied is incorrect', }, ], };
    }

    session user => $user;

    return $user->as_hash(qw/ login_id /);
};

post '/logout' => sub {
    app->destroy_session();

    return {};
};

get '/ping' => sub {
    return {};
};

get '/friend/outgoing' => sub {
    my @friends = session('user')->friends->search_related('friend')->all();

    return { friend_requests => [ map { $_->as_hash(qw/ login_id /) } @friends ], };
};

get '/friend/incoming' => sub {
    my @friends = session('user')->admirers->search_related('user')->all();

    return { friend_requests => [ map { $_->as_hash(qw/ login_id /) } @friends ], };
};

1;
