# Local Development with Docker

### Introduction

While we (University of Victoria Libraries) don't use Docker in production, 
we do use it for local development. Also, our docker image is set to single-tenant mode by default 
(since there's currently no active development on other tenants), even though we run multitenant Hyku
in production. Vault is run on premises (i.e. on local server infrastructure and not the cloud).

We use Docker for our own development environments because the Samvera stack can be very complicated to set up 
(Solr, Fedora, Postgres, Redis, etc.). However, developing with a Virtual Machine (VM) is also possible but not tested. 
For guidance on this topic, please refer to the Samvera instructions for [running Hyku without Docker](https://github.com/samvera/hyku#with-out-docker) 
or [running Hyrax using Engine Cart and Solr Fedora wrapper](https://github.com/samvera/hyrax/wiki/Development-setup-using-Engine-Cart-and-Solr---Fedora-wrapper).

A basic knowledge of the Command Line (e.g. commands like `cd` 
or `ls`) would be helpful if you're unfamiliar. There are many tutorials and resources on the web, such as this
[Programming Historian tutorial](https://programminghistorian.org/en/lessons/intro-to-bash).

### Step 1: Installation

1. Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/) for Mac/Windows
2. **Optional but recommended if you're not a command line Git expert:** [GitHub Desktop](https://desktop.github.com/)
3. If using Windows, we also recommend installing [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701) (prettier and more customizable than Powershell or Cmd)

### Step 2: Download or Clone the GitHub Repository

#### Using the Command Line/Terminal

1. Open the terminal and `cd` into your preferred directory.
2. Run `git clone --branch docker https://github.com/UVicLibrary/Vault.git`

#### Using GitHub Desktop

1. Go to File > Clone Repository > URL
2. Paste the following URL in: https://github.com/UVicLibrary/Vault (And change the local directory/folder if desired)
3. Click Clone
4. [Switch](https://docs.github.com/en/desktop/contributing-and-collaborating-using-github-desktop/making-changes-in-a-branch/managing-branches#switching-between-branches) to the docker branch

### Step 3: Build the Docker Image

1. Open the terminal (bash/command line). If you're on Windows, open Powershell (or open a Powershell tab in your 
Windows Terminal).
2. Navigate to the folder/directory you downloaded Vault into (`cd file/path`)
3. Run `docker-compose build` to build the application

#### Troubleshooting

This step may cause trouble. See our [Troubleshooting Docker](./Troubleshooting_Docker.md) page. Other helpful links:
* [Hyrax docs on debugging Docker](https://github.com/samvera/hyrax/blob/main/CONTAINERS.md#debugging)
* [Debugging Rails App with Docker Compose](https://medium.com/gogox-technology/debugging-rails-app-with-docker-compose-39a3767962f4)

### Step 4: Start/Run the Application 

1. Once built, make sure Docker Desktop is running. Then, in the terminal, run `docker-compose up -d web`
2. Run `docker exec -it vault_web_1 bash` to start a terminal session in the web container. 
3. Run `rails s -b 0.0.0.0` to start the server in development mode.
4. In your browser, visit `vault.localhost:3000` to see the app. Solr is running at localhost:8983.
5. To stop Docker, type `exit` and Enter to exit the web container. Then run `docker-compose stop`. 
**Do not run docker-compose down unless you want all your Solr data to be wiped.**
5. To start up everything again, run `docker-compose up -d web` as before

**Note**
Unlike Hyrax or Hyku, we don't start the server automatically when starting up Docker. This gives us more 
flexibility in how and when we pause execution and allows us to stop and restart the web server without stopping and 
restarting all Docker containers.

### Step 5: Changing the Code

Any local changes you make in `/data` (in the web container) are mapped to your local folder and will be persisted. You 
can pause execution using [byebug](https://guides.rubyonrails.org/v5.1/debugging_rails_applications.html#debugging-with-the-byebug-gem) 
or [web console](https://www.youtube.com/watch?v=XdWnDHjtNqM) ([instructions for using web console with Docker](https://www.youtube.com/watch?v=XdWnDHjtNqM&t=197s)). 
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

Note that Samvera provides many points for override and customization. In some cases you can create a new class/object that inherits from a Hyrax class, then swap out the Hyrax 
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
