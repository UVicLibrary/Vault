# Vault - University of Victoria Libraries

This repository contains code for [Vault](https://vault.library.uvic.ca), a Hyku/Hyrax-based application at the University of Victoria (UVic) Libraries. Vault is a digital asset management system for digitized and born-digital materials in UVic Special Collections, Archives, or other UVic or community-based collections.

![A screenshot of the Vault homepage](documentation/images/vault_homepage.jpg)

If you're completely new to Samvera, we recommend reading the [Hyku documentation](https://samvera.atlassian.net/wiki/spaces/hyku/overview?homepageId=715789904)
first, or this [description of the technology stack](https://samvera.github.io/our_technology_stack.html) if you're more
technically-minded. Then read this introductory page on [Collections, Works, and File Sets](./documentation/Collections_Works_File_Sets.md) and explore
using the Vault interface.

In terms of Vault-specific features, see [the wiki](https://github.com/UVicLibrary/Vault/wiki) for documentation on using the interface or the
[documentation folder](./documentation) of this repo for code documentation.

## Running the Code (Local Development)

UVic Libraries uses Docker as its local development environment (but not in production). Download the code, then use git/GitHub Desktop to switch to the `docker_multitenant` branch. Then run `docker-compose build` and `docker-compose up -d` as normal.

Detailed instructions are available on the [Developing with Docker](documentation/Developing_with_Docker.md) page.

## Versions/Dependencies
See the Gemfile for a full listing. The highlights:
* **Ruby 2.6.8**
* **Rails 5.2.4.6**
* **Hyku** - somewhere between versions 2 and 3 (we've mixed and matched features from both)
* **Hyrax 3.0.2**
* **Active Fedora 13.1**
* **Sidekiq 5.x**
