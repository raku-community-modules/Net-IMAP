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
    $.raw.select($mailbox);
    return True;
}

method authenticate($user, $pass) {
    $.raw.login($user, $pass);
    return True;
}

method create($mailbox) {
    $.raw.create($mailbox);
    return True;
}

method delete($mailbox) {
    $.raw.delete($mailbox);
    return True;
}

method rename($old, $new) {
    $.raw.rename($old, $new);
    return True;
}

method subscribe($mailbox) {
    $.raw.subscribe($mailbox);
    return True;
}

method unsubscribe($mailbox) {
    $.raw.unsubscribe($mailbox);
    return True;
}

method mailboxes {
    die "NYI";
}

method append($message) {
    $.raw.append($.mailbox, ~$message);
    return True;
}

method copy($mailbox, :$sid, :$uid) {
    if(:$uid){
        $.raw.uid-copy($uid, $mailbox);
    } else {
        $.raw.copy($sid, $mailbox);
    }
    return True;
}
