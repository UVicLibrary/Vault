# Local Development with Docker

### Table of Contents
* [Introduction](#introduction)
* [Step 1: Install Docker Desktop](#step-1-install-docker-desktop)
* [Step 2: Download or Clone the GitHub Repository](#step-2-download-or-clone-the-github-repository)
  * [Using the Command Line/Terminal](#using-the-command-lineterminal)
  * [Using GitHub Desktop](#using-github-desktop)
* [Step 3: Build the Docker Images](#step-3-build-the-docker-images)
  * [Troubleshooting](#troubleshooting)
* [Step 4: First Time Setup and Starting/Running the Application](#step-4-first-time-setup-and-startingrunning-the-application)
  * [Multitenancy: Creating Your First Tenant](./Multitenancy.md)
* [Step 5: Changing the Code](#step-5-changing-the-code)

### Introduction

While we (University of Victoria Libraries) don't use Docker in production, 
we do use it for local development. (We run the production version of Vault on premises, i.e. on local server infrastructure and not the cloud). Dev(elopment) instances will run in multitenancy mode by default, but they can be configured to run in single-tenant mode (see lines 104-114 of `docker-compose.yml`). 

We use Docker for our own development environments because the Samvera stack can be very complicated to set up otherwise 
(Solr, Fedora, Postgres, Redis, etc.). However, developing with a Virtual Machine (VM) is also possible, although not tested. 
For guidance on developing without Docker, please refer to the Samvera instructions for [running Hyku without Docker](https://github.com/samvera/hyku#with-out-docker) and/or [running Hyrax using Engine Cart and Solr Fedora wrapper](https://github.com/samvera/hyrax/wiki/Development-setup-using-Engine-Cart-and-Solr---Fedora-wrapper).

A basic knowledge of the Command Line (e.g. commands like `cd` 
or `ls`) would be helpful if you're unfamiliar. There are many tutorials and resources on the web, such as this
[Programming Historian tutorial](https://programminghistorian.org/en/lessons/intro-to-bash).

### Step 1: Install Docker Desktop

1. Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/) for Mac/Windows
2. **Optional but recommended if you're not a command line Git expert:** [GitHub Desktop](https://desktop.github.com/)
3. If using Windows, we also recommend installing [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701) (prettier and more customizable than default Powershell or Cmd). If using a Mac, the Terminal program will suffice.

### Step 2: Download or Clone the GitHub Repository

#### Using the Command Line/Terminal

1. Open the terminal and `cd` into your preferred directory.
2. Run `git clone --branch docker https://github.com/UVicLibrary/Vault.git`

#### Using GitHub Desktop

1. Go to File > Clone Repository > URL
2. Paste the following URL in: https://github.com/UVicLibrary/Vault and select a local directory
    1. **If you're using Docker on Windows, we recommend creating or selecting a directory in the WSL 2 / Linux file system so Docker will run faster. See the [Speeding up Docker on Windows](./Speeding_up_Docker_on_Windows.md) section for more.**
3. Click Clone
4. [Switch](https://docs.github.com/en/desktop/contributing-and-collaborating-using-github-desktop/making-changes-in-a-branch/managing-branches#switching-between-branches) to the `docker_multitenant` branch

### Step 3: Build the Docker Images

1. Open the terminal (bash/command line) on Mac, or in Ubuntu or Powershell on Windows (or open a Powershell/Ubuntu tab in your 
Windows Terminal). We recommend using Ubuntu on Windows for better performance (see [Speeding up Docker on Windows](./Speeding_up_Docker_on_Windows.md)).
2. Navigate to the folder/directory you downloaded Vault into (`cd file/path`)
3. Run `docker-compose build` to build the application. This can take a while depending on your computer's specs. If you get an error message about loading metadata and you are using a VPN, you may need to disconnect from the VPN. 

Once built, here is a non-exhaustive list of services and where they are configured:

| Service Name | Container Name (Docker Desktop/docker-compose.yml) | Associated Variable Name(s) | Configured in | How/Where to Access in Browser |
|---|---|---|---|---|
| Solr | vault_solr_1 / solr | SOLR_URL | .env | localhost:8983 |
| Fedora | vault_fcrepo_1 / fcrepo | FEDORA_URL | .env | localhost, but the exact port number will vary. The easiest way to find it is to click the highlighted button below in Docker Desktop. |
| Postgres | vault_db_1 / db | DATABASE_ADAPTER, DATABASE_NAME, DATABASE_HOST, DATABASE_PASSWORD, DATABASE_USER, DATABASE_TEST_NAME | .env | N/A |
| Sidekiq | vault_workers_1 / workers | N/A | config/initializers/sidekiq.yml | <tenant name>.localhost:3000/sidekiq (You need to creat a tenant and add [one or more lines](https://github.com/UVicLibrary/Vault/blob/main/config/routes.rb#L134) to `config/routes.rb` before you can see this) |
| Web (Rails) Server | vault_web_1 / web | SETTINGS__MULTITENANCY__DEFAULT_HOST, SETTINGS__MULTITENANCY__ADMIN_HOST, SETTINGS__MULTITENANCY__ROOT_HOST | docker-compose.yml | localhost:3000, or <tenant name>.localhost:3000 |

If this step fails, see our [Troubleshooting Docker](./Troubleshooting.md) page. Other helpful links:
* [Hyrax docs on debugging Docker](https://github.com/samvera/hyrax/blob/main/CONTAINERS.md#debugging)
* [Debugging Rails App with Docker Compose](https://medium.com/gogox-technology/debugging-rails-app-with-docker-compose-39a3767962f4)

### Step 4: First Time Setup and Starting/Running the Application

1. Once built, make sure Docker Desktop is running. Then, in the terminal, run `docker-compose up -d`
2. Run `docker exec -it vault_web_1 bash` to start a terminal session in the web container.
3. There are 3 commands we need to run once each before starting the server: 
    ```
    bundle exec rails zookeeper:upload
    rails db:create RAILS_ENV=development
    rails db:schema:load
    rails hyku:superadmin:create
    ```
    1. The first command configuration file to zookeeper (Solr).
    2. The second sets up the database and makes necessary migrations (if this command doesn't work, try `bundle exec rails db:migrate`.
    3. The last command creates a superadmin user account that will let you create new tenant sites. The console should prompt you to create a username and password.
4. To stop the stack, type `exit` and Enter to exit the web container. Then run `docker-compose stop`. 
**Do not run docker-compose down unless you want all your Solr data to be wiped.**
5. To start up everything again, run `docker-compose up -d` as before

See the [Multitenancy instructions page](./Multitenancy.md) to learn how to create your first tenant, or see [instructions for setting up the test environment](./Multitenancy.md#set-up-testing-rspec).

**Note**
Unlike Hyrax or Hyku, we don't start the server automatically when starting up Docker. This gives us more 
flexibility in how and when we pause execution and allows us to stop and restart the web server without stopping and 
restarting all Docker containers.

### Step 5: Changing the Code

Any local changes you make in `/home/app/webapp` (in the web container) are mapped to your local folder and will be persisted. You 
can pause execution using [byebug](https://guides.rubyonrails.org/v5.1/debugging_rails_applications.html#debugging-with-the-byebug-gem) 
or [web console]([how to use web console with Docker](https://www.youtube.com/watch?v=XdWnDHjtNqM&t=197s)). 
In most cases, if you change the code, you'll need to refresh the page (or resubmit a form, etc.) to see it take effect.

Some types of changes (such as those to `config/routes`) will require restarting the web server. To do this, 
press `Cntrl + c` (`Command + c` on a Mac) to stop the server. Then press the up arrow to bring up the command that was 
run last, which should be the command you used to start the server (`rails s -b 0.0.0.0`). Then hit `Enter` to start 
the server again.

Gems are installed in `/usr/local/bundle/gems/gem_name`. To see where a specific gem was installed, run `bundle info gem_name`. 
Using Hyrax as an example:
```
bundle info hyrax

# Sample output:

 * hyrax (3.0.2)
 Summary: Hyrax is a front-end based on the robust Samvera framework ...
        Homepage: http://github.com/samvera/hyrax
        Path: /usr/local/bundle/gems/hyrax-3.0.2
```

To delve further into a file from a gem, you can copy a file from a gem into your local application directory (e.g. 
with `cp`) and then modify it or use byebug to investigate variables, etc. For example, if you want to modify the file 
`/usr/local/bundle/gems/hyrax-3.0.2/app/views/hyrax/homepage/index.html.erb`, you would copy it to 
`/data/app/views/hyrax/homepage/index.html.erb` and edit the copied file, which will override the corresponding file
in the gem folder. To start over fresh, just delete `/data/app/views/hyrax/homepage/index.html.erb` and the application 
will fall back to the Hyrax gem.

Note that Samvera provides many points for override and customization that reduce the need to copy/paste files. In some cases you can create a new class/object that inherits from a Hyrax class, then swap out the Hyrax 
class/object with your own. Taking `app/indexers/hyrax/collection_indexer.rb` as [an example](https://github.com/samvera/hyrax/blob/main/app/indexers/hyrax/collection_indexer.rb):

```ruby
# frozen_string_literal: true
module Hyrax
  class CollectionIndexer < Hydra::PCDM::CollectionIndexer
    include Hyrax::IndexesThumbnails

    STORED_LONG = ActiveFedora::Indexing::Descriptor.new(:long, :stored)

    self.thumbnail_path_service = Hyrax::CollectionThumbnailPathService
```

We could create a custom thumbnail path service like so:

```ruby
class CustomCollectionThumbnailPathService < Hyrax::CollectionThumbnailPathService
  class << self
      # @param [#id] object - to get the thumbnail for
      # @return [String] a path to the thumbnail
    def call(object)
      # This is the main method that we want to override so our custom code goes here...
    end
  end
end
```

And then swap out Hyrax's service with our own back in the collection indexer:

```ruby
    self.thumbnail_path_service = CustomCollectionThumbnailPathService
```

Jeremy Friesen's blog post goes into more detail on [responsible and sustainable code overrides](https://takeonrules.com/2023/03/26/responsible-and-sustainable-overrides-in-ruby-and-samvera-in-general/). 
The documentation on [Samvera design patterns](https://samvera.github.io/patterns-overview.html) may also be helpful.

Next Page: [Speeding up Docker on Windows >>](./Speeding_up_Docker_on_Windows.md)