@ECHO OFF
:BEGIN
CLS
@ECHO START RAILS SERVER PRODUCTION
cd "C:\web applications\projectone"
rails s -e "production"
:END