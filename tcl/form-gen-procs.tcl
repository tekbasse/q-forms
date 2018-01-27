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

namespace eval ::qfo {}

ad_proc -private ::qfo::qtable_label_package_id {
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
    {-duplicate_key_check "0"}
    {-multiple_key_as_list "0"}
    {-hash_check "0"}
    {-post_only "0"}
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
    Indexes are a field 'datatype' as pre-defined in 
    <code>::qdt::data_types</code> or a new datatype.
    Each indexed value is a list containing name/value pairs 
    that match q-data-types' fields.
    See <code>::qdt::data_types</code> for names used.
    Default datatypes are those provided in ::qdt::data_types.
    <br><br>
    <code>inputs_as_array</code> is an <strong>array name</strong>. 
    Array values follow convention of qf_get_inputs_as_array
    <br><br>
    <code>form_id</code> should be unique at least within 
    the package in order to reduce name collision implementation. 
    For customization, a form_id is prefixed with the package_key 
    to create the table name linked to the form. 
    See <code>qfo::qtable_label_package_id</code>
    <br><br>
    <code>doc_type</code> is the XML DOCTYPE used to generate a form. 
    Examples: html4, html5, xhtml and xml. 
    Default uses a previously defined doc(type) 
    if it exists in the namespace called by this proc. 
    Otherwise the default is the one supplied by q-forms qf_doctype.
    <br><br>
    <code>form_varname</code> is the variable name used to assign 
    the generated form to. 
    The generated form is a text value containing markup language tags.
    <br><br>
    Returns 1 if input is validated. 
    If there are no fields, input is validated by default.
    <br><br>
    Note: Validation may be accomplished external to this proc 
    by outputing a user message such as via <code>util_user_message</code> 
    and redisplaying form instead of processing further.
    <br><br>
    <code>duplicate_key_check</code>,<br>
    <code>multiple_key_as_list</code>,<br>
    <code>hash_check</code>, and <br>
    <code>post_only</code> see <code>qf_get_inputs_as_array</code>.
    <br><br>
    @see qdt::data_types
    @see util_user_message
    @see qf_get_inputs_as_array
    @see qfo::qtable_label_package_id
} {
    # Done: Verify negative numbers pass as values in ad_proc that uses
    # parameters passed starting with dash.. -for_example.
    # PASSED. If a non-decimal number begins with dash, flags warning in log.
    # Since default form_id may begin with dash, a warning is possible.

    # qfi = qf input
    # form_ml = form markup (usually in html starting with FORM tag)
    upvar 1 $fields_array fields_arr
    upvar 1 $inputs_as_array qfi_arr
    upvar 1 $form_var_name form_m
    upvar 1 doc doc
    if { $field_types_array ne "" } {
        upvar 1 $field_types_array field_types_arr
    }

  


    submitted_p [qf_get_inputs_as_array qfi_arr \
                     duplicate_key_check $duplicate_key_check \
                     multiple_key_as_list $multiple_key_as_list \
                     hash_check $hash_check \
                     post_only $post_only ]


    # Add the customization code
    # where a q-tables table of same name overrides form definition
    # per form element.
    # That is, any element defined in a q-table overrides existing
    # form element with all existing attributes.
    # This way, customization may remove certain attributes.
    set qtable_enabled_p 0
    set qtable_list [qfo::qtable_label_package_id $form_id]
    if { [llength $qtable_list ] ne 0 } {
        # customize using q-tables paradigm
        set qtable_enabled_p 1

    }

    ::qdt::data_types -array_name qdt_types_arr
    # qdt_types_arr(qdt_data_types.label) /ordered list of parameters/

    if { $qtable_enabled_p } {
        # Apply customizations from table defined in q-tables
        # That is, grab new field definitions

        set qtable_id [lindex $qtable_list 2]
        set instance_id [lindex $qtable_list 1]

        qt_field_defs_maps_set $qtable_id \
            -field_type_of_label_array_name qt_fields_arr
        # Each qt_fields_arr(index) contains an ordered list:
        #
        # field_id label name def_val tdt_type field_type
        #
        # These allow dynamic mapping of fields to different data_types.
        # New data_types are defined in q-data-types like 
        # defaults, only with custom labels likely to not collide
        # with evolving q-data-types defaults.
        # That is:
        # Field definitions may point to different qdt_datatypes,
        # but cannot define new qdt_datatypes.

        # Superimpose dynamic fields over default
        # Remaps overwrite all associated attributes from fields_arr
        # which means, datatype assignments are also handled.
        set qt_field_names_list [array names qt_fields_arr]
        foreach label qt_fields_arr {
            set f_list $qt_fields_arr(${label})
            set datatype [lindex $f_list 4]
            set default [lindex $f_list 3]
            set label_nvl [list name ${label} datatype $datatype]
            if { "value" not in $f_list } {
                lappend laben_nvl value $default
            }
            set fields_arr(${label}) $label_nvl
        }

    }

    set qfi_fields_list [array names fields_arr]    
    # Create a field attributes array
    # fatts = field attributes
    # fatts_arr(label,qdt_data_types.fieldname)
    foreach f $qfi_fields_list {
        foreach {attr val} $fields_arr(${f}) {
            set fatts_arr(${f},${attr}) $val
            if { $attr eq "datatype" } {
                lappend fields_w_datatype_arr(${val}) $f
            }
        }
    }
    # Now that all the fields are known,
    set datatypes_used_list [array names datatypes_arr]

##code

    # Put datatypes used in datatypes_arr where value is list of
    # fields using it.
    # Blend the field types according to significance:
    # qtables field types declarations may point to different ::qdt::data_types
    # fields_arr overrides ::qdt::data_types
    # ::qdt::data_types defaults in qdt_types_arr

    # Collect only the field_types that are used, because
    # each set of datatypes could grow in number, slowing performance
    # as system grows

    set qdt_datatypes_arr_list [array names qdt_types_arr]
    # field_types_arr might not exist yet. Following returns empty list then.
    set field_types_names_list [array names field_types_arr]
    foreach f in $datatypes_used_list {
        if { $f in $field_types_names_list } {
            set datatypes_arr(${f}) $field_types_arr(${f})
        } elseif { $f in $qdt_datatypes_arr_list } {
            set datatypes_arr(${f}) $qdt_types_arr
        }
    }

    


    # Handle custom fields by writing directly to field_types_arr
    set custom_fields_list [array names field_types_arr]
    foreach cfl $custom_fields_list {
        array unset orig_field_types_arr "${cfl},"
    }

    # if field_types_arr is modified, it is settled by this point.

    
    set validated_p 0
    if { $submitted_p } {
        # validate inputs
        foreach f $qfi_fields_list {
            set f_value $qfi_arr(${f})
            switch -- $fatts_arr(${f},
            ##code  

        }
    }

    if { $validated_p } {
        set form_m ""
        if { $qtable_enabled_p } {
            ##code
            # save a new row in customized q-tables table

        }
    } else {
        # generate form
        ##code
        set doctype [qf_doctype $doc_type]
        set form_id [qf_form form_id $form_id]

        qf_close $form_id
        set form_m [qf_read $form_id]
        
    }
    
    return $validated_p
}
