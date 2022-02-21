use Email::MIME;

unit class Net::IMAP::Message;

has $.imap;
has $.mailbox;
has $!sid;
has $!uid;
has $!flags;
has $!header-data;
has $!data;
has @!flags;

method new(:$imap, :$mailbox, :$sid, :$uid) {
    my $self = self.bless(:$imap, :$mailbox);
    $self._init($sid, $uid);
    return $self;
}
method _init($sid, $uid) {
    $!sid = $sid if $sid;
    $!uid = $uid if $uid;
}

method mime-headers() {
    # XXX Very inefficient
    self.mime.header-obj
}

method data() {
    unless $!data {
        if $.mailbox ne $.imap.mailbox {
            fail "Mailbox changed";
        }
        my $resp;
        if $!uid {
            $resp = $.imap.raw.uid-fetch($!uid, "BODY[]");
        }
        else {
            $resp = $.imap.raw.fetch($!sid, "BODY[]");
        }
        fail "Bad fetch" unless $resp ~~ /\w+\hOK\N+$/;

        my @lines = $resp.split("\r\n");
        my $bytes = 0;
        my $seenbytes = 0;
        my $data;
        for @lines {
            if /^\* \s+ \d+ \s+ FETCH .+ BODY\[\] \s+ \{(\d+)\}/ {
                $bytes = $0.Int;
                next;
            }
            if $bytes {
                if $seenbytes >= $bytes {
                    $!data = $data;
                    return $!data;
                }
                $seenbytes += $_.chars + 2; # include \r\n line ending
                $data ~= $_ ~ "\r\n";
            }
        }
    }
    $!data
}

method mime() {
    my $data := self.data;
    $data.defined
      ?? Email::MIME.new($data)
      !! $data
}

method uid() {
    unless $!uid {
        fail "Mailbox changed" if $.mailbox ne $.imap.mailbox;

        my $resp := $.imap.raw.fetch($!sid, "UID");
        fail "Bad fetch" unless $resp ~~ /\w+\hOK\N+$/;
        $resp ~~ /\* \s+ \d+ \s+ FETCH .+ UID \s+ (\d+)/;
        $!uid = $0.Int;
    }
    $!uid
}

method sid() {
    unless $!sid {
        fail "Mailbox changed" if $.mailbox ne $.imap.mailbox;

        my $resp := $.imap.raw.uid-fetch($!uid, "UID");
        fail "Bad fetch" unless $resp ~~ /\w+\hOK\N+$/;
        $resp ~~ /\* \s+ (\d+) \s+ FETCH .+ UID \s+/;
        $!sid = $0.Int;
    }
    $!sid
}

multi method flags() {
    unless @!flags {
        fail "Mailbox changed" if $.mailbox ne $.imap.mailbox:

        my $resp;
        if $!uid {
            $resp = $.imap.raw.uid-fetch($!uid, "FLAGS");
        } else {
            $resp = $.imap.raw.fetch($!sid, "FLAGS");
        }
        fail "Bad fetch" unless $resp ~~ /\w+\hOK\N+$/;
        my @lines = $resp.split("\r\n");
        @lines .= grep(/^\*\s+\d+\s+FETCH/);
        @lines[0] ~~ /FLAGS\s+\((<-[\)]>*)\)/;
        @!flags = $0.Str.words;
    }
    @!flags
}

multi method flags(@new) {
    if $.mailbox ne $.imap.mailbox {
        fail "Mailbox changed";
    }
    @!flags = @new;
    my $resp;
    if $!uid {
        $resp = $.imap.raw.uid-store($!uid, 'FLAGS.SILENT', @new);
    } else {
        $resp = $.imap.raw.store($!sid, 'FLAGS.SILENT', @new);
    }
    fail "Bad store" unless $resp ~~ /\w+\hOK\N+$/;
    return True;
}

method delete() {
    fail "Mailbox changed" if $.mailbox ne $.imap.mailbox;

    my @flags = self.flags;
    @flags.push('\Deleted') unless @flags.grep(/\\Deleted/);
    my $result := self.flags(@flags);
    return $result unless $result;
    $.imap.raw.expunge;
    True
}

method copy($mailbox) {
    fail "Mailbox changed" if $.mailbox ne $.imap.mailbox;

    my $resp;
    if $!uid {
        $resp = $.imap.raw.uid-copy($!uid, $mailbox);
    } else {
        $resp = $.imap.raw.copy($!sid, $mailbox);
    }
    fail "Bad copy" unless $resp ~~ /\w+\hOK\N+$/;
    True
}

# vim: expandtab shiftwidth=4
