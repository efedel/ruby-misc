#!/bin/sh

PRY=`which pry`
echo 'pry: IRB replacement with doc browsing and syntax highlighting'
echo 'http://pry.github.com/'
echo 'Usage: https://github.com/pry/pry/wiki'
[ -z "$PRY" ] && echo 'gem install pry' || pry
