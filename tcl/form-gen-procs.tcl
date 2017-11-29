ad_library {

    routines for creating, managing customizable forms
    for adapting package applications to site specific requirements
    by adding additional fields aka object attributes.
    @creation-date 24 Nov 2017
    @Copyright (c) 2017 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl.html
    @project home: http://github.com/tekbasse/q-forms
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com
}

#agenda:
# qfo = q-form object

# qfo_prepare form_id form_fields_larr
#      Prepares a lists_array definition of a form

#      Grabs custom definitions in context of tips_ api

#      Grabs/overwrites customs with package defaults
#         to force package specific requirements.
#         Customization adds fields, doesn't change supplied ones.
#         Package defaults need to be defined using simple,
#         largely self-explanatory code
#         What is needed?  field attributes for qf_input or qf_textarea
#           additional fields: data type for validation and view.
#           Attributes could default to ones provided by datatype.
#           datatype refers to qss_tips_data_types.. except that doesn't work
#           for defaults provided by q-forms only. 
#           So, q-forms must have its own qfo datatypes, yet a UI is 
#           needed to dynamically change this, and spreadsheet shouldn't require
#           q-forms.. so, create package qfo that requires spreadsheet and q-forms?
#           qfo shouldn't require spreadsheet. Solution is to have
#           qfo package require q-forms and a q-data-types package, and
#           qfo package = q-tables (was q-tips).
#           spreadsheet requires q-data-types package.
#           q-tables is only required if extended qfo custom form features.
#           default values (set in context of qf_input_as_array)
#      This way, can check if a package_id has a parameter enableFormGenP
#      If enableFormGenP and apm_package_enabled_p spreadsheet
#      Then do integration business logic

# qfo_fields 
#      returns list of default form fields + plus any custom ones

# qfo_array_read (as name/val list pairs)
#      reads data from tips_ database that match form_array's unique_key

#qfo_generate_html4 form_id
# converts prepared list_array to html

#qfo_generate_html5 form_id
# converts prepared list_array to html

#qfo_generate_xml_v001 form_id
# converts prepared list_array to xml (mainly for saas)

#qfo_view_html4 arrayname
#qfo_view_html5 arrayname
