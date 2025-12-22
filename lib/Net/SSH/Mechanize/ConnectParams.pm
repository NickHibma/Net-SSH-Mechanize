package Net::SSH::Mechanize::ConnectParams;
use Moose;

# VERSION

has 'host' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

has 'user' => (
    isa => 'Str',
    is => 'rw',
);

has 'password' => (
    isa => 'Str',
    is => 'rw',
    predicate => 'has_password',
);

has 'port' => (
    isa => 'Int',
    is => 'rw',
    default => 22,
);

has 'options' => (
    traits => ['Hash'],
    isa => 'HashRef[Str]',
    is => 'rw',
    default => sub { {} },
    handles => {
        ssh_options => 'keys',
        get_option => 'get',
    },
);

has 'flags' => (
    traits => ['Array'],
    isa => 'ArrayRef[Str]',
    is => 'rw',
    default => sub { [] },
    handles => {
        get_flags => 'elements',
    },
);

sub ssh_options_ordered {
    my $self = shift;

    # For now this returns a sorted list of the options keys, but this might be
    # changed in the future depending on ordering requirements of certain
    # options.

    return sort $self->ssh_options;
}

sub ssh_cmd {
    my $self = shift;

    my @cmd = ('/usr/bin/ssh');

    push @cmd, '-t';
    push @cmd, '-p', $self->port,
        if defined $self->port;
    push @cmd, '-l', $self->user
        if defined $self->user;
    push @cmd, '-' . $_
        for $self->get_flags;
    push @cmd, '-o', $_ . '=' . $self->get_option($_)
        for $self->ssh_options_ordered;

    push @cmd, $self->host;
    push @cmd, 'sh';

    return @cmd;
}



__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Net::SSH::Mechanize::ConnectParams - encapsulates information about an ssh connection

=head1 SYNOPSIS

This class is just a container for log-in details with a method which
constructs an approprate C<ssh> command invocation.

This equates to C</usr/bin/ssh -t somewhere.com sh>:

    my $minimal_params = Net::SSH::Mechanize::ConnectParams->new(
        host => 'somewhere.com',
    );

This equates to C</usr/bin/ssh -t -p 999 -l someone somewhere.com sh>:

    my $all_params = Net::SSH::Mechanize::ConnectParams->new(
        host => 'somewhere.com',
        user => 'someone',
        port => 999,
        password => 'secret',
    );

To silence ssh add the flags parameter C<-q>:

    my $all_params = Net::SSH::Mechanize::ConnectParams->new(
        host => 'somewhere.com',
        user => 'someone',
        port => 999,
        password => 'secret',
        flags => [ 'q' ],
    );

To connect without public key checks C</usr/bin/ssh -t -p 999 -l someone -o
StrictHostKeyChecking=no -o UserKnownHostsFile=none somewhere.com sh>, add
the options parameter:

    my $all_params = Net::SSH::Mechanize::ConnectParams->new(
        host => 'somewhere.com',
        user => 'someone',
        port => 999,
        password => 'secret',
        options => {
            UserKnownHostsFile    => 'none',
            StrictHostKeyChecking => 'no'
        },
    );

To connect using public key authentication use the following code:

    my $all_params = Net::SSH::Mechanize::ConnectParams->new(
        host => 'somewhere.com',
        user => 'someone',
        port => 999,
        options => {
            PubkeyAuthentication => 'yes',
        },
    );

=head1 CLASS METHODS

=head2 C<< $obj = $class->new(%parameters) >>

Creates a new instance.  Parameters is a hash or a list of key-value
parameters.  Valid parameter keys are:

=over 4

=item C<host>

The hostname to connect to (a scalar string).  Either this or C<connection_params> must
be supplied.

=item C<user>

The name of the user account to log into (a scalar string).  If not
given, no user will be supplied to C<ssh> (this typically means it
will use the current user as default).

=item C<port>

The port to connect to (a positive scalar integer; C<ssh> will default
to 22 if this is not specificed).

=item C<password>

The password to connect with (a scalar string).  This is only required
if authentication will be performed, either on log-in or when sudoing.

=item C<options>

A hashref of options to be preceded by the -o flag in the ssh syntax.

=item C<flags>

An arrayref of ssh flags, e.g. C<[-1246AaCfgKkMNnqsTtVvXxYy]>

=back

=head1 INSTANCE ATTRIBUTES

=head2 C<< $obj->host >>
=head2 C<< $obj->user >>
=head2 C<< $obj->password >>
=head2 C<< $obj->port >>

These are all read-write accessors for the attribute parameters
accepted by the constructor.

=head1 INSTANCE METHODS

=head2 C<< $cmd = $obj->ssh_cmd >>

This constructs the C<ssh> command to invoke.  If you need something
different, you can create a subclass which overrides this method, and
pass that via the C<connection_params> parameter to
C<< Net::SSH::Mechanize->new() >>.


=head1 AUTHOR

Nick Stokoe  C<< <wulee@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Nick Stokoe C<< <wulee@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

