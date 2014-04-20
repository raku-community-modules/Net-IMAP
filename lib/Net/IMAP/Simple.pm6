class Net::IMAP::Simple;

use Net::IMAP::Message;

has $.raw;
has $.mailbox;

method new(:$raw!){
    my $self = self.bless(:$raw);
    
    my $greeting = $self.raw.get-response;

    # capabilities list, etc...

    return $self;
}

method quit {
    $.raw.logout;
    $.raw.conn.close;
    return True;
}
method logout { self.quit }

method get-message(:$uid, :$sid) {
    die "NYI";
}

method search(*%params) {
    die "NYI";
}

method select($mailbox) {
    $.mailbox = $mailbox;
    die "NYI";
}

method authenticate($user, $pass) {
    die "NYI";
}

method create($mailbox) {
    die "NYI";
}

method remove($mailbox) {
    die "NYI";
}

method rename($mailbox) {
    die "NYI";
}

method subscribe($mailbox) {
    die "NYI";
}

method unsubscribe($mailbox) {
    die "NYI";
}

method mailboxes {
    die "NYI";
}

method append($message) {
    die "NYI";
}
