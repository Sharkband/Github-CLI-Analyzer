# Github-CLI-Analyzer


create a .env file and put your Github token inside like

GITHUB_TOKEN=your_github_personal_access_token


you can also create a .bat(if on Windows) file to run the app and put this script inside

@echo off

cd /d "path/to/project"

cmd /k ruby bin/github-analyzer analyze


