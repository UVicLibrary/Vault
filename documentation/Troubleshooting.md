# Troubleshooting Docker/Rails Setup

## Useful Links
* [Hyrax docs on debugging Docker](https://github.com/samvera/hyrax/blob/main/CONTAINERS.md#debugging)
* [Debugging Rails App with Docker Compose](https://medium.com/gogox-technology/debugging-rails-app-with-docker-compose-39a3767962f4)

## Error Messages and Possible Solutions

Two errors from "Running Hyrax Locally" Tutorial by Julie Hardesty:

#### The path /Documents/hyrax is not shared from the host and is not known to Docker
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
  bundle install --jobs "$(nproc)" && \
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

