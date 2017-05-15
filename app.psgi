use v5.20;
use warnings;

use Dancer2;

use feature 'signatures';
no warnings 'experimental::signatures';

use Plack::Builder;
use Plack::Response;

use FindBin;
use lib $FindBin::RealBin =~ s{$}{/lib}r;

use Albatross::SocialNetwork;

builder {
    mount '/api' => Albatross::SocialNetwork->to_app,
    mount '/ui' => builder {
        enable "Plack::Middleware::DirIndex", dir_index => 'index.html';
        Plack::App::File->new(root => config->{ui})->to_app
    },
    mount '/' => sub($env) {
        my $res = Plack::Response->new();
        $res->redirect('/ui/index.html', 301);
        return $res->finalize();
    },
}
