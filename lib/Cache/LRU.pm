package Cache::LRU;
use warnings;
use utf8;

sub new {
    my $class = shift;

    my %args = @_;

    bless {
        max_size => $args{max_size} || 3,
        current_size => 0,
        cache        => {},
        start_key    => undef,
        end_key      => undef,
    }, $class;
}

sub max_size {
    my $self = shift;

    $self->{max_size};
}

sub current_size {
    my $self = shift;

    $self->{current_size};
}

sub set {
    my ($self, $key, $value) = @_;

    if (my $current = $self->{cache}{$key}) {
        $self->{cache}{ $current->{prev_key} }{next_key} = $current->{next_key}
            if $current->{prev_key};
        $self->{cache}{ $current->{next_key} }{prev_key} = $current->{prev_key} || $key
            if $current->{next_key};

    }
    else {
        $self->{current_size}++;
    }

    if ($self->current_size > $self->max_size) {
        $self->{current_size}--;

        my $booby_key = $self->{cache}{ $self->{end_key} }{prev_key};
        delete $self->{cache}{ $self->{end_key} } if defined $self->{end_key};
        $self->{end_key} = $booby_key;
    }

    $self->{cache}{$key} = {
        prev_key => undef,
        next_key => $self->{start_key},
        value    => $value,
    };

    $self->{start_key} = $key;
    $self->{end_key} = $key if not defined $self->{end_key};
}

sub get {
    my ($self, $key) = @_;

    my $current = $self->{cache}{$key};

    return if not $current;

    $self->{cache}{ $current->{prev_key} }{next_key} = $current->{next_key} if $current->{prev_key};
    $self->{cache}{ $current->{next_key} }{prev_key} = $current->{prev_key} || $key
        if $current->{next_key};
    $self->{start_key} = $key;
    if ($self->{end_key} && $key eq $self->{end_key}) {
        $self->{end_key} = $current->{prev_key};
    }

    $current->{value};
}

sub remove {
    my ($self, $key) = @_;

    my $current = $self->{cache}{$key};

    return if not $current;

    $self->{current_size}--;

    $self->{cache}{ $current->{prev_key} }{next_key} = $current->{next_key} if $current->{prev_key};
    $self->{cache}{ $current->{next_key} }{prev_key} = $current->{prev_key} if $current->{next_key};
    $self->{start_key} = $current->{next_key} if $self->{start_key} && $key eq $self->{start_key};
    $self->{end_key}   = $current->{prev_key} if $self->{end_key}   && $key eq $self->{end_key};

    delete $self->{cache}{$key};
}

1;
