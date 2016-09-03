Q-Forms
=======

The lastest version of the code is available at the site:
 http://github.com/dcpm/q-forms

introduction
------------

Q-Forms provides procedures for building forms dynamically in OpenACS.
It is an OpenACS service package that allows convenient building and
interpreting of web-based forms via tcl in a web page.

Q-Forms procedures parallel html's form tags with many automatic 
defaults that remove the tedious nature of building forms 
via html or an alternate form building context, such as OpenACS form
builder, ad_form or acs-templating.

license
-------
Copyright (c) 2013 Benjamin Brink
po box 20, Marylhurst, OR 97036-0020 usa
email: tekbasse@yahoo.com

Q-Forms is open source and published under the GNU General Public License, 
consistent with the OpenACS system: http://www.gnu.org/licenses/gpl.html
A local copy is available at q-forms/www/doc/LICENSE.html

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

features
--------

Low learning-curve. Uses tcl context. Procedures match tags. List friendly.

Built-in API defaults. Takes less keystrokes to build a form than typing manually.

Can build multiple forms concurently using Tcl file terminology.

No limitations to building dynamic forms with specialized inputs.

Form values are retrieved as an array named by the programmer.

Form values are automatically quoted, a requirement of secure input handling.

Optional automatic hash generation helps secure form transactions 
and ignores multiple posts caused from mouse double-clicks and browsing page history.

This extra secure feature also prevents tampering of hidden form values.

Multiple values of same key can be combined as a list (instead of producing
a form post error).

html can be inserted in any form at any point during the build.

No UI javascript is used. Technologies with limited UI or cpu power can use it.

Integrates with acs-templating features.


installation
------------
See file q-forms/INSTALL.TXT for directions on installing.
