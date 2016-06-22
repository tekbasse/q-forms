<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>
<h2>Q-Forms</h2>
<pre>
The lastest version of the code is available at the site:
 http://github.com/dcpm/q-forms
The development site: http://github.com/tekbasse/q-forms
</pre>
<h3>
introduction
</h3>
<p>
Q-Forms provides procedures for building forms dynamically in OpenACS tcl.
It is an OpenACS service package that allows convenient building and
interpreting of web-based forms via tcl in a web page.
</p><p>
Q-Forms procedures parallel html's form tags with many
automatic defaults that remove the tedious nature of building forms 
via html or an alternate form building context, such as OpenACS form
builder, ad_form or acs-templating.
</p>
<h3>
license
</h3>
<pre>
Copyright (c) 2013 Benjamin Brink
po box 20, Marylhurst, OR 97036-0020 usa
email: tekbasse@yahoo.com
</pre>
<p>
Q-Forms is open source and published under the GNU General Public License, consistent with the OpenACS system: http://www.gnu.org/licenses/gpl.html
</p><p>
A local copy is available at <a href="LICENSE.html">q-forms/www/doc/LICENSE.html</a>
</p><pre>
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
</pre>
<h3>
features
</h3>
<ul><li>
Low learning-curve:<ul><li>Uses tcl context.</li><li>Procedures match tags.</li><li>TCL list friendly.</li></ul>
</li><li>
Built-in API defaults: Takes less keystrokes to build a form than typing html manually.
</li><li>
Can build multiple forms concurently using Tcl file terminology.
</li><li>
No limitations to building dynamic forms with specialized inputs.
</li><li>
Form values are retrieved as a tcl array named by the programmer.
</li><li>
Form values are automatically quoted, a requirement of secure input handling.
</li><li>
Optional, automatic hash generation helps secure form transactions 
and ignores multiple posts caused from mouse double-clicks and browsing page history.
</li><li>
Passing multiple values of same input name can be combined as a list (instead of producing
a form post error typical of ad_form/ad_page_contract).
</li><li>
html can be inserted in any form at any point during the build.
</li><li>
No UI javascript is used. Technologies with limited UI, cpu power, or low QOS connection can use it.
</li><li>
Integrates with acs-templating features.
</li></ul>

