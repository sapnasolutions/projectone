@ECHO OFF
:BEGIN
CLS
@ECHO START RAILS JOBS PRODUCTION
cd "C:\web applications\projectone"
rake jobs:work rails_env="production"
:END