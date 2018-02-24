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
                      -default "0" \
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
    {-fields_ordered_list ""}
    {-field_types_lists ""}
    {-inputs_as_array "qfi"}
    {-form_submitted_p ""}
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
    'text' datatype is default. For input tags, a 'value' element represents a default value for the form element.
    <br><br>
    Form elements are displayed in order of any attribute 'tabindex' values.
    Order may be overridden by supplying <code>-fields_ordered_list</code>
    with an ordered list of indexes from <code>fields_array</code>.
    Indexes omitted from list appear after ordered ones.
    Any element that is not an index in fields_array is ignored with warning.
    <br><br>
    <code>field_types_lists</code> is a list of lists 
    as defined by ::qdt::data_types parameter 
    <code>-local_data_types_lists</code>.
    See <code>::qdt::data_types</code> for usage.
    <br><br>
    <code>inputs_as_array</code> is an <strong>array name</strong>. 
    Array values follow convention of <code>qf_get_inputs_as_array</code>.
    If passing the array, and <code>hash_check</code> is '1', be sure
    to pass <code>form_submitted_p</code> as well, where form_submitted_p is
    value returned by the proc <code>qf_get_inputs_as_array</code>
    Duplicate invoking of qf_get_inputs_as_array results in
    ignoring of input after first invocation.
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
    Any field attribute, default value, tabindex, or datatype assigned via q-tables to the form takes precedence.
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

    # Blend the field types according to significance:
    # qtables field types declarations may point to different ::qdt::data_types
    # fields_arr overrides ::qdt::data_types
    # ::qdt::data_types defaults in qdt_types_arr
    # This is largely done via feature of called procs.

    # qfi = qf input
    # form_ml = form markup (usually in html starting with FORM tag)
    set error_p 0
    upvar 1 $fields_array fields_arr
    upvar 1 $inputs_as_array qfi_arr
    upvar 1 $form_varname form_m
    # To obtain doctype, if modified:
    upvar 1 doc doc
    
    
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
        lassign $qtable_list qtable_label instance_id qtable_id

    }

    ::qdt::data_types -array_name qdt_types_arr \
        -local_data_types_lists $field_types_lists

    if { $qtable_enabled_p } {
        # Apply customizations from table defined in q-tables

        # Add custom datatypes
        qt_tdt_data_types_to_qdt qdt_types_arr qdt_types_arr

        # Grab new field definitions

       # set qtable_id /lindex $qtable_list 2/
       # set instance_id /lindex $qtable_list 1/

        qt_field_defs_maps_set $qtable_id \
            -field_type_of_label_array_name qt_fields_larr
        # Each qt_fields_larr(index) contains an ordered list:
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

        # Superimpose dynamic fields over default ones.
        # Remaps overwrite all associated attributes from fields_arr
        # which means, datatype assignments are also handled.
        set qt_field_names_list [array names qt_fields_larr]
        foreach n qt_field_names_list {
            set f_list $qt_fields_larr(${n})
            set datatype [lindex $f_list 4]
            set default [lindex $f_list 3]
            set label_nvl [list name ${n} datatype $datatype]
            # Every custom case needs 
            if { "value" not in $f_list } {
                lappend label_nvl value $default
            }

            # Apply customizations to fields_arr
            set fields_arr(${label}) $label_nvl
            # Build this array here that gets used later.
            set datatype_of_arr(${label}) $datatype
        }
 

    }

    set qfi_fields_list [array names fields_arr]    
    # Create a field attributes array
    # fatts = field attributes
    # fatts_arr(label,qdt::data_types.fieldname)
    # qd::data_types fieldnames:
    #    label 
    #    tcl_type 
    #    max_length 
    #    form_tag_type 
    #    form_tag_attrs 
    #    empty_allowed_p 
    #    input_hint 
    #    text_format_proc 
    #    tcl_format_str 
    #    tcl_clock_format_str 
    #    valida_proc 
    #    filter_proc 
    #    default_proc 
    #    css_span 
    #    css_div 
    #    html_style 
    #    abbrev_proc 
    #    css_abbrev 
    #    xml_format
    foreach f $qfi_fields_list {
        foreach {attr val} $fields_arr(${f}) {
            set fatts_arr(${f},${attr}) $val
            if { $attr eq "datatype" } {
                # Put datatypes in an array where value is list of
                # fields using it.
                lappend fields_w_datatypes_used_arr(${val}) $f
            }
        }
    }
    # All the fields and datatypes are known.
    # Proceed with form building and UI stuff


    # Collect only the field_types that are used, because
    # each set of datatypes could grow in number, slowing performance
    # as system grows in complexity etc.
    set datatypes_used_list [array names fields_w_datatypes_used_arr]

    # Verify that used data types exist

    set data_type_existing_list [list]
    foreach n [array names qdt_types_arr "*,label"] {
        lappend data_type_existing_list [string range $n 0 end-6]
    }

    foreach f $datatypes_used_list {
        if { $f ni $data_type_existing_list } {
            ns_log Error "qfo_2g: datatype '${f}' not found."
            set error_p 1
        }
    }
    # field types are settled by this point

    if { $form_submitted_p eq "" } {
        set form_submitted_p [qf_get_inputs_as_array qfi_arr \
                                  duplicate_key_check $duplicate_key_check \
                                  multiple_key_as_list $multiple_key_as_list \
                                  hash_check $hash_check \
                                  post_only $post_only ]
    }
    
    # Make sure every qfi_arr(x) exists for each field
    # Fastest to just collect the most fine grained defaults of each field
    # into an array and then overwrite the array with qfi_arr
    # Except, we don't want any extraneous input inserted unexpectedly in code.

    ##code In a new proc, qfo_3g, 
    # maybe allow dynamically generated fields to allow
    # this following exception:
    # Except, we don't want a filter process
    #   to lose dynamically generated fields, such as used in
    #   forms in spreadsheet apps.
    # So, don't optimize with: array set qfv_arr /array get qfi_arr/
    # Yet, provide a mechanism to allow it via a glob like so:
    #  array set qfv_arr /array get qfi_arr "{glob1}"
    #  array set qfv_arr /array get qfi_arr "glob2"
    # 
    # For now, dynamically generated fields need to be detected and filtered
    # by calling qf_get_inputs_as_array *before* qfo_2g

    # qfv = field value
    foreach f $qfi_fields_list {
        ##code This assumes and INPUT element, single value style for now.
        ## Other form elements may have different defaults
        ## that require more complex values, such as checkboxes
        ## Make sure they work here as expected ie:
        ## Be consistent with qf_* api in passing field values

        # Overwrite defaults with any inputs
        if { [info exists qfi_arr(${f})] } {
            set qfv_arr(${f}) $qfi_arr(${f})
            else { [info exists fatts_arr(${f},value) ] } {
                # This value already sets default as that from
                # datatype, if one is not supplied:
                set qfv_arr(${f}) $fatts_arr(${f},value)
            }
        }
    } 

    # Don't use qfi_arr anymore, as it may contain extraneous input
    # Use qfv_arr
    array unset qfi_arr
    
    set validated_p 0
    set invalid_field_val_list [list ]
    set row_list [list ]
    if { $submitted_p } {
        # validate inputs
        
        foreach f $qfi_fields_list {
            set f_value $qfv_arr(${f})
            # Creating row_list here saves re-parsing later, outside of loop
            lappend row_list $f $f_value
            set valida_proc $fatts_arr(${f},valida_proc)
            set valid_p 0
            switch -- $valida_proc {
                qf_is_decimal {}
                qf_is_integer {}
                hf_are_safe_and_visibe_characters_q {}
                hf_are_safe_and_printable_characters_q {}
                util_url_valid_p {}
                qf_email_valid_q {}
                qf_clock_scan {}
                qf_is_decimal {}
                ad_var_type_check_safefilename_p {}
                default {
                    if { $qtable_enabled_p } {
                        # Check for custom cases
                        if {[catch { set default_val [parameter::get_from_package_key -package_key q-tables -parameter AllowedValidationProcs -default "" ] } ] } {
                            # more than one q-tables exist
                            # Maybe change this to find one in a subsite.
                            # something like qc_set_instance_id from q-control
                            set default_val ""
                        }
                        set custom_procs [parameter::get \
                                              -package_id $instance_id \
                                              -parameter AllowedValidationProcs \
                                              -default $default_val]
                        set allowed_p 0
                        foreach p $custom_procs {
                            if { [string match $p $valida_proc] } {
                                set allowed_p 1
                            }
                        }
                        if { !$allowed_p } {
                            ns_log Warning "qfo_g2: Broken UI. \
 Unknown validation proc '$fatts_arr(${f},valida_proc)' \
 for datatype '$fatts_arr(${f},label)"
                            lappend invalid_field_val_list $f
                        } else {
                            ns_log Notice "qfo_g2: processing safe_eval '${valida_proc}'"
                            set valid_p [safe_eval [list $valida_proc ${f_value}]]
                        }
                    }
                }
            }
            set all_valid_p [expr { $all_valid_p && $valid_p } ]
            # keep track of each invalid field.
            set qfv_valid_arr(${f}) $valid_p
        }
        set validated_p $all_valid_p
    }

    if { $validated_p } {
       
        if { $qtable_enabled_p } {
            # save a new row in customized q-tables table
            qt_row_create $qtable_id $row_list
        }
    } else {
        # generate form
        set form_m ""

        # doc array is used here.
        set doctype [qf_doctype $doc_type]
        set form_id [qf_form form_id $form_id]

        ##code
        # blend tabindex attributes, use to order html tags:
        # input, select, textarea. 1 is first.
        # fields_ordered_list overrides original fatts,
        # dynamic fatts overrides both.
        # use a tabindex_arr(${f}) to track and blend??? and
        # then order into a list?
        foreach f $qfi_fields_list {


        }

        qf_close $form_id
        set form_m [qf_read $form_id]
        
    }
    
    return $validated_p
}
