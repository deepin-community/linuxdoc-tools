
all: rtf2rtf

rtf2rtf: rtf2rtf.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o rtf2rtf rtf2rtf.c -lfl

rtf2rtf.c: rtf2rtf.l
	$(LEX) -t rtf2rtf.l>rtf2rtf.c

install: rtf2rtf
	cp rtf2rtf /usr/local/bin

clean:
	rm -f rtf2rtf.c rtf2rtf core
