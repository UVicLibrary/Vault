# Troubleshooting Setup (Docker/Rails)

## Useful Links
* [Hyrax docs on debugging Docker](https://github.com/samvera/hyrax/blob/main/CONTAINERS.md#debugging)
* [Debugging Rails App with Docker Compose](https://medium.com/gogox-technology/debugging-rails-app-with-docker-compose-39a3767962f4) by Ravic Poon
* [Docker Error Container is Unhealthy: Troubleshooting](https://bobcares.com/blog/docker-error-container-is-unhealthy/) by Manu Menon
* [How to Do a Clean Restart of a Docker Instance](https://docs.tibco.com/pub/mash-local/4.3.0/doc/html/docker/GUID-BD850566-5B79-4915-987E-430FC38DAAE4.html)
* [How to Debug a Docker Compose Build](https://www.matthewsetter.com/basic-docker-compose-debugging/) by Matthew Setter

## List of Errors and Possible Solutions
* [Turning it off and on again](#turning-it-off-and-on-again)
* [Reset everything](#reset-everything)
* [The path ... is not shared from the host and is not known to Docker](#the-path--is-not-shared-from-the-host-and-is-not-known-to-docker)
* [standard_init_linux.go:219: exec user process caused](#windows-standard_init_linuxgo219-exec-user-process-caused-no-such-file-or-directory)
* [LoadError: cannot load such file](#loaderror-cannot-load-such-file--hydra-head-or-other-filegem)
* [KeyError: key not found: :secret_key_base](#keyerror-key-not-found-secret_key_base)
* [Docker web container exits with message "Switch to inspect mode"](#docker-web-container-exits-with-message-switch-to-inspect-mode)
* [Solr container is unhealthy](#solr-container-is-unhealthy)
* [psql error cannot connect to database](#psql-error-cannot-connect-to-database-in-the-workers-and-web-container)
* [Can't login to app or can't create anything](#i-cant-log-into-the-application-or-i-can-log-in-but-cant-create-any-works-or-collections)

#### Turning it off and on again
* Run `docker-compose down` to remove containers and `docker-compose up -d` to recreate them
* If you see configuration errors, this may be because Docker is reusing volume data from a previous install. To remove volumes and start fresh, run `docker-compose down` and then `docker volume prune`. Then run `docker-compose up -d` again to recreate everything.

#### Reset everything
* If the above still doesn't solve anything, consider backing up the current files to a different location, then deleting the entire folder. Then create a new folder with the same name in the same location. Copy all the files inside the backup folder and paste them into the new folder. Then run `docker-compose build` and `docker-compose up -d` again.

Next two errors from "Running Hyrax Locally" Tutorial by Julie Hardesty:

#### The path ... is not shared from the host and is not known to Docker
* You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing.”
* In Docker Desktop app, go to Settings > Resources > File Sharing - make sure the folder where your code is sitting is available in the directories listed here (build can still work but running might not)

#### (Windows:) standard_init_linux.go:219: exec user process caused: no such file or directory
* To fix it, follow the steps in the top answer for this [StackOverflow post](https://stackoverflow.com/questions/51508150/standard-init-linux-go190-exec-user-process-caused-no-such-file-or-directory) 
(you’ll need to install [Notepad++](https://notepad-plus-plus.org/downloads/), [Visual Studio Code](https://code.visualstudio.com/) 
or other text editor program if you don’t have one already)
* If that doesn’t work, you may need to rerun docker-compose build afterwards or delete your docker containers and recreate them

#### LoadError: cannot load such file – hydra head (or other file/gem)
* The error trace may look something like: 
```
/usr/local/bundle/gems/bootsnap-1.16.0/lib/bootsnap/load_path_cache/core_ext/kernel_require.rb:29:in `require'
17 5.514 /usr/local/bundle/gems/activesupport-5.2.8.1/lib/active_support/dependencies.rb:291:in `block in require'
17 5.514 /usr/local/bundle/gems/activesupport-5.2.8.1/lib/active_support/dependencies.rb:257:in `load_dependency'
17 5.514 /usr/local/bundle/gems/activesupport-5.2.8.1/lib/active_support/dependencies.rb:291:in `require'
17 5.514 /app/samvera/hyrax-webapp/config/initializers/hydra_config.rb:2:in `<main>'
```
* This may happen when running `rake assets:precompile`. An easy solution may just be to skip precompiling assets since 
we may not need or want to do that anyway in production
* Possible solution: add a line to the Dockerfile that updates bundler like so:
```dockerfile
RUN gem update bundler && gem cleanup bundler && bundle -v && \
  bundle install && \
```

#### KeyError: key not found: :secret_key_base
* This usually happens when you don't have a `config/secrets.yml` file
* To fix it, create `config/secrets.yml` and edit it like so:
```yaml
development:
  secret_key_base: something_here
```
* You can create a key with the command `rails secret` in bash (web container), Then replace `something_here` 
 with the output of that command (this is the more secure way to do it). However, it will work with any text.
 
#### Docker web container exits with message "Switch to inspect mode"
* [As noted](./Developing_with_Docker.md#step-4:-start/run-the-application), we don't run the server automatically on `docker-compose up` so our Dockerfile doesn't include a command (CMD) at the end to start the web server so that might be why.
* If you've modified `docker-compose.yml`, ensure that these two lines appear somewhere in the web container's configuration:
```
web:
  stdin_open: true
  tty: true
```
* Then start a bash session in your web container `(docker exec -it vault_web_1 bash`) and try starting the server with `rails s -b 0.0.0.0`.
 
#### Solr container is unhealthy
* This likely means that your zoo1 (zookeeper) container is failing the health check defined on line 35 of `docker-compose.yml`
* In Docker Desktop, click on the zoo1 container to open the log output to see what's going on.
* If you see a configuration error, this may be because Docker is trying to use config data from a volume. To reset all volume data, run `docker-compose down` and `docker volume prune` (you may want to back up data before doing this). Then `docker-compose up -d` to start fresh.
* If that still doesn't solve it, consider [resetting everything](#reset-everything).

#### psql error cannot connect to database in the workers and web container
* The db container may have been [initialized without a user/password](https://github.com/docker-library/postgres/issues/453#issuecomment-393939412). In this case, it may be better to completely recreate the `db` container. Stop and/or delete the `db` container in Docker Desktop and run `docker volume rm vault_db_1`. Then run `docker-compose up -d` again.
* The app may also have the wrong address to the database. Double-check your .env file. The following 5 variables need to be defined because they are used by `config/database.yml`:
```
DATABASE_ADAPTER
DATABASE_NAME
DATABASE_HOST
DATABASE_PASSWORD
```
 
#### I can't log into the application OR I can log in but can't create any works or collections
* This is probably happening because 1) there are no users registered with the application or 2) you aren't 
logged in as an admin user
* We can check if any users have been created using the rails console (type `rails c` and `Enter` to open the rails console).
Then run the command `User.all`. If the result is `[]` (an empty array), that means that there are no users currently exist.
* To fix, you can open the rails console and try to run `Hyrax::TestDataSeeders::UserSeeder.generate_seeds`. This 
command, if it succeeds, it will create an admin user and a basic user (emails and passwords are defined 
[here](https://github.com/samvera/hyrax/blob/main/app/utils/hyrax/test_data_seeders/user_seeder.rb))
* You can also create an admin user in the rails console (`rails c`) (from [this user seeder file for Hyrax](https://github.com/samvera/hyrax/blob/b9c8de807ec3c35cdb4a14edaa1cccb5d0e9d591/app/utils/hyrax/test_data_seeders/user_seeder.rb#L40)):
```ruby
# This comes from the Devise gem. Replace email and password 
# with your own email and password if you like
user = User.find_or_create_by(email: email) do |f|
    created = true
    f.password = password
end
user.roles << "admin"
user.save
```

### Error in docker-compose.yml: services.zoo1.healthcheck.timeout must be a string
* This is happening due to an error in the docker-compose.yml file at lines 36 and 37. Change healthcheck "interval" and "timeout" to:
```ruby
interval: 5s
timeout: 8s
```
