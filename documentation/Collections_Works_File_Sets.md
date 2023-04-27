Vault organizes digital objects into 4 different categories:
* **Works** are the main building blocks of a collection and the metadata (such as title, description, contributor) 
for a specific object is attached to a work.
* **Collections** are groups of works. A single work can be a member of one or more collections. 
See the Samvera Features Guide for more about working with collections.
* **File Sets** are the digital objects themselves that can be downloaded by users. One work can have multiple file sets. For example, a work may have one audio file and one PDF transcript. Each file set (PDF and audio) comprises all versions of that file, but all file sets belong to the same work.
* **Admin Sets** are like collections in that they are groups of works, but only adminstrators may access them and their boundaries can be more arbitrary. An admin set also acts like a template for creating works with some pre-determined, default settings for release or visibility. See the Samvera Features Guide page on Admin Sets for more information.

File sets are members of works, and works are members of collections.

![A diagram showing the hierarchy of objects in Hyku/Hyrax. At the top are collections, then works below collections, then file sets below works. Outside of the hierarchy is a box labelled "Admin Set" with the description "Default settings for created Works (such as visibility)"](./images/collections_works_file_sets.png)