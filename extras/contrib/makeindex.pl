From dan@detached.demon.co.uk Mon Mar  4 20:54:09 1996
Received: from burdell.cc.gatech.edu (root@burdell.cc.gatech.edu [130.207.3.207]) by anacreon.cc.gatech.edu (8.7.1/8.6.9) with ESMTP id UAA08880 for <gregh@anacreon.cc.gatech.edu>; Mon, 4 Mar 1996 20:47:07 -0500 (EST)
Received: from detached.demon.co.uk (dan@detached.demon.co.uk [194.222.13.128]) by burdell.cc.gatech.edu (8.7.1/8.6.9) with SMTP id UAA17540 for <gregh@cc.gatech.edu>; Mon, 4 Mar 1996 20:44:19 -0500 (EST)
Received: (from dan@localhost) by detached.demon.co.uk (8.6.12/8.6.12) id BAA01202; Tue, 5 Mar 1996 01:45:08 GMT
Date: Tue, 5 Mar 1996 01:45:08 GMT
Message-Id: <199603050145.BAA01202@detached.demon.co.uk>
From: Daniel Barlow <dan@detached.demon.co.uk>
To: gregh@cc.gatech.edu (Greg Hankins)
Subject: Re: makeindex.pl
In-Reply-To: <199603040501.AAA03412@anacreon.cc.gatech.edu>
References: <199603040501.AAA03412@anacreon.cc.gatech.edu>
X-Attribution: dan
Status: RO

Greg Hankins <gregh@cc.gatech.edu> writes:
>Hi, I was formatting the GCC HOWTO, and I saw the reference to your
>makeindex.pl script.  Could I have a look at it, and possibly
>distribute it with Linuxdoc-SGML?

Certainly.  It comes attached with caveats: to wit, it's a brutal
kludge.  It works for me, for the GCC HOWTO, but don't expect it to
work in the general case without checking the output it produces.

The way I use it is to insert

<index "chewing gum">

at the point that I want an index entry for `chewing gum' (the
intention is that you can have arbitrary markup as well, but this
doesn't work for anything other than  the cases that `sub textof'
deals with) and

<PRINTINDEX>

at the end of the document.  I'll probably keep playing with it as I
find new things for it to do, but for anyone who finds it useful in
its current form, this is the thing.

---cut here---
#!/usr/bin/perl

$/='';				# input in paragraphs
$idxnum=0;

print "             <!-- Warning to the author: -->\n";
print "<!-- Automatically generated by $0: EDIT THE SOURCE INSTEAD -->\n";
while(<STDIN>) {
    s@<([a-z]+),([^,]+),@<$1>$2</$1>@gs;
    while(s@\<index\W\"([^\"]*)\"\>@<label id="index.$idxnum"> <!-- $1 -->@ ){
        $indices{$1}.="$idxnum:";
#	print STDERR $1."   ";
#	print STDERR &textof($1)."\n";
        $idxnum++;
    };
    &printindex if(/\<PRINTINDEX\>/) ;
    print;
}

sub printindex {
    while (($text,$refs) = each %indices) {
	$entry="\n<item> $text ";
	foreach $ref(split(/:/,$refs)) {
	    $entry.="<ref id=\"index.$ref\" name=\"$ref\"> ";
	}
	push(@ndex,$entry);
    }
    print <<MESSAGE
<sect>Index

<p>Entries starting with a non-alphabetical character are listed in ASCII
order.

<itemize>

MESSAGE
    ;
    @ndex=(sort textonly @ndex);
    print @ndex;
    print "\n</itemize>\n\n";
    $_="";
}

sub textonly { &textof($a) cmp &textof($b) };

# Vicious and kludgey markup stripper.  Doesn't have to be perfect (isn't)
# but must remove all leading crud so that index sorts properly

sub textof {
    local($bar)=@_;
    while($bar ne $foo) {
	$foo = $bar;
	$bar =~ s/\<[^\/\>]*.//g;
	$bar =~ s/&[A-Za-z]*;//g;
    }
    $bar=~tr/A-Z/a-z/;
    $bar;
}
---cut here---

I intend to give the ELF HOWTO an index in its next version (mainly
for the practice), so that might knock out a few more oddities

Daniel
--
http://ftp.linux.org.uk/~barlow/, dan@detached.demon.co.uk, PGP key ID 5F263625

 ``Consistency is the last refuge of the unimaginative''      --- Oscar Wilde

