Update titles on folders containing a person presentation
=========================================================

These two scripts sets titles on folders containing a person presentation to the persons realname if found in ldap directory.

 * fix_folder_titles.rb uses screenscraping to search for all persons on a host and generate a ruby script

The generated ruby is a list of calls to the rename_folder() and the current folder title as a comment. Example:

```
# -*- coding: utf-8 -*-
  require 'rename_folder_util'

  rename_folder('https://www-dav.mn.uio.no/ifi/personer/vit/azadeha/index.html','Azadeh Abdolrazaghi') #Abdolrazaghi, Azadeh
  rename_folder('https://www-dav.mn.uio.no/fysikk/personer/vit/erikadl/index.html','Erik Adli') #Adli, Erik
  rename_folder('https://www-dav.mn.uio.no/fysikk/personer/adm/mafdal/index.html','Marianne Afdal') #Afdal, Marianne
```

