========================
Install or Remove `sw`
========================

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
