class Net::IMAP::Message;

has $.pop;
has $!mailbox;
has $!sid;
has $!uid;
has $!flags;
has $!header-data;
has $!data;
has @!flags;

method mime-headers {
    die "NYI";
}

method data {
    die "NYI";
}

method mime {
    die "NYI";
}

method uid {
    die "NYI";
}

method sid {
    die "NYI";
}

method flags {
    die "NYI";
}

method delete {
    die "NYI";
}
