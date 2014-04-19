class Net::IMAP::Simple;

has $.raw;

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
