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
    if $uid {
        return Net::IMAP::Message.new(:imap(self), :mailbox($.mailbox), :$uid);
    } else {
        return Net::IMAP::Message.new(:imap(self), :mailbox($.mailbox), :$sid);
    }
}

method search(*%params) {
    my $resp = $.raw.search(|%params);
    my @lines = $resp.split("\r\n");
    @lines .= grep(/^\*\s+SEARCH/);
    my @messages = @lines[0].comb(/\d+/);
    @messages .= map({ Net::IMAP::Message.new(:imap(self), :mailbox($.mailbox), :sid($_)) });
    return @messages;
}

method select($mailbox) {
    $!mailbox = $mailbox;
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

method mailboxes(:$subscribed) {
    my $resp;
    if $subscribed {
        $resp = $.raw.lsub('""', '*');
    } else {
        $resp = $.raw.list('""', '*');
    }
    my @lines = $resp.split("\r\n");
    my @boxes;
    for @lines {
        if /^\*\s+L...\s+\(\)\s+\S+\s+(.+)$/ {
            @boxes.push($0.Str);
        }
    }
    return @boxes;
}

method append($message) {
    $.raw.append($.mailbox, ~$message);
    return True;
}
