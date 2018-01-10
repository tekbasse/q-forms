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
# qfo_<some_name> refers to a qfo_ paradigm or sub-api
# This permits creating variations of qfo_2g as needed.

ad_proc -private qfo_qtable_label_package_id {
    form_id
} {
    Gets most specific q-tables' table_label, instance_id and table_id in an ordered list. table_label is a reference based on package-key and form_id.
    Returns empty list if none found.
} {
    set return_list [list ]
    set package_id [ad_conn package_id]
    set enable_p [parameter::get -parameter enableQFormGenP \
                      -package_id $package_id \
                      -default "0"
                      -boolean ]
    if { $enable_p } {
        # Is q-tables installed?
        if { [apm_package_enabled_p q-tables] } {
            set package_key [ad_conn package_key]
            set table_label $package_key
            append table_label ":" ${form_id}
            # Cannot use qt_table_def_read, because that paradigm
            # requires instance_id to be defined
            
            # Select the one most specific to this package_id
            set found_p [db_0or1row {
                select id,label,instance_id from qt_table_defs
                where label=:table_label 
                and ( instance_id is null or instance_id=:package_id )
                and trashed_p!='1' order by instance_id asc limit 1} ]
            if { $found_p } {
                set return_list [list $label $instance_id $id]
            }
        }
    }
    return $return_list
}


#ad_proc qfo_form_fields_prepare {
#    {-form_fields_larr_name}
#} {

#}


#      Prepares a lists_array definition of a form

#      Grabs data type definitions in context of q-data-types


#           default values (set in context of qf_input_as_array)




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
    -fields_array:required
    {-field_types_array ""}
    {-inputs_as_array "qfi"}
    {-form_id ""}
    {-doc_type ""}
    {-form_varname "form_m"}
} {
    Inputs essentially declare properties of a form and manages field type validation.
    <br><br>
    <code>fields_array</code> is an <strong>array name</strong>. 
    Indexes are 'name' attributes for form elements. 
    Each indexed value is a list containing attribute/value pairs of form element. 
    <br><br>
    Each form element is expected to have a 'datatype' in the list. 
    'text' datatype is default.
    <br><br>
    Form elements are displayed in order of any attribute 'tabindex' values.
    Order may be overridden by an array index 'element_order' containing an ordered list of array indexes.
    <br><br>
    <code>field_types_array</code> is an <strong>array name</strong>. 
    Indexes are field 'datatype'. 
    Each indexed value is a list containing name/value pairs that match q-data-types or a datatype provided in <code>field_types_array</code>. 
    See <code>qdt_data_types</code> for names used.
    <br><br>
    <code>inputs_as_array</code> is an <strong>array name</strong>. Array values follow convention of qf_get_inputs_as_array
    <br><br>
    <code>form_id</code> should be unique at least within the package in order to reduce name collision implementation.
    <br><br>
    Returns 1 if input is validated. 
    If there are no fields, input is validated by default.
    <br><br>
    Note: Validation may be accomplished external to this proc by outputing a user message such as via <code>util_user_message</code> and redisplaying form instead of processing further.
    
    @see qdt_data_types
    @see util_user_message
    @see qf_get_inputs_as_array
} {
    # Done: Verify negative numbers pass as values in ad_proc that uses
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




    set qtable_enabled_p 0
    set qtable_list [qfo_qtable_label_package_id $form_id]
    if { [llength $qtable_list ] ne 0 } {
        # customize using q-tables paradigm
        set qtable_enabled_p 1

    }
    if { $qtable_enabled_p } {
        

    }

    # 


    return $validated
}
