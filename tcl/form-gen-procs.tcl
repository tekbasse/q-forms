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

# qfo = q-form object
# qfo_2g for a declarative form builder without writing code.
# qfo_<some_name> refers to a qfo_ paradigm.
# This permits creating variations of qfo_2g as needed.
ad_proc qfo_qtable_label {
    form_id
} {
    Gets most specific q-tables' table_label and instance_id in an ordered list. table_label is a reference based on package-key and form_id.
    Returns empty string if none found.
} {
    set return_list [list "" ""]
    # Is q-tables installed?
    if { [apm_package_enabled_p q-tables] } {
        set package_id [ad_conn package_id]
        set package_key [ad_conn package_key]
        set table_label $package_key
        append table_label ":" ${form_id}
        # Cannot use qt_table_def_read, because that paradigm
        # requires instance_id to be defined

        set tables_ul [db_list_of_lists {
            select id,label,instance_id from qt_table_defs
            where (( label=:table_label  and instance_id is null ) or
                    ( label=:tabel_label and instance_id=:package_id ))
            and trashed_p!='1'} ]
        if { [llength $tables_ul] > 0 }  {
            # Select the one most specific to this package_id

       ##code



        }
    }
    return $q_tables_defined_p
}


ad_proc qfo_form_fields_prepare {
    form_fields_larr
}
# qfo_prepare form_id form_fields_larr
#      Prepares a lists_array definition of a form

#      Grabs data type definitions in context of q-data-types

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
#             (package remapping is DONE).
#           q-tables is only required if extended qfo custom form features.

#           default values (set in context of qf_input_as_array)
#      This way, can check if a package_id has a parameter enableFormGenP
#      If enableFormGenP and apm_package_enabled_p spreadsheet
#      Then do integration business logic

# qfo_fields form_id
#      returns list of default form fields + plus any custom ones

# qfo_input_as_array ??
# qfo_row_array_read (as name/val list pairs)
#      reads data into tcl space from connection input
#which should be idential to data from 
# tips_ database that was written to table and matching form_array's unique_key
# except that there is no extra trips to db.

#qfo_generate_html4 form_id
# converts prepared list_array to html4

#qfo_generate_html5 form_id
# converts prepared list_array to html5

#qfo_generate_xml_v001 form_id
# converts prepared list_array to xml (mainly for saas)

#qfo_view arrayname returns form definition as text in generated format

ad_proc -public qfo_2g {
    -fields:required
    {-inputs_as_array "qfi"}
    {-form_id ""}
    {-doc_type ""}
    {-field_types_array ""}
    {-form_var_name "form_m"}
} {
    Inputs essentially declare properties of a form and manages field type validation.

    Returns 1 if input is validated. If there are no fields, input is automatically validated.

    Validation may occur outside of this validation by outputing a user message and redisplaying form_var_name instead of processing further.
} {
    # Verify negative numbers pass as values in ad_proc that uses
    # parameters passed starting with dash.. -for_example.
    # PASSED. If a non-decimal number begins with dash, flags warning in log.
    # Since default form_id may begin with dash, a warning is possible.

    # qfi = qf input
    # form_ml = form markup (usually in html starting with FORM tag)
    upvar 1 $inputs_as_array qfi
    upvar 1 $form_var_name form_m
    if { $field_types_array ne "" } {
        upvar 1 $field_types_array field_types_arr
    }



    return $validated
}
