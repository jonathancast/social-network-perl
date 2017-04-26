use Moops;

class Albatross::SocialNetwork::Schema::Result::UserFriend extends DBIx::Class::Core {
    use DBIx::Class::Candy -autotable => v1;

    column user => { data_type => 'int', };
    column friend => { data_type => 'int', };

    primary_key qw/ user friend /;

    belongs_to user => 'Albatross::SocialNetwork::Schema::Result::User';
    belongs_to friend => 'Albatross::SocialNetwork::Schema::Result::User';
}

1;
