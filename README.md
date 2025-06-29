# Github-CLI-Analyzer

create a .env file and put your Github token inside like

GITHUB_TOKEN=your_github_personal_access_token

RUN LOCALLY:

bundle install (if your using bundler)

you can also create a .bat(if on Windows) file to run the app and put this script inside

@echo off

cd /d "path/to/project"

cmd /k ruby bin/github-analyzer analyze


USING DOCKER:

docker build -t github-analyzer .

docker run --rm -it -p 4567:4567 --env-file .env github-analyzer


