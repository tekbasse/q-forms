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
# qf_form_prepare form_id form_fields_arr
#      Prepares an lists_array definition of a form
#      Grabs custom definitions
#      Grabs/overwrites customs with package defaults
#         to force package specific requirements
#      This way, can check if a package_id has a parameter enableFormGenP
#      If enableFormGenP and apm_package_enabled_p spreadsheet
#      Then do integration business logic

# qf_form_fields 
#      returns list of default form fields + plus any custom ones

# qf_form_array_read (as name/val list pairs)
#      reads data from tips_ database that match form_array's unique_key

#qf_form_generate_html4 form_id
# converts prepared list_array to html

#qf_form_generate_html5 form_id
# converts prepared list_array to html

#qf_form_generate_xml_v001 form_id
# converts prepared list_array to xml (mainly for saas)

# object?? what other word works instead of 'form' that doesn't conflict with
# existing openacs-isms
#qf_object_generate_html4 arrayname
#qf_object_generate_html5 arrayname
