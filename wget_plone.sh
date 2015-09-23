#!/bin/bash
# wget_plone.sh -- created 2010-02-25, davidjb.com
# @Last Change: 30-July-2010.
# @Revision:    2.0

#USAGE: ./wget_plone.sh SITE_NAME [username] [password]
#When executed with a username and password, the script attempts to authenticate with the site
#and obtain a session cookie for access.  When used without login credentials, the site is 
#copied anonymously.
#
#Joomla: 
#find . -name "pdf.html" -print0 | xargs -0 rename 's/pdf.html/article.pdf/g'
#find . -name "*.html" -print0 | xargs -0 sed -i "s/pdf.html/article.pdf/g"


cookies_file="cookies-test.txt"
login_file="login_form"
WGET_COMMON_OPTS='--no-parent
         --no-check-certificate
         --recursive
         --adjust-extension
         --convert-links
         --restrict-file-names=windows
         --level=inf
         --page-requisites
         -e robots=off
         --wait=0
         --quota=inf
         --timestamping
         --reject "*_form,RSS,*login*,logged_in,*logout*,logged_out,full_review_list,createObject*,select_default_page,selectViewTemplate*,object_cut,object_copy,object_rename,delete_confirmation,content_status_*,addtoFavorites,pdf.html,print.html,*@@search*,@@content-checkout,*@@history*,versions_history_form,edit,atct_edit,sharing,select_default_view,@@manage-portlets,@@manage-viewlets,@@manage-content-rules,placeful_workflow_configuration,*folder_factories,*++add++*,*folder_contents?*select=screen"
         --exclude-directories="search,*@@search*,*com_mailto*"'

function display_help {
    echo "Usage: wget_plone.sh SITE_URL [USERNAME PASSWORD]
    When executed with a username and password, the script
    attempts to authenticate with the site and obtain a session
    cookie for access.  When used without login credentials, the
    site is copied anonymously."
    exit 0
}

function cleanup {
    echo "Cleaning up files.  Please remain calm."
    if [[ -e "$cookies_file" ]]; then
        rm --verbose "$cookies_file"
    fi

    if [[ -e "$login_file" ]]; then
        rm --verbose "$login_file"
    fi

    exit $1
}

if [[ "$1" == "--help" ]] || [[ -z "$1" ]]; then
    display_help
fi

# Get our Plone site down!
# With authentication
if [[ -n "$2" ]] && [[ -n "$3" ]]; then
    echo "
    WARNING: To run this script with an admin user account or account 
    with elevated privileges put your site in read-only, as this 
    process will hit ALL links on the site. Or you could 
    attempt this process with AT MOST a 'Reader' account or 
    someone without Edit rights anywhere.
    -----------------------------------------------------------
    Consider yourself warned.  Do you wish to continue? (y/n)"
    read -e acceptance

    shopt -s nocasematch
    if [[ $acceptance != "y" ]] && [[ $acceptance != "yes" ]]; then
        exit 0
    fi
    shopt -u nocasematch

    wget --keep-session-cookies \
         --no-check-certificate \
         --save-cookies "$cookies_file" \
         --user $2 \
         --password $3 \
         --output-document=/dev/null \
         $1

    wget --keep-session-cookies \
         --no-check-certificate \
         --save-cookies "$cookies_file" \
         --user $2 \
         --password $3 \
         --post-data "__ac_name=$2&__ac_password=$3&form.submitted=1&cookies_enabled=1&js_enabled=0" \
         --output-document=/dev/null \
         $1/login_form

    if [[ `cat $cookies_file | wc -l` -lt 5 ]]; then
        echo "Cookie file size too short.  Confirm that you entered the right username and password."
        echo "Aborting wget process..."
        cleanup 1
    fi

    wget --load-cookies $cookies_file \
         --user $2 \
         --password $3 \
         $WGET_COMMON_OPTS \
         $1

# Without authentication
else
    wget $WGET_COMMON_OPTS \
         $1
fi

#Normalise the folder name, removing protocol and any slashes from the end
folder=$1
folder=${folder##http://}
folder=${folder##https://}
folder=${folder%%/}

#Start formatting our actual web address accordingly
escaped_address=${1%%/}

#Escape our site URL for use within the upcoming commands
escaped_address=${escaped_address////\\\/}

#Get and fix up references to images within CSS.
pushd $folder/portal_css/*
images=`grep -R -h -o -P "$escaped_address/?([\w])+\.(png|gif|jpg)" *`
if [[ -n $images ]]; then
    echo ${images} | xargs wget -nc
    find . -name "*.css" -print0 | xargs -0 sed -i "s/$escaped_address\///g"
fi
popd

#Finally, remove any remaining absolute links.  These will include things we've exlcuded
#such as login_form, sendto_form, search and so forth.  They will be replaced so they go 
#nowhere.
echo "Fixing up any remaining absolute links to point to --> '#'..."
find $folder -name "*.html" -print0 | xargs -0 sed -i -r "s/$escaped_address[a-zA-Z0-9\_\/\.\=\%\&\:\;\-]*/\#/g"
echo "Fixing spaces in @import url"
find $folder -type f -a -name "*.html" -print0 | xargs -0 sed -i -r "s/(@import url[\(\.a-zA-Z\_\/]*)\s/\1%20/g"
echo "Removing unwanted elements"
find $folder -type f -a -name "*.html" -exec ./html-rm.py --xpaths='//div[@id="edit-bar"] //div[@id="portal-personaltools"] //div[@class="managePortletsLink"]' --file={} \;

echo "View in your default web browser? (y/n)"
read -e acceptance

shopt -s nocasematch
if [[ $acceptance == "y" ]] || [[ $acceptance == "yes" ]]; then
    open "$folder/index.html" &
fi
shopt -u nocasematch

echo -e "Wget process complete.  Your site is now available in the $folder directory."
cleanup 0

# vi: 
