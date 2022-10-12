
#!/bin/sh
#
# $Id: make-all.sh,v 1.1.1.1 2001/05/24 15:57:39 sano Exp $
#
# make all available howtos into all available formats
# -----------------------------------------------------
# this assumes a directory structure with subdirectories named
# txt, html, info, ps under the $HOWTO directory that contains
# files of the format "something-howto"
#
# vince@halcyon.com
#
# ---------- start editing here ------------------------------

# where are the howtos
HOWTOS="/home/vince/howtos"

# what formats are available
FORMATS="txt html info ps"

# ---------- stop editing here -------------------------------

if [ -d $HOWTOS ]
then
   cd $HOWTOS

   #-- loop through the howto files ----
   for file in *howto
   do

     #-- loop over the various formats for this file
     for FORMAT in $FORMATS
     do
        if [ -d $HOWTOS/$FORMAT ]
        then
  	  cd $HOWTOS/$FORMAT
    	  echo "..................processing $file ($FORMAT)........................."
	  sgml2$FORMAT $HOWTOS/$file
        else
          echo "can't cd to $FORMAT subdirectory"
        fi
     done

  done

else
   echo "exiting - no dir $HOWTOS found..."
fi
