class Net::IMAP::Message;

use Email::MIME;

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

method mime-headers {
    # XXX Very inefficient
    return self.mime.header-obj;
}

method data {
    unless $!data {
        my $resp;
        if $!uid {
            $resp = $.imap.raw.uid-fetch($!uid, "BODY[]");
        } else {
            $resp = $.imap.raw.fetch($!sid, "BODY[]");
        }

        my @lines = $resp.split("\r\n");
        my $bytes;
        my $seenbytes;
        my $data;
        for @lines {
            if /^\* \s+ \d+ \s+ FETCH .+ BODY\[\] \s+ \{(\d+)\}/ {
                $bytes = $0.Int;
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
    return $!data;
}

method mime {
    return Email::MIME.new(self.data);
}

method uid {
    unless $!uid {
        my $resp = $.imap.raw.fetch($!sid, "UID");
        $resp ~~ /\* \s+ \d+ \s+ FETCH .+ UID \s+ (\d+)/;
        $!uid = $0.Int;
    }
    return $!uid;
}

method sid {
    unless $!sid {
        my $resp = $.imap.raw.uid-fetch($!uid, "UID");
        $resp ~~ /\* \s+ (\d+) \s+ FETCH .+ UID \s+/;
        $!sid = $0.Int;
    }
    return $!sid;
}

multi method flags {
    unless @!flags {
        my $resp;
        if $!uid {
            $resp = $.imap.raw.uid-fetch($!uid, "FLAGS");
        } else {
            $resp = $.imap.raw.fetch($!sid, "FLAGS");
        }
        my @lines = $resp.split("\r\n");
        @lines .= grep(/^\*\s+\d+\s+FETCH/);
        @lines[0] ~~ /FLAGS\s+\((<-[\)]>*)\)/;
        @!flags = $0.Str.words;
    }
    return @!flags;
}

multi method flags(@new) {
    @!flags = @new;
    if $!uid {
        $.imap.raw.uid-store($!uid, 'FLAGS.SILENT', @new);
    } else {
        $.imap.raw.store($!sid, 'FLAGS.SILENT', @new);
    }
    return True;
}

method delete {
    my @flags = self.flags;
    @flags.push('\Deleted') unless @flags.grep(/\\Deleted/);
    self.flags(@flags);
    $.imap.raw.expunge;
    return True;
}

method copy($mailbox) {
    if $!uid {
        $.imap.raw.uid-copy($!uid, $mailbox);
    } else {
        $.imap.raw.copy($!sid, $mailbox);
    }
    return True;
}
