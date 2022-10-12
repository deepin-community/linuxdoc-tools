#!/bin/sh
#
# $Id: make-one.sh,v 1.1.1.1 2001/05/24 15:57:39 sano Exp $
#
# make one user-specified howto into all available formats
# ---------------------------------------------------------
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

# stick the filename in a variable that's readable
file=$1

if [ -f $HOWTOS/$file ]
then

   for FORMAT in $FORMATS
   do
      if [ -d $HOWTOS/$FORMAT ]
      then
	cd $HOWTOS/$FORMAT
	echo "..................processing $file........................."
	sgml2$FORMAT $HOWTOS/$file
      else
        echo "can't cd to $FORMAT subdirectory"
      fi
   done

else
   echo "exiting - no file $file found in dir $HOWTOS..."
fi
