A DB2 console with history and autocomplete support, and few other goodies
====================================

DB2 console mode does not support readline and autocomplete, this is a wrapper for the db2 command mode with support for both. It also tries to make using db2 a little bit more tolerable, adding support for psql-like commands and other shortcuts.

Install
-------

* apt-get install [rlwrap][0]
* gem install db2c

Contributing
------------

Once you've made your great commits:

1. [Fork][1] db2c
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create an [Issue][2] with a link to your branch
5. That's it!

Acknowledgement
------------

* Chris Jester-Young ([CKY][4]) found out the problem of using shell metacharacters when executing commands from Ruby.
* The initial script was inspired by [defunkt's repl][3], for a genenral purpose repl/wrapper, this is your friend.

Meta
----

* Code: `git clone git://github.com/on-site/db2c.git`
* Home: <https://github.com/on-site/db2c>
* Bugs: <https://github.com/on-site/db2c/issues>
* Gems: <http://rubygems.org/gems/db2c>

Author
------

Samer Abukhait <samer@on-siteNOSPAM.com>, @s4mer

[0]: http://utopia.knoware.nl/~hlub/rlwrap/
[1]: http://help.github.com/forking/
[2]: https://github.com/on-site/db2c/issues
[3]: https://github.com/defunkt/repl
[4]: https://github.com/cky
