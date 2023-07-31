========================
Install or Remove `sw`
========================

Package Dependencies
--------------------
We currently support *debian* for automatic dependencies
installation. These are the current dependencies for *Debian*:

   .. include:: ../dependencies/debian.dependencies

If you want to build the documentation as it is displayed on our website you
also need this pip package:

   .. include:: ../dependencies/pip.dependencies

.. note::
   Our base support is Ubuntu LTS. i.e., the dependency packages installed in
   your system should be at least as new as those present in Ubuntu LTS.

Install
-------

Manual install
~~~~~~~~~~~~~~
In the sw's directory, type::

    ./install

This command will install `sw` and append the following
lines at the end of your `.bashrc`.::

    # sw
    PATH=$HOME/sworkflow/bin:$PATH # sw

If you use another shell (`ksh`, for example), you will need to manually add
the path to `sw` to `PATH` environment variable.

To check if the installations was ok, open another terminal and type::

    sw help
