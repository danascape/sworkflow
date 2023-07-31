==========================
  How to setup sworkflow
==========================

.. _setup-tutorial:

.. contents::
   :depth: 1
   :local:
   :backlinks: none

.. highlight:: console

Downloading kw
--------------
First of all, let's download **sw**::

  git clone https://github.com/sworkflow/sworkflow.git

Installing kw
-------------
First, ``cd`` into the repository you cloned::

  cd sworkflow

Then install **sw**::

  ./setup.sh -i

After installing **sw**, you should be able to call ``sw`` directly from the
command line. For example, to display sw's help message::

  sw help

After installing, you should check that everything is working as expected. Try
running::

  sw version
