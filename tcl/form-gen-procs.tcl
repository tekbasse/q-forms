ad_library {

    routines for creating, managing customizable forms
    for adapting package applications to site specific requirements
    by adding additional fields aka object attributes.
    @creation-date 24 Nov 2017
    @Copyright (c) 2017 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl.html
    @project home: http://github.com/tekbasse/q-forms
    @email: tekbasse@yahoo.com
}

# qfo = q-form object
# qfo_2g for a declarative form builder without writing code.
# qfo_<some_name> refers to a qfo_ paradigm or sub-api
# This permits creating variations of qfo_2g as needed.

namespace eval ::qfo {
    # constants used in this space
    set alphabet_c "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
}

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


ad_proc -private ::qfo::larr_replace {
    -array_name
    -index
    -list_index
    -new_value
} {
    Replaces the value in a list of an array_name that is indexed by 'index'.
    Returns 1.
    This proc essentially breaks up a long line in to many, more legible ones.
} { 
    upvar 1 $array_name a_larr
    set i $list_index
#    ns_log Notice "::qfo::larr_replace.69 ${array_name}(${index}) '$a_larr(${index})'"
    set a_larr(${index}) [lreplace $a_larr(${index}) $i $i $new_value]
#    ns_log Notice "::qfo::larr_replace.71 ${array_name}(${index}) '$a_larr(${index})'"
    return 1
}

ad_proc -private ::qfo::lol_remake {
    -attributes_name_array_name
    -attributes_value_array_name
    -is_multiple_p
    -qfv_array_name
} {
    <code>attributes_name_array_name</code> and
    <code>attributes_value_array_name</code> refer to the name/value pairs
    of a list of lists for <code>qf_choice</code> or <code>qf_choices</code>,
    where the name/value pairs have been split into two arrays with a lowercase
    name as common index for both. See code implementation for example.
    <br><br>
    qfv_arr is the array containing form input such as from 
    <code>qf_get_inputs_as_array</code>
    <br><br>
    Returns updated values in a name/value paired list of lists
    based on existence of input from qfv_array_name.
    
    @see qf_get_inputs_as_array for expected qfv_array_name format.
} { 
    upvar 1 $attributes_name_array_name fan_arr
    upvar 1 $attributes_value_array_name fav_arr
    upvar 1 $qfv_array_name qfv_arr
    set selected_c "selected"
    set checkbox_c "checkbox"

    # fan_arr/fav_arr is a normalized array pair representing choicem_lol
    set new_qf_choices_lol [list]

    # The value's value is a list of name/value pair lists.
    set new_val_lol [list ]


    # get name from checkbox/select multiple attributes,

    set att_name_exists_p [info exists fav_arr(name) ]

    set type_checkbox_p 0
    if { [info exists fav_arr(type) ] } {
        if { [string match -nocase $checkbox_c $fav_arr(type) ] } {
            set type_checkbox_p 1
        }
    }
    
#    ns_log Notice "qfo::lol_remake.137 is_multiple_p '${is_multiple_p}' att_name_exists_p '${att_name_exists_p}' array get fav_arr '[array get fav_arr]'"

    # normalize form input names
    foreach {n v} [array get qfv_arr] {
        set nlc [string tolower $n]
        set qfv_v_arr(${nlc}) $v
        #set qfv_n_arr(${nlc}) $n
    }
    


    if { $is_multiple_p } {

        # this is a checkbox or select multiple tag configuration.

        # Not every name exists in qfv_arr

        # If name does not exist, 
        # use default value.. and
        # if there is a 'selected' attribute, set it to '0'

        # val = value, as in attribute 'value'
        foreach row_nvl $fav_arr(value) {
            # index may be upper or lower case
            foreach {n v} $row_nvl {
                set nlc [string tolower $n]
                set row_v_arr(${nlc}) $v
                set row_n_arr(${nlc}) $n
            }

            # Use attribute 'value' as it is consistent for 
            # checkbox and select multiple cases.
            # 'name' is only required for checkbox input attributes.

            # Does the input case exist? Or maybe this is a separator
            if { [info exists row_v_arr(value) ] } {

                if { [info exists row_v_arr(name) ] \
                         && $type_checkbox_p } {
                    #  input type checkbox
                    set name_n $row_v_arr(name)
                } elseif { $att_name_exists_p } {
                    #  input type select multiple
                    set name_n $fav_arr(name)
                }
#                ns_log Notice "qfo::lol_remake.174 name_n '${name_n}'"
                # Is qvf_arr(name) set to the value of this choice?
                set selected_p 0
                if { [info exists qfv_v_arr(${name_n}) ] } {
                    # unqoute qfv_arr first
                    set input_unquoted [qf_unquote $qfv_v_arr(${name_n}) ]
                    # Instead of checking only if input matches original
                    # check also if original is *in* input, because
                    # input may be a list of multiple inputs of same name.
#                    ns_log Notice "qfo::lol_remake.181 input_unquoted '${input_unquoted}' row_v_arr(value) '$row_v_arr(value)'"
                    if { $input_unquoted eq $row_v_arr(value) \
                             || [lsearch -exact $input_unquoted $row_v_arr(value) ] > -1 } {
                        set selected_p 1
                    }
                }
                # Is 'selected' an attribute in original declaration?
                # Either way, set according to new state
                set row_v_arr(selected) $selected_p
                set row_n_arr(selected) $selected_c

                set new_row_nvl [list ]
                foreach nlc [array names row_v_arr] {
                    lappend new_row_nvl $row_n_arr(${nlc}) $row_v_arr(${nlc})
                }
                #ns_log Notice "qfo::lol_remake 191. \
# new_row_nvl '${new_row_nvl}'"
            } else {
                #ns_log Notice "qfo::lol_remake 192. \
# new_row_nvl '${new_row_nvl}'"
                # selection must be a separator or the like.
                set new_row_nvl $row_nvl
            }
            unset row_v_arr
            unset row_n_arr

            lappend new_val_lol $new_row_nvl
        }

    } else {
        # Name is a part of tag attributes,
        # so there is only one name to check.

        # index may be upper or lower case
        if { $att_name_exists_p } {

            set selected_count 0
            
            foreach row_nvl $fav_arr(value) {
                foreach {n v} $row_nvl {
                    set nlc [string tolower $n]
                    set row_v_arr(${nlc}) $v
                    set row_n_arr(${nlc}) $n
                }
                # index may be upper or lower case

                if { [info exists row_v_arr(value) ] } {
                    # Does the input case exist?
                    set selected_p 0
                    if { [info exists qfv_v_arr($fav_arr(name)) ] } {
                        # unqoute qfv_arr first
                        set input_unquoted [qf_unquote $qfv_v_arr($fav_arr(name)) ]
                        # Instead of checking only if input matches original
                        # check also if original is *in* input, because
                        # input may be a list of multiple inputs of same name
                        # intentional or not.
                        #ns_log Notice "qfo::lol_remake.237 input_unquoted '${input_unquoted}' row_v_arr(value) '$row_v_arr(value)'"
                        if { $input_unquoted eq $row_v_arr(value) \
                                 || [lsearch -exact $input_unquoted $row_v_arr(value) ] > -1 } {
                            incr selected_count
                            if { $selected_count < 2 } {
                                set selected_p 1
                            } else {
                                ns_log Warning "qfo::lol_remake.244: \
 Unexpected: 'selected' has multiple selected cases. \
 items for form element '$fav_arr(value)', \
 specifically item '${row_nvl}'. Unselected."
                            }
                        } 
                    }
                    # Is 'selected' an attribute in original declaration?
                    # Either way, set to new status
                    set row_v_arr(selected) $selected_p
                    set row_n_arr(selected) $selected_c

                    set new_row_nvl [list ]
                    foreach nlc [array names row_v_arr] {
                        lappend new_row_nvl $row_n_arr(${nlc}) $row_v_arr(${nlc})
                    }
                    
                } else {
                    # selection must be a separator or the like.
                    set new_row_nvl $row_nvl
                }
                unset row_v_arr
                unset row_n_arr
                lappend new_val_lol $new_row_nvl
            }
        } else {
            ns_log Warning "::qfo::lol_remake.261. Name attribute not found. \
 array get fan_arr '[array get fan_arr]' array get fav_arr '[array get fav_arr]'"
        }
    }

    set fav_arr(value) $new_val_lol
    # rebuild original lol
    foreach nlc [array names fav_arr] {
        lappend new_qf_choices_lol $fan_arr(${nlc}) $fav_arr(${nlc})
    }

    return $new_qf_choices_lol
}


ad_proc -public qfo_2g {
    -fields_array:required
    {-fields_ordered_list ""}
    {-field_types_lists ""}
    {-inputs_as_array "qfi_arr"}
    {-form_submitted_p ""}
    {-form_id ""}
    {-doc_type ""}
    {-form_varname "form_m"}
    {-duplicate_key_check "0"}
    {-multiple_key_as_list "0"}
    {-hash_check "0"}
    {-post_only "0"}
    {-tabindex_start "1"}
    {-suppress_tabindex_p "1"}
    {-replace_datatype_tag_attributes_p "0"}
    {-write_p "1"}
} {
    Inputs essentially declare properties of a form and manages field type validation.
    <br><br>
    <code>fields_array</code> is an <strong>array name</strong>. 
    A form element is for example, an INPUT tag.
    Values are name-value pairs representing attributes for form elements.

    Each indexed value is a list containing attribute/value pairs of form element. The form element tag is determined by the data type.
    <br><br>
    Each form element is expected to have a 'datatype' in the list, 
    unless special cases of 'choice' or 'choices' are used (and discussed later).
    'text' datatype is default.
    <br><br>
    For html <code>INPUT</code> tags, a 'value' element represents a default value for the form element.
    <br><br>
    For html <code>SELECT</code> tags and <code>INPUT</code> tags with <code>type</code> 'checkbox' or 'radio', the attribute <code>value</code>'s 'value' is expected to be a list of lists consistent with 'value' attributed supplied to <code>qf_select</code>, <code>qf_choice</code> or <code>qf_choices</code>.
    <br><br>
    Special cases 'choice' and 'choices' are reprepresented by supplying an attribute <code>type</code> with value 'checkbox' or 'radio' or 'select'. If 'select', a single value is assumed to be returned unless an attribute <code>multiple</code> is supplied with corresponding value set to '1'. Note: Supplying a name/value pair '<code>multiple</code> 0' is treated the same as not including a <code>multiple</code> attribute.
    <br><br>
    Form elements are displayed in order of attribute 'tabindex' values.
    Order defaults are supplied by <code>-fields_ordered_list</code> consisting
    of an ordered list of indexes from <code>fields_array</code>.
    Indexes omitted from list appear after ordered ones.
    Any element in list that is not an index in fields_array 
    is ignored with warning.
    Yet, <code>fields_ordered_list</code> is optional.
    When fields_ordered_list is empty, sequence is soley 
    in sequential order according to relative tabindex value.
    Actual tabindex value is calculated, so that a sequence is contiguous
    even if supplied values are not.
    <br><br>
    <code>field_types_lists</code> is a list of lists 
    as defined by ::qdt::data_types parameter 
    <code>-local_data_types_lists</code>.
    See <code>::qdt::data_types</code> for usage.
    <br><br>
    <code>inputs_as_array</code> is an <strong>array name</strong>. 
    Array values follow convention of <code>qf_get_inputs_as_array</code>.
    If <code>qf_get_inputs_as_array</code> is called before calling this proc,
    supply the returned array name using this parameter.
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
    Returns 1 if there is input, and the input is validated.
    Otherwise returns 0.
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
    <code>write_p</code> if write_p is 0, presents form as a list of uneditable information.
    For example, setting to "\n<style>\nlabel { display: block ; }\n</style>\n"
    causes form elements to be displayed in a vertical, linear fashion
    as one would expect on a small device screen.
    <br><br>
    Note: fieldset tag is not implemented in this paradigm.
    <br><br>
    Note: qf_choices can determine use of type 'select' vs. 'checkbox' using
    just the existence of 'checkbox', anything else can safely be 
    interpreted to be a 'select multiple'.
    With qfo_2g, differentiation is not so simple. 'select' may specify
    a single choice, or 'multiple' selections with same name.
    <br><br>
    @see qdt::data_types
    @see util_user_message
    @see qf_get_inputs_as_array
    @see qfo::qtable_label_package_id
    @see qf_select
    @see qf_choice
    @see qf_choices
} {
    # Done: Verify negative numbers pass as values in ad_proc that uses
    # parameters passed starting with dash.. -for_example.
    # PASSED. If a non-decimal number begins with dash, flags warning in log.
    # Since default form_id may begin with dash, a warning is possible.

    # Blend the field types according to significance:
    # qtables field types declarations may point to different ::qdt::data_types
    # fields_arr overrides ::qdt::data_types
    # ::qdt::data_types defaults in qdt_types_arr
    # Blending is largely done via features of called procs.

    # fieldset is not implemented in this paradigm, because
    # it adds too much complexity to the code for the benefit.
    # A question is, if there is a need for fieldset, maybe
    # there is a need for a separate input page?

    # qfi = qf input
    # form_ml = form markup (usually in html starting with FORM tag)
    set error_p 0
    upvar 1 $fields_array fields_arr
    upvar 1 $inputs_as_array qfi_arr
    upvar 1 $form_varname form_m

    # To obtain page's doctype, if customized:
    upvar 1 doc doc
    # external doc array is used here
    set doctype [qf_doctype $doc_type]

    
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
    #    set datatype "text_word"
    #           ns_log Debug "qfo_2g.290: array get qdt_types_arr(${datatype},form_tag_attrs) '[array get qdt_types_arr(${datatype},form_tag_attrs) ]' array get qdt_types_arr(${datatype},form_tag_type) '[array get qdt_types_arr(${datatype},form_tag_type) ]'"
    #    ns_log Debug "qfo_2g.292: array get qdt_types_arr text_word '[array get qdt_types_arr "text_word*"]'"
    ##ns_log Debug "qfo_2g.382: array get qdt_types_arr text* '[array get qdt_types_arr "text*"]'"
    if { $qtable_enabled_p && 0 } {
	# Not supported for this version
	
        # Apply customizations from table defined in q-tables
        ##code This part has not been tested, as it is
        # pseudo code for a feature to add after 
        # 'hardcoded' deployment is proven to work, and testable
        # for this.

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

        # Superimpose dynamic fields over default fields from fields_arr.
        # Remaps overwrite all associated attributes from fields_arr
        # which means, datatype assignments are also handled.
        set qt_field_names_list [array names qt_fields_larr]
        ##code: this will not work for type:SELECT,Checkbox,or radio.
        ## Will q-tables paradigm handle these cases? May require a deeper
        ## investigation.
        ## It can adapt. Use tab delim data in a cell, then split.
        ## Or perhaps adding an additional datatype "set of elements"
        ## where  set of elements are defined as entries in another table..
        foreach n qt_field_names_list {
            set f_list $qt_fields_larr(${n})
            set datatype [lindex $f_list 4]
            set default [lindex $f_list 3]
            set name [lindex $f_list 2]
            set label [lindex $f_list 1]
            set label_nvl [list \
                               name $name \
                               datatype $datatype \
                               label $label \
                               default $default]

            # Apply customizations to fields_arr
            ##code Use $n instead of $label on next two lines??
            set fields_arr(${label}) $label_nvl
            # Build this array here that gets used later.
            set datatype_of_arr(${label}) $datatype
        }

    }


    set qfi_fields_list [array names fields_arr]
    # Do not assume field index is same as attribute name's value.
    # Ideally, this list is the names used for inputs. 
    # Yet, this pattern breaks for 'input checkbox' (not 'select multiple'),
    # where names are defined in the supplied value list of lists.
    # How to handle?  These cases should be defined uniquely,
    # using available data, so attribute 'id' if it exists,
    # and parsed via flag identifing their variation from using 'name'.


    ##ns_log Debug "qfo_2g.453: array get fields_arr '[array get fields_arr]'"
    ##ns_log Debug "qfo_2g.454: qfi_fields_list '${qfi_fields_list}'"
    set field_ct [llength $qfi_fields_list]
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
    set fields_ordered_list_len [llength $fields_ordered_list]
    set qfi_fields_list_len [llength $qfi_fields_list]
    if { $fields_ordered_list_len == $qfi_fields_list_len } {
        set calculate_tabindex_p 0
    } else {
        set calculate_tabindex_p 1
    }
    # Make a list of available datatypes
    # Html SELECT tags, and
    # INPUT tag with attribute type=radio or type=checkbox
    # present a discrete list, which is a
    # set of specific data choices.

    # To validate against one (or more in case of MULTIPLE) SELECT choices
    # either the choices must be rolled into a standardized validation proc
    # such as a 'qf_days_of_week' or provide the choices in a list, which
    # is required to build a form anyway.
    #  So, a special datatype is needed for two dynamic cases:
    #  select one / choice, such as for qf_choice
    #  select multiple / choices, such as for qf_choices
    # To be consistent, provide for cases when:
    #   1. qf_choice or qf_choices is used.
    #   2. INPUT (type checkbox or select) or SELECT tags are directly used.
    #   Case 2 does not fit this automated paradigm, so can ignore
    # for this proc. Yet, must still be considered in context of validation.
    # The api is already designed for handling case 2.
    # This proc uses qf_choice/choices paradigm, 
    # so special datatype handling is acceptable here, even if 
    # not part of q-data-types.
    # Name datatypes: choice, choices?
    # No, because what if there are multiple sets of choices?
    # name is unique, so:
    # datatype is name. Name collision is avoided by using
    # a separate array to store what is essentially custom lists.


    set button_c "button"
    set comma_c ","
    set datatype_c "datatype"
    set form_tag_attrs_c "form_tag_attrs"
    set form_tag_type_c "form_tag_type"
    set hidden_c "hidden"
    set input_c "input"
    set label_c "label"
    set multiple_c "multiple"
    set name_c "name"
    set select_c "select"
    set submit_c "submit"
    set tabindex_c "tabindex"
    set text_c "text"
    set type_c "type"
    set value_c "value"
    set title_c "title"
    set ignore_list [list $submit_c $button_c $hidden_c]
    # Array for holding datatype 'sets' defined by select/choice/choices:
    # fchoices_larr(element_name)

    set data_type_existing_list [list]
    foreach n [array names qdt_types_arr "*,label"] {
        lappend data_type_existing_list [string range $n 0 end-6]
    }

    # Make a list of datatype elements
    set datatype_dummy [lindex $data_type_existing_list 0]
    set datatype_elements_list [list]
    set datatype_dummy_len [string length $datatype_dummy]
    foreach n [array names qdt_types_arr "${datatype_dummy},*"] {
        lappend datatype_elements_list [string range $n $datatype_dummy_len+1 end]
    }
    ##ns_log Debug "qfo_2g.534: datatype_elements_list '${datatype_elements_list}'"

    set dedt_idx [lsearch -exact $datatype_elements_list $datatype_c]
    set ftat_idx [lsearch -exact $datatype_elements_list $form_tag_attrs_c]
    
    # Determine adjustments to be applied to tabindex values
    if { $qtable_enabled_p } {
        set tabindex_adj [expr { 0 - $field_ct - $fields_ordered_list_len } ]
    } else {
        set tabindex_adj $fields_ordered_list_len
    }
    set tabindex_tail [expr { $fields_ordered_list_len + $field_ct } ]


    # Parse fields

    # Build dataset validation and making a form

    # make a list of datatype elements that are not made during next loop:
    # element "datatype" already exists, skip that loop:
    # element "form_tag_attrs" already exists, skip that in loop also.
    # e = element
    # Remove from list, last first to use existing index values.
    set remaining_datatype_elements_list $datatype_elements_list
    if { $dedt_idx > $ftat_idx } {
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $dedt_idx $dedt_idx]
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $ftat_idx $ftat_idx]
    } else {
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $ftat_idx $ftat_idx]
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $dedt_idx $dedt_idx]
    }

    # default tag_type
    # tag_type is the html tag (aka element) used in the form.
    # tag is an attribute of tag_type.
    set default_type $text_c
    set default_tag_type "input"

    # $f_hash is field_index not field name.
    foreach f_hash $qfi_fields_list {

	ns_log Debug "qfo_2g.686  f_hash: '${f_hash}'"
        # This loop fills fatts_arr(${f_hash},${datatype_element}),
        # where datatype elements are:
        # label xml_format default_proc tcl_format_str tcl_type tcl_clock_format_str abbrev_proc valida_proc input_hint max_length css_abbrev empty_allowed_p html_style text_format_proc css_span form_tag_attrs css_div form_tag_type filter_proc
        # Additionally,
        # fatts_arr(${f_hash},names) lists the name (or names in the case of
        # multiple associated with form element) associated with f_hash.
        # This is a f_hash <--> name map, 
        # where name is a list of 1 or more form elements.

        # fatts_arr(${f_hash},$attr) could reference just the custom values
        # but then double pointing against the default datatype values
        # pushes complexity to later on.
        # Is lowest burden to get datatype first, load defaults,
        # then overwrite values supplied with field?  Yes.
        # What ife case is a table with 100+ fields with same type?
        # Doesn't matter, if every $f_hash and $attr will be referenced:
        # A proc could be called that caches, with parameters:
        # $f_hash and $attr, yet that is slower than just filling the array
        # to begin with, since every $f_hash will be referenced.

        # The following logical split of datatype handling
        # should not rely on a datatype value,
        # which is a proc-based artificial requirement,
        # but instead rely on value of tag_type.

        # If there is no tag_type and no form_tag_type, the default is 'text'
        # which then requires a datatype that defaults to 'text'.
        # The value is used to branch at various points in code,
        # so add an index with a logical value to speed up
        # parsing at these logical branches:  is_datatyped_p


	

        # get fresh, highest priority field html tag attributes
        set field_nvl $fields_arr(${f_hash})
        foreach {n v} $field_nvl {
            set nlc [string tolower $n]
            set hfv_arr(${nlc}) $v
            set hfn_arr(${nlc}) $n
        }
	ns_log Debug "qfo_g2.725 array get hfv_arr '[array get hfv_arr]'"

        set tag_type ""
	set datatype ""
        if { [info exists hfv_arr(datatype) ] } {
            # This field is partly defined by datatype
            set datatype $hfv_arr(datatype)

	    ns_log Debug "qfo_2g.733: qdt_types_arr(${datatype},form_tag_attrs) '$qdt_types_arr(${datatype},form_tag_attrs)' qdt_types_arr(${datatype},form_tag_type) '$qdt_types_arr(${datatype},form_tag_type)'"

            set dt_idx $datatype
            append dt_idx $comma_c $form_tag_type_c
            set tag_type $qdt_types_arr(${dt_idx})

            set dta_idx $datatype
            append dta_idx $comma_c $form_tag_attrs_c
            foreach {n v} $qdt_types_arr(${dta_idx}) {
                set nlc [string tolower $n ]
                set hfv_arr(${nlc}) $v
                set hfn_arr(${nlc}) $n
            }
	    ns_log Debug "qfo_2g.746. array get hfv_arr '[array get hfv_arr]' datatype '${datatype}' tag_type '${tag_type}'"
        } 

        # tag attributes provided from field definition
        if { $replace_datatype_tag_attributes_p \
                 && [array exists hfv_arr ] } {
            array unset hfv_arr
            array unset hfn_arr
        }
        # Overwrite anything introduced by datatype reference
        set field_nvl $fields_arr(${f_hash})
        foreach {n v} $field_nvl {
            set nlc [string tolower $n]
            set hfv_arr(${nlc}) $v
            set hfn_arr(${nlc}) $n
        }
	ns_log Debug "qfo_2g.762. array get hfv_arr '[array get hfv_arr]'"

        # Warning: Variable nomenclature near collision:
        # "datatype,tag_type"  refers to attribute 'type's value,
	# such as types of INPUT tags, 'hidden', 'text', etc.
	#
	# Var $tag_type refers to qdt_data_types.form_tag_type
	
        if { [info exists hfv_arr(type) ] && $hfv_arr(type) ne "" } {
            set fatts_arr(${f_hash},tag_type) $hfv_arr(type)
        }
	if { $tag_type eq "" && $datatype ne "" } {
	    set tag_type $fatts_arr(${f_hash},form_tag_type)
	}
        if { $tag_type eq "" } {
            # Let's try to guess tag_type
            if { [info exists hfv_arr(rows) ] \
                     || [info exists hfv_arr(cols) ] } {
                set tag_type "textarea"
            } else {
                set tag_type $default_tag_type
            }
        }
        ns_log Debug "qfo_2g.785 datatype '${datatype}' tag_type '${tag_type}'"
        set multiple_names_p ""
        if { ( [string match -nocase "*input*" $tag_type ] \
                   || $tag_type eq "" ) \
                 && [info exists hfv_arr(type) ] } {
            set type $hfv_arr(type)
            #set fatts_arr(${f_hash},tag_type) $type
	    # ns_log Debug "qfo_2g.630: type '${type}'"
            switch -exact -nocase -- $type {
                select {
                    if { [info exists hfv_arr(multiple) ] } {
                        set multiple_names_p 1
                        # Technically, 'select multiple' case is still one
                        # name, yet multiple values posted.
                        # This case is handled in the context
                        # of multiple_names_p, essentially as a subset
                        # of 'input checkbox' since names supplied
                        # with inputs *could* be the same.
                    } else {
                        set multiple_names_p 0
                    } 
                    set fatts_arr(${f_hash},is_datatyped_p) 0
                    set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p
                }
                radio {
                    set multiple_names_p 0
                    set fatts_arr(${f_hash},is_datatyped_p) 0
                    set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p
                }
                checkbox {
                    set multiple_names_p 1
                    set fatts_arr(${f_hash},is_datatyped_p) 0
                    set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p
                }
                email -
                file {
                    # These can pass multiple values in html5.
                    # Still should be validateable
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                }
                button -
                color -
                date -
                datetime-local -
                hidden -
                image -
                month -
                number -
                password -
                range -
                reset -
                search -
                submit -
                tel -
                text -
                time -
                url -
                week {
                    # Check of attribute against doctype occurs later.
                    # type is recognized
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                }
                default {
                    ns_log Debug "qfo_2g.853: field '${f_hash}' \
 attribute 'type' '${type}' for 'input' tag not recognized. \
 Setting 'type' to '${default_type}'"
                    # type set to defaut_type
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                    set hfv_arr(type) $default_type
                }
            }

            if { $fatts_arr(${f_hash},is_datatyped_p) } {
                # If there is no label, add one.
                if { ![info exists hfv_arr(label)] \
                         && [lsearch -exact $ignore_list $type] == -1 } {
		    #                    ns_log Debug "qfo_2g.855 array get hfv_arr '[array get hfv_arr]'"
                    set hfv_arr(label) $hfv_arr(name)
                    set hfn_arr(label) $label_c
                }
            }

        } elseif { [string match -nocase "*textarea*" $tag_type ] } {
            set fatts_arr(${f_hash},is_datatyped_p) 1
        } else  {
            ns_log Warning "qfo_2g.642: field '${f_hash}' \
 tag '${tag_type}' not recognized. Setting to '${default_tag_type}'"
            set tag_type $default_tag_type
            set fatts_arr(${f_hash},is_datatyped_p) 1
        } 
        set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p

        if { $fatts_arr(${f_hash},is_datatyped_p) } {
            
            if { [info exists hfv_arr(datatype) ] } {
                set datatype $hfv_arr(datatype)
                set fatts_arr(${f_hash},${datatype_c}) $datatype
            } else {
                set datatype $text_c
                set fatts_arr(${f_hash},${datatype_c}) $text_c
            }
	    #ns_log Debug "qfo_2g.875: datatype '${datatype}'"
            set name $hfv_arr(name)
            set fatts_arr(${f_hash},names) $name

        } else {

            # When fatts_arr($f_hash,datatype), is not created,
            # validation checks the set of elements in
            # fchoices_larr(form_name) list of choice1 choice2 choice3..

            # This may be a qf_select/qf_choice/qf_choices field
            # make and set the datatype using array fchoices_larr
            # No need to validate entry here.
            # Entry is validated when making markup language for form.
            # Just setup to validate input from form post/get.

            # define choice(s) datatype in fchoices_larr for validation

            if { [info exists hfv_arr(value) ] } {
                set tag_value $hfv_arr(value)
                # Are choices treated differently than choice
                # for validation? No
                # Only difference is name is for all choices with 'choice'
                # and 'choices select' whereas
                # 'choices checkbox' has a different name for each choice.
                # For SELECT tag, need to know if has MULTIPLE attribute
                # to know if to expect multiple input values.

                if { [info exists hfv_arr(name) ] } {
                    set tag_name $hfv_arr(name)
                    lappend fatts_arr(${f_hash},names) $tag_name
                }

                
                foreach tag_v_list $tag_value {
                    # Consider uppercase/lowercase refs
                    foreach {n v} $tag_v_list {
                        set nlc [string tolower $n]
                        #set fn_arr($nlc) $n
                        set fv_arr(${nlc}) $v
                    }
                    if { [info exists fv_arr(value) ] } {
                        if { [info exists fv_arr(name)] } {
                            # Use lappend to collect validation values, 
                            # because the name may be the same, 
                            # just different value.
                            lappend fchoices_larr($fv_arr(name)) $fv_arr(value)
                            lappend fatts_arr(${f_hash},names) $fv_arr(name)
                        } else {
                            # use name from tag
                            lappend fchoices_larr(${tag_name}) $fv_arr(value)
                        }
                    }
                    array unset fv_arr
                    
                }
                
            } else {
                set error_p 1
                ns_log Error "qfo_2g.722: value for field '${f_hash}' not found."
            }
        }
        

        if { !$error_p } {
            
            if { $fatts_arr(${f_hash},is_datatyped_p) } {

                lappend fields_w_datatypes_used_arr(${datatype}) $f_hash


                foreach e $remaining_datatype_elements_list {
                    # Set field data defaults according to datatype
                    set fatts_arr(${f_hash},${e}) $qdt_types_arr(${datatype},${e})
                    ##ns_log Debug "qfo_2g.734 set fatts_arr(${f_hash},${e}) \
                        ## '$qdt_types_arr(${datatype},${e})' (qdt_types_arr(${datatype},${e}))"
                }
            }


            if { $calculate_tabindex_p } {
                # Calculate relative tabindex
                set val [lsearch -exact $fields_ordered_list $f_hash]
                if { $val < 0 } {
                    set val $tabindex_tail
                    if { [info exists hfv_arr(tabindex) ] } {
                        if { [qf_is_integer $hfv_arr(tabindex) ] } {
                            set val [expr { $hfv_arr(tabindex) + $tabindex_adj } ]
                        } else {
                            ns_log Warning "qfo_2g.980: tabindex not integer \
 for  tabindex attribute of field '${f_hash}'. Value is '${val}'"
                        }
                    }
                }
                set fatts_arr(${f_hash},tabindex) $val
            }
            
            set new_field_nvl [list ]
            foreach nlc [array names hfn_arr] {
                lappend new_field_nvl $hfn_arr(${nlc}) $hfv_arr(${nlc})
            }
            
            set fatts_arr(${f_hash},form_tag_attrs) $new_field_nvl
            
        }
        ##ns_log Debug "qfo_2g.761: array get fatts_arr '[array get fatts_arr]'"
        ##ns_log Debug "qfo_2g.762: data_type_existing_list '${data_type_existing_list}'"
	
        array unset hfv_arr
        array unset hfn_arr
    }
    # end of foreach f_hash



    # All the fields and datatypes are known.
    # Proceed with form building and UI stuff


    # Collect only the field_types that are used, because
    # each set of datatypes could grow in number, slowing performance
    # as system grows in complexity etc.
    set datatypes_used_list [array names fields_w_datatypes_used_arr]




    # field types are settled by this point

    if { $form_submitted_p eq "" } {
        set form_submitted_p [qf_get_inputs_as_array qfi_arr \
                                  duplicate_key_check $duplicate_key_check \
                                  multiple_key_as_list $multiple_key_as_list \
                                  hash_check $hash_check \
                                  post_only $post_only ]
        #ns_log Debug "qfo_2g.891 array get qfi_arr '[array get qfi_arr]'"
    } 

    # Make sure every qfi_arr(x) exists for each field
    # Fastest to just collect the most fine grained defaults of each field
    # into an array and then overwrite the array with qfi_arr
    # Except, we don't want any extraneous input inserted unexpectedly in code.

    ##code Future feature comment. In a new proc, qfo_3g, 
    # maybe allow dynamically generated fields to allow
    # this following exception:
    # Except, we don't want a filter process
    #   to lose dynamically generated form fields, such as used in
    #   forms that pass N number of cells in a spreadsheet.
    # So, don't optimize with: array set qfv_arr /array get qfi_arr/
    # Yet, provide a mechanism to allow 
    # batch process of a set of dynamic fields
    # by selecting the fields via a glob that uniquely identifes them like so:
    #  array set qfv_arr /array get qfi_arr "{glob1}"
    #  array set qfv_arr /array get qfi_arr "glob2"

    # For now, dynamically generated fields need to be 
    # created in fields_array or be detected and filtered
    # by calling qf_get_inputs_as_array *before* qfo_2g
    #ns_log Debug "qfo_2g.903 form_submitted_p '${form_submitted_p}' array get qfi_arr '[array get qfi_arr]'"

    #ns_log Debug "qfo_2g.905 array get fields_arr '[array get fields_arr]'"

    # qfv = field value
    foreach f_hash $qfi_fields_list {

        # Some form elements have different defaults
        # that require more complex values: 
        # fieldtype is checkboxes, radio, or select.
        # Make sure they work here as expected ie:
        # Be consistent with qf_* api in passing field values

        # Overwrite defaults with any inputs
        foreach name $fatts_arr(${f_hash},names) {
            if { [info exists qfi_arr(${name})] } {
                set qfv_arr(${name}) $qfi_arr(${name})
            } 
            # Do not set default value if there isn't any value
            # These cases will be caught during validation further on.
        }
    } 
    # Don't use qfi_arr anymore, as it may contain extraneous input
    # Use qfv_arr for input array
    array unset qfi_arr
    #ns_log Debug "qfo_2g.1018 form_submitted_p '${form_submitted_p}' array get qfv_arr '[array get qfv_arr]'"
    # validate inputs?
    set validated_p 0
    set all_valid_p 1
    set valid_p 1
    set invalid_field_val_list [list ]
    set nonexisting_field_val_list [list ]
    set row_list [list ]
    if { $form_submitted_p } {
	
	# validate inputs

        foreach f_hash $qfi_fields_list {

            # validate.
	    ns_log Debug "qfo_2g.1077: f_hash '${f_hash}', datatype '${datatype}'"
            if { $fatts_arr(${f_hash},is_datatyped_p) } {
                # Do not set a name to exist here,
                # because then it might validate and provide
                # info different than the user submitted.

                if { [info exists fatts_arr(${f_hash},valida_proc)] } {
                    set name $fatts_arr(${f_hash},names)
		    #                    ns_log Debug "qfo_2g.900. Validating '${name}'"
                    if { [info exists qfv_arr(${name}) ] } {
                        set valid_p [qf_validate_input \
                                         -input $qfv_arr(${name}) \
                                         -proc_name $fatts_arr(${f_hash},valida_proc) \
                                         -form_tag_type $fatts_arr(${f_hash},form_tag_type) \
                                         -form_tag_attrs $fatts_arr(${f_hash},form_tag_attrs) \
                                         -q_tables_enabled_p $qtable_enabled_p \
                                         -empty_allowed_p $fatts_arr(${f_hash},empty_allowed_p) ]
                        if { !$valid_p } {
                            lappend invalid_field_val_list $f_hash
                        }
                    } else {
			ns_log Debug "qfo_2g.1111. array get fatts_arr f_hash,* '[array get fatts_arr ${f_hash},*]'"
                        if { ![info exists fatts_arr(${f_hash},tag_type) ] || [lsearch -exact $ignore_list $fatts_arr(${f_hash},tag_type) ] == -1 } {
                            ns_log Debug "qfo_2g.1113: field '${f_hash}' \
 no validation proc. found"
                        }
                    }
                } else {
                    lappend nonexsting_field_val_list $f_hash
                }

            } else {
                # not is_datatyped_p: type is select, checkbox, or radio input
                set valid_p 1
                set names_len [llength $fatts_arr(${f_hash},names)]
                set n_idx 0
                while { $n_idx < $names_len && $valid_p } {
                    set name $fatts_arr(${f_hash},names)
                    if { [info exists qfv_arr(${name}) ] } {
                        # check for type=select,checkbox, or radio
                        # qfv_arr may contain multiple values
                        foreach m $qfv_arr(${name}) {
                            set m_valid_p 1
                            if { [lsearch -exact $fchoices_larr(${name}) $m ] < 0 } {
                                # name exists, value not found
                                set m_valid_p 0
                                ns_log Debug "qfo_2g.1136: name '${name}' \
 has not valid value '$qfv_arr(${name})'"
                            }
                            set valid_p [expr { $valid_p && $m_valid_p } ]
                        }
                    }
                    incr n_idx
                }
            }
            # keep track of each invalid field.
            set all_valid_p [expr { $all_valid_p && $valid_p } ]
        }
        set validated_p $all_valid_p
	#        ns_log Notice "qfo_2g.1117: Form input validated_p '${validated_p}' \
	    # invalid_field_val_list '${invalid_field_val_list}' \
	    # nonexisting_field_val_list '${nonexisting_field_val_list}'"
    } else {
        # form not submitted
	
        # Populate form values with defaults if not provided otherwise
        foreach f_hash $qfi_fields_list {
            if { ![info exists fatts_arr(${f_hash},value) ] } {
                # A value was not provided by fields_arr
                if { $fatts_arr(${f_hash},is_datatyped_p) } {
                    set qfv_arr(${f_hash}) [qf_default_val $fatts_arr(${f_hash},default_proc) ]
                }
            }
        }
    }

    if { $validated_p } {
        # Which means form_submitted_p is 1 also.

        if { $qtable_enabled_p } {
            # save a new row in customized q-tables table
            qt_row_create $qtable_id $row_list
        }
        # put qfv_arr back into qfi_arr
        array set qfi_arr [array get qfv_arr]

    } else {
        # validated_p 0, form_submitted_p is 0 or 1.

        # generate form

        # Blend tabindex attributes, used to order html tags:
        # input, select, textarea. 
        # '1' is first tabindex value.
        # fields_ordered_list overrides original fields attributes.
        # Original is in fields_arr(name) nvlist.. element tabindex value,
        #  which converts to fatts_arr(name,tabindex) value (if exists).
        # Dynamic fatts (via q-tables)  overrides both, and is already handled.
        # Blending occurs by assigning a lower range value to each case,
        # then choosing the lowest value for each field.

        # Finally, a new sequence is generated to clean up any blending
        # or ommissions in sequence etc.
        if { $calculate_tabindex_p } {
            # Create a new qfi_fields_list, sorted according to tabindex
            set qfi_fields_tabindex_lists [list ]
            foreach f_hash $qfi_fields_list {
                set f_list [list $f_hash $fatts_arr(${f_hash},tabindex) ]
                lappend qfi_fields_tabindex_lists $f_list
            }
            set qfi_fields_tabindex_sorted_lists [lsort -integer -index 1 \
                                                      $qfi_fields_tabindex_lists]
            set qfi_fields_sorted_list [list]
            foreach f_list $qfi_fields_tabindex_sorted_lists {
                lappend qfi_fields_sorted_list [lindex $f_list 0]
            }
        } else {
            set qfi_fields_sorted_list $fields_ordered_list
        }

	
        # build form using qf_* api
        set form_m ""
	
        set form_id [qf_form form_id $form_id hash_check $hash_check]

        # Use qfi_fields_sorted_list to generate 
        # an ordered list of form elements

        if { !$validated_p && $form_submitted_p } {

            # Update form values to those provided by user.
            # That is, update value of 'value' attribute to one from qfv_arr
            # Add back the nonexistent cases that must carry a text value
            # for the form.

            ##code
            # Highlight the fields that did not validate.
            # Add hints to title/other attributes.

            set selected_c "selected"
            foreach f_hash $qfi_fields_sorted_list {
                set fatts_arr_index $f_hash
                append fatts_arr_index $comma_c $form_tag_attrs_c


                # Determine index of value attribute's value
                foreach {n v} $fatts_arr(${fatts_arr_index}) {
                    set nlc [string tolower $n]
                    set fav_arr(${nlc}) $v
                    set fan_arr(${nlc}) $n
                }


                if { $fatts_arr(${f_hash},is_datatyped_p) } {


                    if { [string match "*html*" $doctype ] } {
                        if { [lsearch -exact $invalid_field_val_list $f_hash] > -1 } {
                            # Error, tell user
                            set error_msg " <strong class=\"form-label-error\">"
                            append error_msg "#acs-tcl.lt_Problem_with_your_inp# <br> "
                            if { !$fatts_arr(${f_hash},empty_allowed_p) } {
                                append error_msg "<span class=\"form-error\"> "
                                append error_msg "#acs-templating.required#"
                                append error_msg "</span> "
                            }
                            append error_msg "#acs-templating.Format# "
                            append error_msg $fatts_arr(${f_hash},input_hint)
                            append error_msg "</strong> "
                            if { [info exists fav_arr(label) ] } {
                                append fav_arr(label) $error_msg
                            } else {
                                set fav_arr(title) $error_msg
                                set fan_arr(title) $title_c
                            }
                        } else {
                            if { ![info exists fav_arr(title) ] } {
                                set fav_arr(title) "#acs-templating.Format# "
                                append fav_arr(title) $fatts_arr(${f_hash},input_hint)
                                set fan_arr(title) $title_c 
                            }
                        }
                    }
		    

                    set n2 $fatts_arr(${f_hash},names)
                    if { [info exists qfv_arr(${n2}) ] } {
                        set v2 [qf_unquote $qfv_arr(${n2}) ]
                        if { $v2 ne "" \
                                 || ( $v2 eq "" \
                                          && $fatts_arr(${f_hash},empty_allowed_p) ) } {
			    #                            ns_log Notice "qo_g2.1021 n2 '${n2}' v2 '${v2}' qf# v_arr(${n2}) '$qfv_arr(${n2})'"
                            set fav_arr(value) $v2
                            if { ![info exists fan_arr(value) ] } {
                                set fan_arr(value) $value_c
                            }
                        }
                    } else {
                        # If there is a 'selected' attr, unselect it.
                        if { [info exists fav_arr(selected) ] } {
                            set fav_arr(selected) "0"
                        }
                    }

                    set fa_list [list ]
                    foreach nlc [array names fav_arr] {
                        lappend fa_list $fan_arr(${nlc}) $fav_arr(${nlc})
                    }
                    set fatts_arr(${fatts_arr_index}) $fa_list

                    # end has_datatype_p block

                } else { 
                    switch -exact -nocase -- $fatts_arr(${f_hash},tag_type) {
                        radio -
                        checkbox -
                        select {
                            # choice/choices name/values may not exist.
                            # qfo::lol_remake handles those cases also.
                            if { [info exists fav_arr(value) ] } {
                                set fatts_arr(${fatts_arr_index}) [::qfo::lol_remake \
                                                                       -attributes_name_array_name fan_arr \
                                                                       -attributes_value_array_name fav_arr \
                                                                       -is_multiple_p $fatts_arr(${f_hash},multiple_names_p) \
                                                                       -qfv_array_name qfv_arr ]
				
                            }
                        }
                        default {
                            ns_log Warning "qfo_2g.1245 tag_type '${tag_type}' \
 unexpected."
                        }
                        
                    }
                }
                array unset fav_arr
                array unset fan_arr
            }
        }

        # Every f_hash element has a value at this point..
	if { $write_p } {
	    
	    # build form
	    set tabindex $tabindex_start
	    
	    foreach f_hash $qfi_fields_sorted_list {
		set atts_list $fatts_arr(${f_hash},form_tag_attrs)
		foreach {n v} $atts_list {
		    set nlc [string tolower $n]
		    set attn_arr(${nlc}) $n
		    set attv_arr(${nlc}) $v
		}
		

		if { [info exists attv_arr(tabindex) ] } {
		    if { $suppress_tabindex_p } {
			unset attv_arr(tabindex)
			unset attn_arr(tabindex)
		    } else {
			set attv_arr(tabindex) $tabindex
		    }
		}

		set atts_list [list ]
		foreach nlc [array names attn_arr ] {
		    lappend atts_list $attn_arr(${nlc}) $attv_arr(${nlc})
		}
		array unset attn_arr
		array unset attv_arr

		if { $fatts_arr(${f_hash},is_datatyped_p) } {

		    switch -exact -- $fatts_arr(${f_hash},form_tag_type) {
			input {
			    ##ns_log Notice "qfo_2g.1001: qf_input \
				   ## fatts_arr(${f_hash},form_tag_attrs) '${atts_list}'"
			    qf_input $atts_list
			}
			textarea {
			    ##ns_log Notice "qfo_2g.1003: qf_textarea \
				      ## fatts_arr(${f_hash},form_tag_attrs) '${atts_list}'"
			    qf_textarea $atts_list
			}
			default {
			    # this is not a form_tag_type
			    # tag attribute 'type' determines if this
			    # is checkbox, radio, select, or select/multiple
			    # This should not happen, because
			    # fatts_arr(${f_hash},is_datatyped_p) is false for 
			    # these cases.
			    ns_log Warning "qfo_2g.1009: Unexpected form element: \
 f_hash '${f_hash}' ignored. \
 fatts_arr(${f_hash},form_tag_type) '$fatts_arr(${f_hash},form_tag_type)'"
			}
		    }
		} else {
		    # choice/choices

		    if { $fatts_arr(${f_hash},multiple_names_p) } {
			qf_choices $atts_list
		    } else {
			qf_choice $atts_list
		    }

		}
		incr tabindex
	    }
	    qf_close form_id $form_id
	    append form_m [qf_read form_id $form_id]
	} else {
	    # write_p is 0
	    # Display form data only
	    
	    append form_m "<ul id="
	    append form_m "\"" $form_id "\">\n"
	    
	    foreach f_hash $qfi_fields_sorted_list {
		set atts_list $fatts_arr(${f_hash},form_tag_attrs)
		foreach {n v} $atts_list {
		    set nlc [string tolower $n]
		    set attn_arr(${nlc}) $n
		    set attv_arr(${nlc}) $v
		}
		
		if { $fatts_arr(${f_hash},is_datatyped_p) } {

		    switch -exact -- $fatts_arr(${f_hash},form_tag_type) {
			textarea -
			input {
			    if { [info exists attv_arr(type) ] \
				     && ![string match -nocase "hidden" $attv_arr(type) ] \
				     && ![string match -nocase "submit" $attv_arr(type) ] \
				     && ![string match -nocase "button" $attv_arr(type) ] \
				     && ![string match -nocase "password" $attv_arr(type) ] \
				     && ![string match -nocase "reset" $attv_arr(type) ] \
				     && ![string match -nocase "search" $attv_arr(type) ] } {
				append form_m "<li>"
				set class_p [info exists attv_arr(class)]
				set style_p [info exists attv_arr(style)]
				set value_p [info exists attv_arr(value)]
				set name_p [info exists attv_arr(name)]
				set label_p [info exists attv_arr(label)]
				if { $label_p } {
				    set label $attv_arr(label)
				} else {
				    set label ""
				}
				if { $class_p || $style_p } {
				    append form_m "<span"
				    if { $class_p } {
					append form_m " class=\"" $attv_arr(class) "\""
				    }
				    if { $style_p } {
					append form_m " style=\"" $attv_arr(style) "\""
				    }
				    append form_m ">" $label "</span>"
				} else {
				    append form_m $label
				}
				if { $value_p } {
				    append form_m "<br>" $attv_arr(value) "</li>\n"
				} else {
				    append form_m "<br></li>\n"
				    #ns_log Notice "qfo_2g.1420. No value for attv_(value) array get attv_arr '[array get attv_arr]'"
				}
			    }
			}
			default {
			    # this is not a form_tag_type
			    # tag attribute 'type' determines if this
			    # is checkbox, radio, select, or select/multiple
			    # This should not happen, because
			    # fatts_arr(${f_hash},is_datatyped_p) is false for 
			    # these cases.
			    ns_log Warning "qfo_2g.1410: Unexpected form element: \
 f_hash '${f_hash}' ignored. \
 fatts_arr(${f_hash},form_tag_type) '$fatts_arr(${f_hash},form_tag_type)'"
			}
		    }
		} else {
		    append form_m "<li>"
		    set class_p [info exists attv_arr(class)]
		    set style_p [info exists attv_arr(style)]
		    if { $class_p || $style_p } {
			append form_m "<span"
			if { $class_p } {
			    append form_m " class=\"" $attv_arr(class) "\""
			}
			if { $style_p } {
			    append form_m " style=\"" $attv_arr(style) "\""
			}
			append form_m ">" $attv_arr(label) "</span>"
		    } else {
			if { [info exists attv_arr(label) ] } {
			    append form_m $attv_arr(label)
			} 
		    }
		    append form_m "<br><ul>\n"
		    # choice/choices
		    # Just show the values selected
		    ns_log Notice "qfo_2g.1483: f_hash '${f_hash}'"
		    if { $fatts_arr(${f_hash},multiple_names_p) eq 1 } {
			#qf_choices
			foreach row_list $attv_arr(value) {
			    foreach {n v} $row_list {
				set nlc [string tolower $n]
				set choices_arr(${nlc}) $v
			    }
			    if { [info exists choices_arr(selected)] } {
				if { $choices_arr(selected) } {
				    append form_m "<li>"
				    if { [info exists choices_arr(label) ] } {
					append form_m $choices_arr(label)
				    } elseif { [info exists choices_arr(value) ] } {
					append form_m $choices_arr(value)
				    }
				    append form_m "</li>"
				}
			    }
			    array unset choices_arr
			}		
		    } else {
			#qf_choice
			if { [info exists attv_arr(value) ] } {
			    set rows_max [llength $attv_arr(value) ]
			    set i 0
			    set i_max 500
			    while { $i < $rows_max && $i < $i_max } {
				set row_list [lindex $attv_arr(value) $i]
				foreach {n v} $row_list {
				    set nlc [string tolower $n]
				    set choices_arr(${nlc}) $v
				}
				if { [info exists choices_arr(selected)] } {
				    if { $choices_arr(selected) } {
					append form_m "<li>"
					if { [info exists choices_arr(label) ] } {
					    append form_m $choices_arr(label)
					} elseif { [info exists choices_arr(value) ] } {
					    append form_m $choices_arr(value)
					}
					append form_m "</li>"
				    }
				}
				array unset choices_arr
				incr i
			    }
			}
		    }
		    lappend form_m "</ul>"
		    append form_m "</li>\n"
		}
		
		array unset attn_arr
		array unset attv_arr
		# next field
	    }
	}
    }    
    return $validated_p
}

ad_proc -private qf_default_val {
    default_proc_q
} {
    Returns the value of default_proc_q, or the value passed if default_proc_q is not a recognized default proc according to parameter <code>allowedDefaultProcs</code>.
} {
    set procs_list [parameter::get_from_package_key \
                        -package_key q-forms \
                        -parameter allowedDefaultProcs ]
    if { [lsearch -exact $procs_list $default_proc_q ] > -1 } {
        set return_val [safe_eval $default_proc_q ]
    } else {
        set return_val $default_proc_q
    }
    return $return_val
}

ad_proc -private qf_validate_input {
    -input 
    -proc_name
    {-q_tables_enabled_p "0"}
    {-form_tag_type ""}
    {-form_tag_attrs ""}
    {-empty_allowed_p "0"}
} {
    Returns '1' if value is validated. Otherwise returns '0'.
    <br><br>
    <code>form_tag_type</code> and <code>form_tag_attrs</code> refer to the fields of same name as defined by <code>qdt::data_types</code>.
    These two fields might be used to validate special cases, such as INPUT tag of various special-purpose types, or for diagnostics (To Be Determined).
    @see qdt::data_types

} {
    
    set valid_p 0

    # Simplify any future cases, where 
    # proc_name is called with default ' {value}' explicitly added.
    if { $input eq "" } {

        set valid_p $empty_allowed_p

    } else {

        set proc_name_len [llength $proc_name]
        if { $proc_name_len > 1 } {
            if { $proc_name_len eq 2 \
                     && [lindex $proc_name 1] eq "{value}" } {
                set proc_name [lindex $proc_name 0]
                set proc_name_len 1
            } else {
                regsub -- {{value}} $proc_name "\${input}" proc_name
                set proc_params_list [split $proc_name " "]
                set proc_name [lindex $proc_params_list 0]
            }
        }
        switch -exact -- $proc_name {
            qf_is_decimal {
                set valid_p [qf_is_decimal $input ]
            }
            qf_is_integer {
                set valid_p [qf_is_integer $input ]
            }
            hf_are_safe_and_visible_characters_q {
                set valid_p [hf_are_safe_and_visible_characters_q $input ]
            }
            hf_are_safe_and_printable_characters_q {
                set valid_p [hf_are_safe_and_printable_characters_q $input ]
            }
	    hf_are_safe_textarea_characters_q {
		set valid_p [hf_are_safe_textarea_characters_q $input]
	    }
            hf_list_filter_by_natural_number {
                set input_list [split $input ";,\t "]
                set filtered_list [hf_list_filter_by_natural_number $input_list ]
                if { [llength $input_list ] == [llength $filtered_list] } {
                    set valid_p 1
                } else {
                    set valid_p 0
                }
            }
            util_url_valid_p {
                set valid_p [util_url_valid_p $input ]
            }
            qf_email_valid_q {
                set valid_p [qf_email_valid_q $input ]
            }
            qf_clock_scan {
                set time_since_epoch [qf_clock_scan $input]
                if { $time_since_epoch ne "" } {
                    set valid_p 1
                }
            }
            qf_is_decimal {
                set valid_p [qf_is_decimal $input ]
            }
            qf_is_natural_number {
                set valid_p [qf_is_natural_number $input ]
            }
            ad_var_type_check_safefilename_p {
                set valid_p [qfad_safefilename_p $input ]
            }
            qf_domain_name_valid_q {
                set valid_p [qf_domain_name_valid_q $input ]
            }
            ad_var_type_check_word_p {
                set valid_p [qfad_word_p $input]
            }
            qf_is_boolean {
                set valid_p [qf_is_boolean $input ]
            }
            qf_is_currency_like {
                set valid_p [qf_is_currency_like $input]
            }
            qf_is_currency {
                if { $proc_name_len eq 2 } {
                    set valid_p [qf_is_currency $input [lindex $proc_params_list 1]]
                } else {
                    set valid_p [qf_is_currency $input]
                }
            }
            default {
                # Is default_proc allowed?
                set allowed_p 0
                set procs_list [parameter::get \
                                    -package_id [ad_conn package_id] \
                                    -parameter AllowedValidationProcs \
                                    -default ""]

                if { [lsearch -exact $procs_list $proc_name ] > -1 } {
                    set allowed_p 1
                }
                if { !$allowed_p && $q_tables_enabled_p } {
                    # Check for custom cases
                    set default_val ""
                    if {[catch { set default_val [parameter::get_from_package_key -package_key q-tables -parameter AllowedValidationProcs -default "" ] } ] } {
                        # more than one q-tables exist
                        # Maybe change this to find one in a subsite.
                        # something like qc_set_instance_id from q-control
                    }
                    set custom_procs [parameter::get \
                                          -package_id [ad_conn package_id] \
                                          -parameter AllowedValidationProcs \
                                          -default $default_val]
                    foreach p $custom_procs {
                        if { [string match $p $proc_name] } {
                            set allowed_p 1
                        }
                    }
                    if { !$allowed_p } {
                        ns_log Warning "qf_validate_input.1690: Broken UI. \
 Unknown validation proc '${proc_name}' proc_params_list '${proc_params_list}'"


                    } else {
                        ns_log Notice "qf_validate_input.1695: processing safe_eval '${proc_params_list}'"
                        set valid_p [safe_eval $proc_params_list]
                    }
                }
                if { !$allowed_p } {
                    ns_log Warning "qf_validate_input.1700: Broken UI. \
 proc_name '${proc_name}' form_tag_type '${form_tag_type}' \
 form_tag_attrs '${form_tag_attrs}'"
                }
            }
        }
    }    
    return $valid_p
}

ad_proc -public ::qfo::form_list_def_to_array {
    -array_name
    -list_of_lists_name
    {-fields_ordered_list_name "qf_fields_ordered_list"}
    {-ignore_parse_issues_p "1"}
} {
    Converts a well formed list of lists into an array for input
    as fields_array in qfo_2g, and provides a fields_ordered_list based on
    the order elements defined in the list.
    <br><br>
    When <code>ignore_parse_issues_p</code> is '1', 
    any list item that cannot be parsed as expected will be ignored. 
    When <code>ignore_parse_issues_p</code> is '0', 
    any parsing issue will trigger a warning posted to ns_log.
    <br><br>
    Indexes are assigned the same as it's element's name's attribute value, 
    such as 'xyz' for &lt;input name="xyz" value=""&gt;. 
    Cases with multiple choice use the value of an ID attribute if it exists,
    otherwise a unique id is created.
} {
    upvar 1 $array_name fields_arr
    upvar 1 $list_of_lists_name elements_lol
    upvar 1 $fields_ordered_list_name fields_ordered_list
    set multiple_i 0
    set select_c "select"
    set multiple_c "multiple"
    set checkbox_c "checkbox"
    set fields_ordered_list [list ]
    foreach element_nvl $elements_lol {
        # array set e_arr $element_nvl, except convert names to lowercase
        set n_list [list ]
        foreach {n v} $element_nvl {
            set nlc [string tolower $n]
            lappend n_list $nlc
            set v_arr(${nlc}) $v
            set n_arr(${nlc}) $n
        }
        if { [info exists v_arr(name) ] } {
            set fields_arr($v_arr(name)) $element_nvl
            lappend fields_ordered_list $v_arr(name)
        } elseif { [info exists v_arr(type) ] } {
            switch -exact -nocase -- $v_arr(type) {
                select -
                checkbox {
                    # If type is checkbox, it is a multiple choice
                    # If type is select, it must be multiple choice, because
                    # if it wasn't, it would have a 'name' attribute.
                    if { $v_arr(type) eq $select_c } {
                        set mx [lsearch -exact $n_list $multiple_c ]
                        if { $mx > -1 } {
                            set element_nvl [lreplace $element_nvl $mx $mx 1]
                        } else {
                            lappend element_nvl $multiple_c 1
                        }
                    }

                    # if id exists, use it, or create one.
                    if { [info exists v_arr(id) ] } {
                        set multiple_ref $v_arr(id)
                    } else {
                        set multiple_ref $multiple_c
                        append multiple_ref $multiple_i
                    }
                    set fields_arr(${multiple_ref}) $element_nvl
                    lappend fields_ordered_list $multiple_ref
                    incr multiple_i
                }
                default {
                    if { !$ignore_parse_issues_p } {
                        ns_log Warning "::qfo::form_list_def_to_array.1241: \
 No 'name' attribute found, and type '$v_arr(type)' \
 not of type 'checkbox' or 'select multiple' for element '${element_nvl}'"
                    }
                }
            }
        } else {
            if { !$ignore_parse_issues_p } {
                ns_log Warning "::qfo::form_list_def_to_array.1249: \
 No 'name' or 'type' attribute found for element '${element_nvl}'"
            }
        }
        array unset v_arr
        array unset n_arr
    }
    ##ns_log Notice "::qfo::form_list_def_to_array.1267: ${list_of_lists_name} '${elements_lol}'"
    ##ns_log Notice "::qfo::form_list_def_to_array.1268: array get ${array_name} '[array get fields_arr ]'"
    return $fields_ordered_list
}

ad_proc -public ::qfo::form_list_def_to_css_table_rows {
    -form_field_defs_to_multiply
    -rows_count
    {-list_of_lists_name ""}
    {-group_letter ""}
    {-ignore_parse_issues_p "1"}
    {-rows_count_max "999"}
} {
    Returns a multiple set of form field definitions by copying each supplied
    field definition, and changing the field name.
    This is for use in the <code>qal_3g</code> paradigm.
    <br><br>
    <code>form_field_defs_to_multiply</code> The name of a list of field
    definitions per qal_3g/qfo_2g paradigm that are to be multiplied.
    <br><br>
    <code>rows_count</code> The number of times each field is to be
    multiplied.
    <br><br>
    <code>list_of_lists_name</code> The name of the complete form definition
    list_of_lists that gets passed to qal_3g or qfo_2g.  If provided,
    this proc will automatically add the generated fields to this list.
    <br><br>
    <code>group_letter</code> This a unique, single letter that is assigned to
    each group of multiplied rows that help identify the group. It is
    supplied by default, but you can choose it to.
    <br><br>
    <code>rows_count_max</code> Fields cannot be multiplied higher than this.
    On invoices at least, a survey of software specs suggests four digits
    is considered a practical high limit for BOM items.
    <code>defaults_arr_name</code> is the name of an array that contains
    the values to use for each of the elements in a form. The index
    of the array is the value of the attribute 'name' for each element.
    For example, if defaults_arr_name is old_val_arr, and there is
    an element named 'city' containing value 'Atlantis', then
    old_var_arr(city) equals 'Atlantis'.  The proc will automatically
    calculate the variances of the names for the various rows and extract
    the related data, if any, from the array. Any missing value defaults to ""
    <br><br>
    Converts a row of related form fields formated for input into qal_3g,
    into multiple rows with related naming conventions. Put another
    way, it takes a well formed list of lists of qaf_2g form input fields into
    multiple scalar arrays of same. For example, suppose one has
    a form where some data inputs are repeated, such as on an invoice.
    If the input names are: qty unit description price_per_unit qty_price,
    And list_of_lists_name is a list_of_lists defining the fields,
    and rows_count is '2', then this proc returns a well formed list of lists
    with two rows defined using rc table naming convention with a twist.
    <br><br>
    Instead of the conventional group:rowcolumn like sheet1:3A,
    to fit the html form paradigm, name_{group}{column}{row} is used, where
    name is the name of each field.
    As an example, for this proc, groups are designated a letter:
    address_line1_ba3 for second group, first column, third row of
    address_line1.
    <br><br>
    This proc does not work with select multiple (checkbox or select)
    inputs, but those cases *could* be added without too much additional
    complexity if you find a case that needs them and want to program it.
    @see qal_3g
} {
    upvar 1 $form_field_defs_to_multiply elements_lol
    upvar 1 __qfo_groups_used_list groups_used_list
    if { $list_of_lists_name ne "" } {
        set add_to_lol_p 1
        upvar 1 $list_of_lists_name lol_name
    } else {
        set add_to_lol_p 0
    }
    # Let's put an upper limit on rows,
    # maybe to help avoid some kind of DOS issue
    # A survey of other web app limits suggests 999
    # is above the max for most all practical cases

    # make sure user input a list of lists, not just a list (single form element)
    set name_c "name"
    set value_c "value"
    if { [lsearch -nocase $elements_lol $name_c] > -1 } {
        ns_log Error "form_list_def_to_css_table_rows.1809 Detected list_of_lists is a list instead. Wrap it with another list."
        ad_script_abort
    }
    
    if { $rows_count > 0 && $rows_count < $rows_count_max } {
        if { ![info exists groups_used_list] } {
            set groups_used_list [list ]
        }

        set alphabet_list [split ${qfo::alphabet_c} ""]
        set k 0
        set group $group_letter
        while { ( $group eq "" || $group in $groups_used_list \
                      || !($group in $alphabet_list) ) && $k < 53 } {
            set group [lrange $alphabet_list $k $k]
            incr k
        }
        if { $k > 51 || $group eq "" } {
            ns_log Error "qfo::form_list_def_to_css_table_rows.1811 Ran out of group letters. used: '${groups_used_list}' k '${k}' group '${group}'."
            # something must be wrong. There must be a better way
            # to do what the page developer wants to accomplish with rows
            # on a page.
            ad_script_abort
        }
        
        set elements_new_lol [list ]
        set qfo_ct_c "qfo_ct_"

        for {set i 1} {$i <= $rows_count} {incr i} {
            set column_ct 0
            
            foreach element_nvl $elements_lol {
                set column [string range $qfo::alphabet_c $column_ct $column_ct]
                # convert list to array
                # array set e_arr $element_nvl,
                # except convert names to lowercase
                set n_list [list ]
                foreach {n v} $element_nvl {
                    set nlc [string tolower $n]
                    lappend n_list $nlc
                    set v_arr(${nlc}) $v
                    set n_arr(${nlc}) $n
                }
                # change name's value by appending $group$column${i}
                #ns_log Notice "form_list_def_to_css_table_rows.1845 array get n_arr '[array get n_arr]'"
                #ns_log Notice "form_list_def_to_css_table_rows.1845 n_arr(${name_c}) '$n_arr(${name_c})' group '${group}' column '${column}' i '${i}' column_ct '${column_ct}'"

                append v_arr(${name_c}) "_" ${group} ${column} $i 

                # change back to list
                set element_new_nvl [list ]
                foreach n $n_list {
                    lappend element_new_nvl $n_arr(${n}) $v_arr(${n})
                }
                # unset arrays
                unset v_arr
                unset n_arr
                # append to new list
                lappend elements_new_lol $element_new_nvl
                incr column_ct
            }
        }
        # append a hidden table_name_count variable
        set name $qfo_ct_c
        append name ${group} ${column} ${rows_count}
        set rc_list [list type hidden name ${name} value ${rows_count} ]
        lappend elements_new_lol $rc_list
        #ns_log Notice "qfo::form_list_def_to_css_table_rows.1865: elements_new_lol '${elements_new_lol}'"
        set fldtctr_lol $elements_new_lol
    } else {
        set fldtctr_lol $elements_lol
    }
    if { $add_to_lol_p } {
        foreach f_list  $fldtctr_lol {
            lappend lol_name $f_list
        }
    }
    #ns_log Notice "qfo::form_list_def_to_css_table_rows.1921 fldtctr_lol '${fldtctr_lol}'"
    return $fldtctr_lol
}

ad_proc -public qal_3g {
    -fields_array:required
    {-fields_ordered_list ""}
    {-field_types_lists ""}
    {-inputs_as_array "qfi_arr"}
    {-form_submitted_p ""}
    {-form_id ""}
    {-doc_type ""}
    {-form_varname "form_m"}
    {-duplicate_key_check "0"}
    {-multiple_key_as_list "0"}
    {-hash_check "0"}
    {-post_only "0"}
    {-tabindex_start "1"}
    {-suppress_tabindex_p "1"}
    {-replace_datatype_tag_attributes_p "0"}
    {-write_p "1"}
} {
    Inputs essentially declare properties of a form and
    manages field type validation like qfo_2g, but with new features:

    1. capacity to handle 'scalared arrays' as names for multiple rows of sets
    of named form elements.  This allows clean handling of arrays in the
    context of form CGI by avoiding use of special characters which may be
    problematic in some contexts.
    <br><br>

    A 'scalared array' here means a scalar variable with a suffix
    number appened that represents an array index.  For example, if an input
    tag with the name's attribute set to 'foobar', and there are 3 rows
    of the input tag, then it would be represented with something like
    foobar_1, foobar_2, foobar_3. Actually, it would be foobar_aa1,
    foobar_aa2, foobar_aa3. The two letters before the number help
    with structuring the form on the page properly by putting the fields
    in the expected order. 

    <br><br>
    2. split 'form_varname'(s) for placing different parts of the output
    form html into different parts of a templated adp page.
    The developer assigns each input field a
    '<code>context</code>' and its value (name/value pair).
    The value of context is the form_varname that the associated form field
    html is assigned to.  In qfo_2g, the form output defaults to form_html.
    In qal_3g, uses the same parameter 'form_varname' with default form_m,
    but outputs the results in a series of variables. E.g. form_m1, form_m2,
    form_m3. where "form_m" is the value of attribute "context" supplied
    during form field defintion. If the context attribute is left out of any
    field, the default form_m is used.
    
    The field <code>context</code> attribute and its value determines
    which form context the form element is added to.
    Each 'context' value may be supplied as either a number or
    the form_varname with its number as a suffix.
    If no context is provided or the context sequence number is not
    supplied, the previous context is assumed based on TABINDEX order.
    The generated form fragments containing HTML markup language and
    are assigned to the form_varname with a numeric suffix.
    form_varname_open contains the open FORM tag.
    form_varname1 contains the first form fragment determined by context
    form_varname2 contains the second form fragment..
    form_varnameN contains the Nth form fragment
    form_varname_close contains the close FORM tag. This is supplied for
    consistency, but its value is constant.
    The first context contains open FORM tag. The last defined context includes
    the closed FORM tag.  <b>If there is no context provided, the context
    defaults to form_varname's value.
    <br><br>
    Each html form element (tag) can now have attributes "html_before" and
    "html_after", which inserts that html before and after.

    
    <br><br>

    <code>fields_array</code> is an <strong>array name</strong>. 
    A form element is for example, an INPUT tag.
    Values are name-value pairs representing attributes for form elements.
    Each indexed value is a list containing attribute/value pairs of form
    element. The form element tag is determined by the data type.
    <br><br>
    Each form element is expected to have a 'datatype' in the list, 
    unless special cases of 'choice' or 'choices' are used
    (and discussed later).
    'text' datatype is default.
    <br><br>

    For html <code>INPUT</code> tags, a 'value' element represents a
    default value for the form element.
    <br><br>

    For html <code>SELECT</code> tags and <code>INPUT</code> tags with
    <code>type</code> 'checkbox' or 'radio', the attribute <code>value</code>'s
    'value' is expected to be a list of lists consistent with 'value'
    attributed supplied to <code>qf_select</code>, <code>qf_choice</code> or
    <code>qf_choices</code>.
    <br><br>

    Special cases 'choice' and 'choices' are reprepresented by supplying
    an attribute <code>type</code> with value 'checkbox' or 'radio' or
    'select'. If 'select', a single value is assumed to be returned
    unless an attribute <code>multiple</code> is supplied with corresponding
    value set to '1'.
    Note: Supplying a name/value pair '<code>multiple</code> 0' is treated
    the same as not including a <code>multiple</code> attribute.
    <br><br>

    Form elements are displayed in order of attribute 'tabindex' values.
    Order defaults are supplied by <code>-fields_ordered_list</code> consisting
    of an ordered list of indexes from <code>fields_array</code>.
    Indexes omitted from list appear after ordered ones.
    Any element in list that is not an index in fields_array 
    is ignored with warning.
    Yet, <code>fields_ordered_list</code> is optional.
    When fields_ordered_list is empty, sequence is soley 
    in sequential order according to relative tabindex value.
    Actual tabindex value is calculated, so that a sequence is tabindex
    compliant. Supplied values can be integers (negative and positive).
    <br><br>

    <code>field_types_lists</code> is a list of lists 
    as defined by ::qdt::data_types parameter 
    <code>-local_data_types_lists</code>.
    See <code>::qdt::data_types</code> for usage.
    <br><br>

    <code>inputs_as_array</code> is an <strong>array name</strong>. 
    Array values follow convention of <code>qf_get_inputs_as_array</code>.
    If <code>qf_get_inputs_as_array</code> is called before calling this proc,
    supply the returned array name using this parameter.
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
    <br><br>

    Returns 1 if there is input, and the input is validated.
    Otherwise returns 0.
    If there are no fields, input is validated by default.
    <br><br>
    Note: Validation may be accomplished external to this proc 
    by outputing a user message such as via <code>util_user_message</code> 
    and redisplaying form instead of processing further.
    <br><br>
    Any field attribute, default value, tabindex, or datatype assigned
    via q-tables to the form takes precedence.
    <br><br>

    <code>duplicate_key_check</code>,<br>
    <code>multiple_key_as_list</code>,<br>
    <code>hash_check</code>, and <br>
    <code>post_only</code> see <code>qf_get_inputs_as_array</code>.

    <code>write_p</code> if write_p is 0,
    presents form as a list of uneditable information.
    <br><br>

    Note: fieldset tag is not implemented in this paradigm.
    <br><br>

    Note: qf_choices can determine use of type 'select' vs. 'checkbox' using
    just the existence of 'checkbox', anything else can safely be 
    interpreted to be a 'select multiple'.
    With qal_3g, differentiation is not so simple. 'select' may specify
    a single choice, or 'multiple' selections with same name.
    <br><br>

    Based on  qfo_2g
    <br><br>

    @see qdt::data_types
    @see util_user_message
    @see qf_get_inputs_as_array
    @see qfo::qtable_label_package_id
    @see qf_select
    @see qf_choice
    @see qf_choices
    @see qfo_2g
} {

    # Form fragments are not assigned to context names in order to maximize
    # portability of code and for consistency.

    # For forms that display an entire table, this is not the proc you seek.
    # A different proc needs to be made. Maybe something named like
    #   qss::3g and put in spreadsheet package.

    
    # Blend the field types according to significance:
    # qtables field types declarations may point to different ::qdt::data_types
    # fields_arr overrides ::qdt::data_types
    # ::qdt::data_types defaults in qdt_types_arr
    # Blending is largely done via features of called procs.

    # fieldset is not implemented in this paradigm, because
    # it adds too much complexity to the code for the benefit.
    # A question is, if there is a need for fieldset, maybe
    # there is a need for a separate input page?
    # qal_3g uses the OpenACS template system instead of fieldset
    # for grouping.

    # qfi = qf input
    # form_ml = form markup (usually in html starting with FORM tag)
    set error_p 0
    upvar 1 $fields_array fields_arr
    upvar 1 $inputs_as_array qfi_arr
    upvar 1 $form_varname form_m
    upvar 1 ${form_varname}_open form_m_open
    upvar 1 ${form_varname}_close form_m_close
    # upvar assignments like:  upvar 1 ${form_varname}N form_mN
    # are deferred until determined dynamically

    # To obtain page's doctype, if customized:
    upvar 1 doc doc
    # external doc array is used here
    set doctype [qf_doctype $doc_type]


    ::qdt::data_types -array_name qdt_types_arr \
        -local_data_types_lists $field_types_lists
    # set datatype "text_word"
    # ns_log Notice "qal_3g.245: array get qdt_types_arr(${datatype},form_tag_attrs) '[array get qdt_types_arr(${datatype},form_tag_attrs) ]' array get qdt_types_arr(${datatype},form_tag_type) '[array get qdt_types_arr(${datatype},form_tag_type) ]'"
    # ns_log Notice "qal_3g.246: array get qdt_types_arr text_word '[array get qdt_types_arr "text_word*"]'"
    # ns_log Notice "qal_3g.247: array get qdt_types_arr text* '[array get qdt_types_arr "text*"]'"



    set qfi_fields_list [array names fields_arr]
    set field_ct [llength $qfi_fields_list]
    # ns_log Notice "qal_3g.253: array get fields_arr '[array get fields_arr]'"
    #ns_log Notice "qal_3g.254: qfi_fields_list '${qfi_fields_list}'"

    ### qal_3g does not add rows etc.
    ### It only works with what it is given via
    ### input_form_array and form_array,
    ### which may be more than provided from form_array alone.
    ### It sees dynamically generated fields as static as everything else.
    ### So code only has to be changed to validate dynamically created fields.

    ### Allow dynamically generated fields (scalared arrays)
    ### Before we parse fields, adapt form_array ie form_arr to include the
    ### dynamically generated fields that are not in the default defintion.
    ### A filter process needs to retain these dynamically generated fields.
    ### How to identify the fields to process?
    ### $fcshtml_arr(${f_hash},${scalar_array_p_c}) is 1 if is a scalar_array
    ### suffix consists of delimiter "_" {group letter}{column letter}
    ### and natural number {row}.
    
    
    ### If dynamically generated fields are
    ### created in fields_array definition
    ### The only additional changes to code that needs to be made
    ### is adapting form_m to a set of contexts.

    ### Recognize row/column 'name' naming convention and
    ### generate css-based
    ### table (not an html table) with column headers
    ### titled with a standard row/column (rc) reference, and
    ### each input 'cell' labeled with an rc reference
    ### in the spirit of responsive html page design.

    ### Problem: The vertical sequence is determined by sort tabindex,
    ###    which messes with the row and column order.
    ### sort tabindex is this order: qfi_fields_sorted_list
    ### using f_hash values. We need to look at names..

    

    ### To put titles and cells in same horizontal sequence,
    ### look at the name suffix _{group letter}{col letter}{row}
    ###    ..but that doesn't work for qf_choices...
    ###
    ### qfo::form_list_def_to_array names the multiple choices 'multipleN'
    ### for the ones that don't have a single name, but that doesn't
    ### transfer to the form.. response. Does it need to? 
    ### We're building the form on response from form_array with hints
    ### about rows from qal_ct_{group} counts
    ### in either case, and if the
    ### multiple selection names are named accordingly, it's possible
    ### to validate the data, and also build a form using the mulipleN def.

    ### Well, those multiple cases are either checkboxes or
    ### multiple selects.. which don't really fit the 'row' paradigm UI,
    ### since they also accept multiple 'rows' or selections as inputs.
    ### So, let's ignore this case for now.
    ### Except, if f_hash=name, or multpleN, then.. f_hash could be used,
    ### because it is name, except when it's not, that's okay.
    ### We can still use a stored f_shash_{group}{column}{row} to build
    ### the form, and names from a form's post based on suffix to validate.
    
    

    ### Iterate through f_hashes to collect names
    ### Get the qal_ct_{group}{column count}{row count}
    ### The max rows and columns can be used to audit 
    ### field elements in repeatable rows
    ### and cross reference to f_hash
    ### to get context.
    ### re-order if necessary
    ### qfi_fields_sorted_list to qfi_sorted_grouped_list
    ### the tabindex of column1 row1 becomes most significant.
    ### the tabindex of column2 row1 becomes next most etc.
    ### then column1 row2..
    ### Assume qfi_fields_sorted_list already has done this
    ### a manual rendering of the code suggests as much.
    ### And any automatic re-calculating of tab indexing *should*
    ### retain the order, since, if any tabindex is included in the
    ### row elements, it will be applied to all the rows.
    ### This info is still needed to audit input,
    ### because the form definition only includes default count of rows
    ### when there may be more (or depending on UI/app), less.

    ### Instead of using fcshtml_arr,
    ### reference the group directly, so another array.

    # set defaults, repeated use of text etc.
    set context_c "context"
    set html_before_c "html_before"
    set html_after_c "html_after"
    set name_c "name"
    set scalar_array_p_c "scalar_array_p"
    ### Following used for repeat rows of fields, e.g. items on an invoice
    set column_c "column"
    set group_c "group"
    set f_hash_c "f_hash"
    set rows_c "rows"

    set qfo_ct_blob_c {qfo_ct_[a-z][a-z][1-9]*}
    #ns_log Notice "qal_3g.352 array get fields_arr '[array get fields_arr]'"

    
    set qfo_ct_fields_list [array names fields_arr ${qfo_ct_blob_c}]
    #ns_log Notice "qal_3g.356 working on '${qfo_ct_blob_c}' qfo_ct_fields_list '${qfo_ct_fields_list}'" 
    #ns_log Notice "qal_3g.357 fields_ordered_list '${fields_ordered_list}'"
    set reset_ct_p 0
    foreach f_hash $qfo_ct_fields_list {

        set f_list $fields_arr(${f_hash})
        set name_idx [lsearch -exact -nocase $f_list ${name_c}]
        incr name_idx
        set name [lindex $f_list $name_idx]
        if { [llength $name] > 1 } {
            ns_log Error "qal_3g:335 More than 1 name '${name}'. Not supported."
            ad_script_abort
        }
        
        set gcr_max [string range $name 7 end]
        set group [string range $gcr_max 0 0]
        set column [string range $gcr_max 1 1]
        set rows [string range $gcr_max 2 end]
        set col_nbr [string first $column $qfo::alphabet_c]
        ### These two can audit fields in input array to make sure
        ### there's not extra fields being added externally.
        set fg_arr(${group},${column_c}) $column
        set fg_arr(${group},${rows_c}) $rows
        ### cross ref. to f_hash, so we can get datatype, context etc.
        set fg_arr(${group},${column},${f_hash_c}) $f_hash

        ### Do all fields already exist?
        ### check for input via form.
        if { [info exists qfi_arr(${name}) ] } {
            set v $qfi_arr(${name})
            if { ![qf_is_natural_number $v] } {
                ns_log Warning "qal_3g.387. name '${name}'s value not a number: '${v}'"
                set v $rows               
            }
            
            set diff [expr { $v - $rows } ]
            if { $diff > 0 } {
                ### add this many ($diff) rows using the first as a reference.

                ### get existing first field f_hash
                set reset_ct_p 1
                set tgf_hash [array names fields_arr "*_${group}a1"]
                if { [llength $tgf_hash ] ne 1 } {
                    nslog Error "qal_3g.399. tgf_hash '${tgf_hash}'. There should be one."
                    ad_script_abort
                }
                set f_list $fields_arr(${tgf_hash})
                set tgf_name_idx [lsearch $tfg_list ${name_c}]
                incr tgf_name_idx
                set tgf_name [lindex $tgf_list $tfg_name_idx ]
                set name_base [string range $tgf_name 0 end-2]
                ### name_base looks like 'some_name_g'
                set row_start $rows
                incr row_start
                set row_end $rows
                incr row_end $diff
                set f_hash_new_list [list ]
                for {set r $row_start} {$r <= $row_end} {incr r} {
                    ### make new name and f_hash
                    ### do for each column
                    
                    for {set c 1} { $c <= $column} {incr c } {
                        set col [string range $qfo::alphabet_c $c $c]
                        set name_new $name_base
                        append name_new $group $col $r
                        ### add to field_arr (not qfi_arr)
                        ### new f_hash is same as name
                        lappend f_hash_new_list $name_new
                        set fields_arr(${name_new}) [lreplace $fields_arr(${tgf_hash}) $idx $idx $name_new]
                    }
                }
                if { [llength $fields_ordered_list] > 0 } {
                    ### edit the existing fields_ordered_list
                    ### insert the new f_hash in expected sequence
                    ### after last one in the sequence.
                    ### last one is $name_base $group $column $rows
                    set prior $name_base
                    append prior $group $column $rows
                    set prior_idx [lsearch -exact $fields_ordered_list $prior]
                    incr prior_idx

                    set fields_ordered_list [linsert $fields_ordered_list $prior_idx $f_hash_new_list]
                    #ns_log Notice "qal_3g.438 fields_ordered_list '${fields_ordered_list}'"
                }

            }
        }
    }
    #ns_log Notice "qal_3g.444 qfi_fields_list '${qfi_fields_list}'"
    if { $reset_ct_p } {
        set qfi_fields_list [array names fields_arr]
        set field_ct [llength $qfi_fields_list]
        #ns_log Notice "qal_3g.448 reset qfi_fields_list '${qfi_fields_list}'"
    }

    ### setup any contexts
    ### upvar must be called for each form_varnameN form_mN *before*
    ### assigning values to form_mN
    ### get context and scalar_array_p from:
    ###  fcshtml_arr(${f_hash},${scalar_array_p_c})


    #ns_log Notice "qal_3g.458 array get fields_arr '[array get fields_arr]'"
    
    foreach f_hash $qfi_fields_list {
        ### extract group feature, highest priority field html tag attributes
        set field_nvl $fields_arr(${f_hash})
        set field_new_nvl [list ]
        set fcshtml_arr(${f_hash},${context_c}) ""
        set fcshtml_arr(${f_hash},${scalar_array_p_c}) 0
        set fcshtml_arr(${f_hash},${html_before_c}) ""
        set fcshtml_arr(${f_hash},${html_after_c}) ""
        foreach {n v} $field_nvl {
            set nlc [string tolower $n]
            
            ###  Extract 'context' and 'scalar_array_p'
            ###  into a new array fcshtml_arr with same index so as to avoid
            ###  needing to modify existing, working logic
            ###  because these attributes were not in qfo_2g.
            switch -exact -- $nlc {
                context {
                    #ns_log Notice "qal_3g.477 nlc '${nlc}' v '${v}'"
                    set fcshtml_arr(${f_hash},${context_c}) $v
                }
                scalar_array_p {
                    set fcshtml_arr(${f_hash},${scalar_array_p_c}) $v
                }
                html_before {
                    set fcshtml_arr(${f_hash},${html_before_c}) $v
                }
                html_after {
                    set fcshtml_arr(${f_hash},${html_after_c}) $v
                }
                default {
                    lappend field_new_nvl $n $v
                }
            }
        }
        #ns_log Notice "qal_3g.494 should have context: fcshtml_arr(${f_hash},${context_c}) '$fcshtml_arr(${f_hash},${context_c})' field_new_nvl '${field_new_nvl}'"
        set fields_arr(${f_hash}) $field_new_nvl
    }
    
    #ns_log Notice "qal_3g.498 array get fields_arr '[array get fields_arr]'"


    
    ### count contexts, create upvar links for them.
    set context_ct 1
    set context_prev ""
    set one_digit {[1-9]}
    set two_digits {[1-9][0-9]}
    foreach f_hash $fields_ordered_list {
        ### Every html element should have a 'context' attribute
        ### in fcshtml_arr, but not in fields_arr.
        ### If not, add one.
        if { [info exists fcshtml_arr(${f_hash},${context_c}) ] } {
            set context $fcshtml_arr(${f_hash},${context_c})
        } else {
            #ns_log Notice "qal_3g.516 no context attr found for f_hash '${f_hash}'"
            set fcshtml_arr(${f_hash},${context_c}) ""
        }
        
        set fvarn_len [string length $form_varname]
        ### avoid form_varname / form_m mixup.
        ### Here we just want the name of form_m
        set fvarn $form_varname
        # switch doesn't accept variables for the cases, so
        # using if statements.
        #ns_log Notice "qal_3g.524 fvarn '${fvarn}'"
        if { [string match "${fvarn}${two_digits}" $context] || [string match "${fvarn}${one_digit}" $context] } {
            # in good form. Leave as is.
            # Assumes there are less than 9999 contexts on a page.
            # update context_ct
            set context_new $context
            set context_ct [string range $context $fvarn_len end]
        } elseif { [string match "*${two_digits}" $context] || [string match "*${one_digit}" $context ] } {
            # There's a number there,
            # and maybe nothing else, or maybe a spelling
            # issue. Use the number..
            # update context_ct to the same.
            #ns_log Notice "qal_3g.540: context '${context}' not \
            #    recognized for f_hash '${f_hash}' form_id '${form_id}'"
            regexp -- {^[^0-9]*([0-9]+)$} $context context_ct
            set context_new $fvarn
            append context_new $context_ct
        } elseif { $context_prev ne "" } {
            # No recognizable context assigned.
            # Assign the same as the last context, or the first
            # if no previous ones.
            set context_new $context_prev
            #ns_log Notice "qal_3g.548 Using previous context."
        } else {
            set context_new $fvarn
            append context_new $context_ct
            #ns_log Notice "qal_3g.552 Creating new context '${context_new}'"
        }
        #ns_log Notice "qal_3g.553 context '${context}' -> context_new '${context_new}'"
        ### Create the upvar link before the context is used.
        if { ![info exists ${context_new} ] } {
            #ns_log Notice "qal_3g.557: creating context '${context_new}' for form_varname/fvarn '${fvarn}'"
            upvar 1 $context_new $context_new
            ### give it a value to make sure it exists.
            ### Note: context_new is not reset to "" here
            ### set $context_new ""
        }
        #ns_log Notice "qal_3g.563 f_hash '${f_hash}'  context '${context_new}'"
        set fcshtml_larr(${f_hash},${context_c}) $context_new
        set context_prev $context_new

    }



    # Create a field attributes array
    
    # Do not assume field index is same as attribute 'name's value.
    # Ideally, this list is the names used for inputs. 
    # Yet, this pattern breaks for 'input checkbox' (not 'select multiple'),
    # where names are defined in the supplied value list of lists.
    # How to handle?  These cases should be defined uniquely,
    # using available data, so attribute 'id' if it exists,
    # and parsed via a flag identifing their variation from using 'name'.

    # fatts = field attributes
    # fatts_arr(label,qdt::data_types.fieldname)
    # qdt::data_types fieldnames:
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

    # $fatts_arr(${f_hash},names) lists the name (or names in the case of
    # multiple associated with form element) associated with f_hash.
    # This is a f_hash <--> name map, 
    # where name is a list of 1 or more form elements.

    
    ###context and scalared_array_p break this paradigm. Need to add in...

    
    set fields_ordered_list_len [llength $fields_ordered_list]
    if { $fields_ordered_list_len == $field_ct } {
        # tabindexes have already been supplied for all cases
        set calculate_tabindex_p 0
    } else {
        set calculate_tabindex_p 1
    }
    #ns_log Notice "qal_3g calculate_tabindex_p '${calculate_tabindex_p}'"
    # Make a list of available datatypes
    # Html SELECT tags, and
    # INPUT tag with attribute type=radio or type=checkbox
    # present a discrete list, which is a
    # set of specific data choices.

    # To validate against one (or more in case of MULTIPLE) SELECT choices
    # either the choices must be rolled into a standardized validation proc
    # such as a 'qf_days_of_week' or provide the choices in a list, which
    # is required to build a form anyway.
    #  So, a special datatype is needed for two dynamic cases:
    #  select one / choice, such as for qf_choice
    #  select multiple / choices, such as for qf_choices
    # To be consistent, provide for cases when:
    #   1. qf_choice or qf_choices is used.
    #   2. INPUT (type checkbox or select) or SELECT tags are directly used.
    #   Case 2 does not fit this automated paradigm, so can ignore
    # for this proc. Yet, must still be considered in context of validation.
    # The api is already designed for handling case 2.
    # This proc uses qf_choice/choices paradigm, 
    # so special datatype handling is acceptable here, even if 
    # not part of q-data-types.
    # Name datatypes: choice, choices?
    # No, because what if there are multiple sets of choices?
    # name is unique, so:
    # datatype is name. Name collision is avoided by using
    # a separate array to store what are essentially custom lists.

    set button_c "button"
    set comma_c ","
    set datatype_c "datatype"
    set disabled_c "disabled"
    set form_tag_attrs_c "form_tag_attrs"
    set form_tag_type_c "form_tag_type"
    set hidden_c "hidden"
    set input_c "input"
    set label_c "label"
    set multiple_c "multiple"
    #set name_c "name"
    set select_c "select"
    set submit_c "submit"
    set tabindex_c "tabindex"
    set text_c "text"
    set type_c "type"
    set value_c "value"
    set title_c "title"
    set ignore_list [list $submit_c $button_c $hidden_c]

    ### Adding form element/tag attributes
    ### to allow breaking a form up into multiple html segments
    ### at the page level via 'context', and within each segment
    ### for use in responsive page design (and traditional templating).

    # Array for holding datatype 'sets' defined by select/choice/choices:
    # fchoices_larr(element_name)

    set data_type_existing_list [list]
    foreach n [array names qdt_types_arr "*,label"] {
        lappend data_type_existing_list [string range $n 0 end-6]
    }

    # Make a list of datatype elements
    # These are the same as in list qdt::data_types.fieldname listed above.
    set datatype_dummy [lindex $data_type_existing_list 0]
    set datatype_elements_list [list]
    set datatype_dummy_len [string length $datatype_dummy]
    foreach n [array names qdt_types_arr "${datatype_dummy},*"] {
        lappend datatype_elements_list [string range $n $datatype_dummy_len+1 end]
    }
    #ns_log Notice "qal_3g.690: datatype_elements_list '${datatype_elements_list}'"
    # datatype_elements are:
    #   label xml_format  default_proc  tcl_format_str  tcl_type
    #   tcl_clock_format_str  abbrev_proc  valida_proc  input_hint  max_length
    #   css_abbrev empty_allowed_p  html_style  text_format_proc  css_span
    #   form_tag_attrs  css_div  form_tag_type  filter_proc

    
    # Determine adjustments to be applied to tabindex values
    set tabindex_adj $fields_ordered_list_len
    set tabindex_tail [expr { $fields_ordered_list_len + $field_ct } ]

    #
    # Parse form fields
    #

    
    # Build dataset validation and make a form

    # Make a list of datatype elements that are not made during next loop
    # remaining_datatype_elements
    
    # element "datatype" already exists, skip that loop.
    # element "form_tag_attrs" already exists, skip that in loop also.
    set dedt_idx [lsearch -exact $datatype_elements_list $datatype_c]
    set ftat_idx [lsearch -exact $datatype_elements_list $form_tag_attrs_c]
    # e = element
    # Remove from list, the last case first so that existing index values work
    set remaining_datatype_elements_list $datatype_elements_list
    if { $dedt_idx > $ftat_idx } {
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $dedt_idx $dedt_idx]
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $ftat_idx $ftat_idx]
    } else {
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $ftat_idx $ftat_idx]
        set remaining_datatype_elements_list [lreplace $remaining_datatype_elements_list $dedt_idx $dedt_idx]
    }

    # default tag_type
    # tag_type is the html tag (aka element) used in the form.
    # Note: 'tag' is an attribute of 'tag_type', even though
    # nomenclature suggests the opposite.  This is because
    # tag_type and other factors ultimately determine the tag used.
    set default_type $text_c
    set default_tag_type "input"

    # $f_hash is field_index not field name.
    # The following loop standardizes element input data that does not
    # depend on values of prior element.
    foreach f_hash $qfi_fields_list {
        #ns_log Notice "qal_3g.739  f_hash: '${f_hash}'"

        #
        # This loop fills fatts_arr(${f_hash},${datatype_element})
        #
        
        # Additionally,
        # fatts_arr(${f_hash},names) lists the name (or names in the case of
        # multiple associated with form element) associated with f_hash.
        # This is a f_hash <--> name map, 
        # where name is a list of 1 or more form elements.

        # fatts_arr(${f_hash},$attr) could reference just the custom values
        # but then double pointing against the default datatype values
        # pushes complexity to later on.
        # Is lowest burden to get datatype first, load defaults,
        # then overwrite values supplied with field?  Yes.
        # What if case is a table with 100+ fields with same type?
        # Doesn't matter, if every $f_hash and $attr will be referenced:
        # A proc could be called that caches, with parameters:
        # $f_hash and $attr, yet that is slower than just filling the array
        # to begin with, since every $f_hash will be referenced.

        # The following logical split of datatype handling
        # should not rely on a datatype value,
        # which is a proc-based artificial requirement,
        # but instead rely on value of tag_type.

        # If there is no tag_type and no form_tag_type, the default is 'text'
        # which then requires a datatype that defaults to 'text'.
        # The value is used to branch at various points in code,
        # so add an index with a logical value to speed up
        # parsing at these logical branches:  is_datatyped_p
        

        #ns_log Notice "qal_3g.774 array get hfv_arr '[array get hfv_arr]'"

        set tag_type ""
        set datatype ""

        set field_nvl $fields_arr(${f_hash})        
        foreach {n v} $field_nvl {
            set nlc [string tolower $n]
            set hfv_arr(${nlc}) $v
            set hfn_arr(${nlc}) $n
        }

        if { [info exists hfv_arr(${datatype_c}) ] } {
            # This field is partly defined by using datatype
            set datatype $hfv_arr(${datatype_c})

            #ns_log Notice "qal_3g.7382: qdt_types_arr(${datatype},form_tag_attrs) '$qdt_types_arr(${datatype},form_tag_attrs)' qdt_types_arr(${datatype},form_tag_type) '$qdt_types_arr(${datatype},form_tag_type)'"

            set dt_idx $datatype
            append dt_idx $comma_c $form_tag_type_c
            set tag_type $qdt_types_arr(${dt_idx})

            set dta_idx $datatype
            append dta_idx $comma_c $form_tag_attrs_c
            foreach {n v} $qdt_types_arr(${dta_idx}) {
                set nlc [string tolower $n ]
                set hfv_arr(${nlc}) $v
                set hfn_arr(${nlc}) $n
            }
            #ns_log Notice "qal_3g.795. array get hfv_arr '[array get hfv_arr]' datatype '${datatype}' tag_type '${tag_type}'"
        } 

        # tag attributes provided from field definition
        if { $replace_datatype_tag_attributes_p \
                 && [array exists hfv_arr ] } {
            array unset hfv_arr
            array unset hfn_arr
        }
        # Overwrite anything introduced by datatype reference

        foreach {n v} $field_nvl {
            set nlc [string tolower $n]
            set hfv_arr(${nlc}) $v
            set hfn_arr(${nlc}) $n
            
        }
        #ns_log Notice "qal_3g.812. array get hfv_arr '[array get hfv_arr]'"
        # Warning: Variable nomenclature near collision:
        # "datatype,tag_type"  refers to attribute 'type's value,
        # such as types of INPUT tags, 'hidden', 'text', etc.
        #
        # Var $tag_type refers to qdt_data_types.form_tag_type ie element
        if { [info exists hfv_arr(type) ] && $hfv_arr(type) ne "" } {
            set fatts_arr(${f_hash},tag_type) $hfv_arr(type)
        }
        if { $tag_type eq "" && $datatype ne "" } {
            set tag_type $fatts_arr(${f_hash},form_tag_type)
        }
        if { $tag_type eq "" } {
            # Let's try to guess tag_type
            if { [info exists hfv_arr(rows) ] \
                     || [info exists hfv_arr(cols) ] } {
                set tag_type "textarea"
            } else {
                set tag_type $default_tag_type
            }
        }
        #ns_log Notice "qal_3g.833 datatype '${datatype}' tag_type '${tag_type}'"
        set multiple_names_p ""
        if { ( [string match -nocase "*input*" $tag_type ] \
                   || $tag_type eq "" ) \
                 && [info exists hfv_arr(type) ] } {
            set type $hfv_arr(type)
            #set fatts_arr(${f_hash},tag_type) $type
            # ns_log Notice "qal_3g.840: type '${type}'"
            switch -exact -nocase -- $type {
                select {
                    if { [info exists hfv_arr(multiple) ] } {
                        set multiple_names_p 1
                        # Technically, 'select multiple' case is still one
                        # name, yet multiple values posted.
                        # This case is handled in the context
                        # of multiple_names_p, essentially as a subset
                        # of 'input checkbox' since names supplied
                        # with inputs *could* be the same.
                    } else {
                        set multiple_names_p 0
                    } 
                    set fatts_arr(${f_hash},is_datatyped_p) 0
                    set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p
                }
                radio {
                    set multiple_names_p 0
                    set fatts_arr(${f_hash},is_datatyped_p) 0
                    set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p
                }
                checkbox {
                    set multiple_names_p 1
                    set fatts_arr(${f_hash},is_datatyped_p) 0
                    set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p
                }
                email -
                file {
                    # These can pass multiple values in html5.
                    # Still should be able to be validated.
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                }
                button -
                color -
                date -
                datetime-local -
                hidden -
                image -
                month -
                number -
                password -
                range -
                reset -
                search -
                submit -
                tel -
                text -
                time -
                url -
                week {
                    # Checking attribute against doctype occurs later
                    # in qf_* procs.
                    # 'type' is recognized
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                }
                default {
                    ns_log Notice "qal_3g.897: field '${f_hash}' \
 attribute 'type' '${type}' for 'input' tag not recognized. \
 Setting 'type' to '${default_type}'"
                    # type set to defaut_type
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                    set hfv_arr(type) $default_type
                }
            }

            if { $fatts_arr(${f_hash},is_datatyped_p) } {
                # If there is no label, add one.
                if { ![info exists hfv_arr(label)] \
                         && [lsearch -exact $ignore_list $type] == -1 } {
                    #ns_log Notice "qal_3g.910 array get hfv_arr '[array get hfv_arr]'"
                    set hfv_arr(${label_c}) $hfv_arr(${name_c})
                    set hfn_arr(${label_c}) $label_c
                }
            }

            if { [string match {*_[a-z][a-z]*[02-9]} $hfv_arr(${name_c}) ] } {
                ### suppress labels on rows 2 through 9
                ### keep labels for 1 11 21 etc.
                set hfv_arr(${label_c}) ""
                set hfn_arr(${label_c}) $label_c
            }

        } elseif { [string match -nocase "*textarea*" $tag_type ] } {
            set fatts_arr(${f_hash},is_datatyped_p) 1
        } elseif  { [string match -nocase "*input*" $tag_type ] } {
            set fatts_arr(${f_hash},is_datatyped_p) 1
        } else {
            ns_log Warning "qal_3g.919: field '${f_hash}' \
 tag '${tag_type}' not recognized. Setting to '${default_tag_type}'"
            set tag_type $default_tag_type
            set fatts_arr(${f_hash},is_datatyped_p) 1
        } 
        set fatts_arr(${f_hash},multiple_names_p) $multiple_names_p

        if { $fatts_arr(${f_hash},is_datatyped_p) } {
            
            if { [info exists hfv_arr(datatype) ] } {
                set datatype $hfv_arr(datatype)
                set fatts_arr(${f_hash},${datatype_c}) $datatype
            } else {
                set datatype $text_c
                set fatts_arr(${f_hash},${datatype_c}) $text_c
            }
            #ns_log Notice "qal_3g.935: datatype '${datatype}'"
            set name $hfv_arr(name)
            set fatts_arr(${f_hash},names) $name

        } else {

            # When fatts_arr($f_hash,datatype), is not created,
            # validation checks the set of elements in
            # fchoices_larr(form_name) list of choice1 choice2 choice3..

            # This may be a qf_select/qf_choice/qf_choices field.
            # Make and set the datatype using array fchoices_larr
            # No need to validate entry here.
            # Entry is validated when making markup language for form.
            # Just setup to validate input from form post/get.

            # Define choice(s) datatype in fchoices_larr for validation.

            if { [info exists hfv_arr(value) ] } {
                set tag_value $hfv_arr(value)
                # Are choices treated differently than choice
                # for validation? No
                # Only difference is 'name' is same for all choices
                # with 'choice' and 'choices select', whereas
                # 'choices checkbox' has a different name for each choice.
                # For SELECT tag, need to know if 'has MULTIPLE' attribute
                # is set to know if  multiple input values are expected.

                if { [info exists hfv_arr(name) ] } {
                    set tag_name $hfv_arr(name)
                    lappend fatts_arr(${f_hash},names) $tag_name
                }

                
                foreach tag_v_list $tag_value {
                    # Consider uppercase/lowercase refs
                    foreach {n v} $tag_v_list {
                        set nlc [string tolower $n]
                        #set fn_arr($nlc) $n
                        set fv_arr(${nlc}) $v
                    }
                    if { [info exists fv_arr(value) ] } {
                        if { [info exists fv_arr(name)] } {
                            # Use lappend to collect validation values, 
                            # because the name may be the same, 
                            # just different value.
                            lappend fchoices_larr($fv_arr(name)) $fv_arr(value)
                            lappend fatts_arr(${f_hash},names) $fv_arr(name)
                        } else {
                            # use name from tag
                            lappend fchoices_larr(${tag_name}) $fv_arr(value)
                        }
                    }
                    array unset fv_arr
                    
                }
                
            } else {
                set error_p 1
                ns_log Error "qal_3g.994: value for field '${f_hash}' not found."
            }
        }
        

        if { !$error_p } {
            
            if { $fatts_arr(${f_hash},is_datatyped_p) } {

                lappend fields_w_datatypes_used_arr(${datatype}) $f_hash


                foreach e $remaining_datatype_elements_list {
                    # Set field data defaults according to datatype
                    set fatts_arr(${f_hash},${e}) $qdt_types_arr(${datatype},${e})
                    #ns_log Notice "qal_3g.1009 set fatts_arr(${f_hash},${e}) \
                        # '$qdt_types_arr(${datatype},${e})' (qdt_types_arr(${datatype},${e}))"
                }
            }


            if { $calculate_tabindex_p } {
                # Calculate relative tabindex
                set val [lsearch -exact $fields_ordered_list $f_hash]
                if { $val < 0 } {
                    set val $tabindex_tail
                    if { [info exists hfv_arr(tabindex) ] } {
                        if { [qf_is_integer $hfv_arr(tabindex) ] } {
                            set val [expr { $hfv_arr(tabindex) + $tabindex_adj } ]
                        } else {
                            ns_log Warning "qal_3g.1024: tabindex not integer \
 for  tabindex attribute of field '${f_hash}'. Value is '${val}'"
                        }
                    }
                }
                set fatts_arr(${f_hash},tabindex) $val
            }
            
            set new_field_nvl [list ]
            foreach nlc [array names hfn_arr] {
                lappend new_field_nvl $hfn_arr(${nlc}) $hfv_arr(${nlc})
            }
            
            set fatts_arr(${f_hash},form_tag_attrs) $new_field_nvl
            
        }
        #ns_log Notice "qal_3g.1040: array get fatts_arr '[array get fatts_arr]'"
        #ns_log Notice "qal_3g.1041: data_type_existing_list '${data_type_existing_list}'"
        
        array unset hfv_arr
        array unset hfn_arr
    }
    # end of foreach f_hash


    #
    # All the fields and datatypes are known.
    # Proceed with form building and UI stuff
    #

    # Collect only the field_types that are used, because
    # each set of datatypes could grow in number, slowing performance
    # as system grows in complexity etc.
    set datatypes_used_list [array names fields_w_datatypes_used_arr]

    #
    # field types are settled at this point
    #
    
    if { $form_submitted_p eq "" } {
        set form_submitted_p [qf_get_inputs_as_array qfi_arr \
                                  duplicate_key_check $duplicate_key_check \
                                  multiple_key_as_list $multiple_key_as_list \
                                  hash_check $hash_check \
                                  post_only $post_only ]
        #ns_log Notice "qal_3g.069 array get qfi_arr '[array get qfi_arr]'"
    } 




    # Make sure every qfi_arr(x) exists for each field
    # Fastest to just collect the most fine grained defaults of each field
    # into an array and then overwrite the array with qfi_arr
    # Except, we don't want any extraneous input inserted unexpectedly in code.
    
    #ns_log Notice "qal_3g.1080 form_submitted_p '${form_submitted_p}' array get qfi_arr '[array get qfi_arr]'"

    #ns_log Notice "qal_3g.1082 array get fields_arr '[array get fields_arr]'"


    # qfv = field value
    foreach f_hash $qfi_fields_list {
        # Some form elements have different defaults
        # that require more complex values: 
        # fieldtype is checkboxes, radio, or select.
        # Make sure they work here as expected ie:
        # Be consistent with qf_* api in passing field values

        # Overwrite defaults with any inputs
        foreach name $fatts_arr(${f_hash},names) {
            if { [info exists qfi_arr(${name})] } {
                set qfv_arr(${name}) $qfi_arr(${name})
            } 
            # Do not set default value if there isn't any value
            # These cases will be caught during validation further on.
        }
    } 



    # Don't use qfi_arr anymore, as it may contain extraneous input
    # Use qfv_arr for input array
    array unset qfi_arr




    ns_log Notice "qal_3g.1112 form_submitted_p '${form_submitted_p}' array get qfv_arr '[array get qfv_arr]'"
    # validate inputs?
    set validated_p 0
    set all_valid_p 1
    set valid_p 1
    set invalid_field_val_list [list ]
    set nonexisting_field_val_list [list ]
    set row_list [list ]
    if { $form_submitted_p } {

        #
        # validate inputs
        #
        
        ### Validate the scalar_array_p variables via glob? No and yes..
        ### Yes if there are more rows than defined in default form_array def.
        ### Each is statically defined, so the usual process works for default
        ### cases.
        ### New refs to handle dynamic rows:
        ### fcshtml_arr(${f_hash},${context_c})  provides group context
        ### fcshtml_arr(${f_hash},${scalar_array_p_c}) Q:a repeating row type?
        ### fcshtml_arr(${f_hash},${html_before_c}) Html to add before tag
        ### fcshtml_arr(${f_hash},${html_after_c}) Html to add after tag

        foreach f_hash $qfi_fields_list {

            #
            # validate.
            #
            
            #ns_log Notice "qal_3g.1142: f_hash '${f_hash}', datatype '${datatype}'"
            if { $fatts_arr(${f_hash},is_datatyped_p) } {
                # Do not set a name to exist here,
                # because then it might validate and provide
                # info different than the user submitted.

                if { [info exists fatts_arr(${f_hash},valida_proc)] } {
                    set name $fatts_arr(${f_hash},names)
                    # ns_log Notice "qal_3g.1150. Validating '${name}'"
                    if { [info exists qfv_arr(${name}) ] } {
                        set valid_p [qf_validate_input \
                                         -input $qfv_arr(${name}) \
                                         -proc_name $fatts_arr(${f_hash},valida_proc) \
                                         -form_tag_type $fatts_arr(${f_hash},form_tag_type) \
                                         -form_tag_attrs $fatts_arr(${f_hash},form_tag_attrs) \
                                         -empty_allowed_p $fatts_arr(${f_hash},empty_allowed_p) ]
                        if { !$valid_p } {
                            lappend invalid_field_val_list $f_hash
                        }
                    } else {
                        #ns_log Notice "qal_3g.1162. array get fatts_arr f_hash,* '[array get fatts_arr ${f_hash},*]'"
                        if { ![info exists fatts_arr(${f_hash},tag_type) ] || [lsearch -exact $ignore_list $fatts_arr(${f_hash},tag_type) ] == -1 } {
                            ns_log Notice "qal_3g.1164: field '${f_hash}' \
 no validation proc. found"
                        }
                    }
                } else {
                    lappend nonexsting_field_val_list $f_hash
                }

            } else {
                # not is_datatyped_p: type is select, checkbox, or radio input
                set valid_p 1
                set names_len [llength $fatts_arr(${f_hash},names)]
                set n_idx 0
                while { $n_idx < $names_len && $valid_p } {
                    set name $fatts_arr(${f_hash},names)
                    if { [info exists qfv_arr(${name}) ] } {
                        # check for type=select,checkbox, or radio
                        # qfv_arr may contain multiple values
                        foreach m $qfv_arr(${name}) {
                            set m_valid_p 1
                            if { [lsearch -exact $fchoices_larr(${name}) $m ] < 0 } {
                                # name exists, value not found
                                set m_valid_p 0
                                ns_log Notice "qal_3g.1187: name '${name}' \
 has not valid value '$qfv_arr(${name})'"
                            }
                            set valid_p [expr { $valid_p && $m_valid_p } ]
                        }
                    }
                    incr n_idx
                }
            }
            # keep track of each invalid field.
            set all_valid_p [expr { $all_valid_p && $valid_p } ]
        }
        set validated_p $all_valid_p
        #        ns_log Notice "qal_3g.1200: Form input validated_p '${validated_p}' \
            # invalid_field_val_list '${invalid_field_val_list}' \
            # nonexisting_field_val_list '${nonexisting_field_val_list}'"
    } else {
        # form not submitted
        
        # Populate form values with defaults if not provided otherwise
        foreach f_hash $qfi_fields_list {
            if { ![info exists fatts_arr(${f_hash},value) ] } {
                # A value was not provided by fields_arr
                if { $fatts_arr(${f_hash},is_datatyped_p) } {
                    set qfv_arr(${f_hash}) [qf_default_val $fatts_arr(${f_hash},default_proc) ]
                }
            }
        }
    }

    if { $validated_p } {
        # Which means form_submitted_p is 1 also.

        # put qfv_arr back into qfi_arr
        array set qfi_arr [array get qfv_arr]

    } else {
        # validated_p 0, form_submitted_p is 0 or 1.

        # generate form

        # Blend tabindex attributes, used to order html tags:
        # input, select, textarea. 
        # '1' is first tabindex value.
        # fields_ordered_list overrides original fields attributes.
        # Original is in fields_arr(name) nvlist.. element tabindex value,
        #  which converts to fatts_arr(name,tabindex) value (if exists).
        # Dynamic fatts (via q-tables)  overrides both, and is already handled.
        # Blending occurs by assigning a lower range value to each case,
        # then choosing the lowest value for each field.

        # Finally, a new sequence is generated to clean up any blending
        # or ommissions in sequence etc.
        if { $calculate_tabindex_p } {
            # Create a new qfi_fields_list, sorted according to tabindex
            set qfi_fields_tabindex_lists [list ]
            foreach f_hash $qfi_fields_list {

                set f_list [list $f_hash $fatts_arr(${f_hash},tabindex) $fatts_arr(${f_hash},names) ]
                lappend qfi_fields_tabindex_lists $f_list
            }
            ### subsort list by name's value in order using -dictionary
            ### keep scalar array rows in same sequence.
            set qfi_fields_name_sorted_lists [lsort -dictionary -index 2 \
                                                  $qfi_fields_tabindex_lists]
            set qfi_fields_tabindex_sorted_lists [lsort -integer -index 1 \
                                                      $qfi_fields_name_sorted_lists]
            set qfi_fields_sorted_list [list]
            foreach f_list $qfi_fields_tabindex_sorted_lists {
                lappend qfi_fields_sorted_list [lindex $f_list 0]
            }
            #ns_log Notice "qal_3g.1258. from qfi_fields_list sorted by tabindex..: qfi_fields_sorted_list '${qfi_fields_sorted_list}'"
        } else {
            set qfi_fields_sorted_list $fields_ordered_list
            #ns_log Notice "qal_3g.1260. from fields_ordered_list: qfi_fields_sorted_list '${qfi_fields_sorted_list}'"
        }

        
        # build form using qf_* api
        
        set form_m ""
        
        set form_id [qf_form form_id $form_id hash_check $hash_check]
        set form_m_open [qf_read form_id $form_id]
        #ns_log Notice "qal_3g.1271: form_m_open '${form_m_open}'"
        
        # Use qfi_fields_sorted_list to generate 
        # an ordered list of form elements

        if { !$validated_p && $form_submitted_p } {

            # Update form values to those provided by user.
            # That is, update value of 'value' attribute to one from qfv_arr
            # Add back the nonexistent cases that must carry a text value
            # for the form.

            #code
            # Highlight the fields that did not validate.
            # Add hints to title/other attributes.

            set selected_c "selected"
            foreach f_hash $qfi_fields_sorted_list {
                #ns_log Notice "qal_3g.1289. f_hash '${f_hash}'"
                set fatts_arr_index $f_hash
                append fatts_arr_index $comma_c $form_tag_attrs_c


                # Determine index of value attribute's value
                foreach {n v} $fatts_arr(${fatts_arr_index}) {
                    set nlc [string tolower $n]
                    set fav_arr(${nlc}) $v
                    set fan_arr(${nlc}) $n
                }


                if { $fatts_arr(${f_hash},is_datatyped_p) } {


                    if { [string match "*html*" $doctype ] } {
                        if { [lsearch -exact $invalid_field_val_list $f_hash] > -1 } {
                            # Error, tell user
                            set error_msg " <strong class=\"form-label-error\">"
                            append error_msg "#acs-tcl.lt_Problem_with_your_inp# <br> "
                            if { !$fatts_arr(${f_hash},empty_allowed_p) } {
                                append error_msg "<span class=\"form-error\"> "
                                append error_msg "#acs-templating.required#"
                                append error_msg "</span> "
                            }
                            append error_msg "#acs-templating.Format# "
                            append error_msg $fatts_arr(${f_hash},input_hint)
                            append error_msg "</strong> "
                            if { [info exists fav_arr(label) ] } {
                                append fav_arr(label) $error_msg
                            } else {
                                set fav_arr(title) $error_msg
                                set fan_arr(title) $title_c
                            }
                        } else {
                            if { ![info exists fav_arr(title) ] } {
                                set fav_arr(title) "#acs-templating.Format# "
                                append fav_arr(title) $fatts_arr(${f_hash},input_hint)
                                set fan_arr(title) $title_c 
                            }
                        }
                    }
                    

                    set n2 $fatts_arr(${f_hash},names)
                    if { [info exists qfv_arr(${n2}) ] } {
                        set v2 [qf_unquote $qfv_arr(${n2}) ]
                        if { $v2 ne "" \
                                 || ( $v2 eq "" \
                                          && $fatts_arr(${f_hash},empty_allowed_p) ) } {
                            # ns_log Notice "qal_3g.1340 n2 '${n2}' v2 '${v2}' qf# v_arr(${n2}) '$qfv_arr(${n2})'"
                            set fav_arr(value) $v2
                            if { ![info exists fan_arr(value) ] } {
                                set fan_arr(value) $value_c
                            }
                        }
                    } else {
                        # If there is a 'selected' attr, unselect it.
                        if { [info exists fav_arr(selected) ] } {
                            set fav_arr(selected) "0"
                        }
                    }

                    set fa_list [list ]
                    foreach nlc [array names fav_arr] {
                        lappend fa_list $fan_arr(${nlc}) $fav_arr(${nlc})
                    }
                    set fatts_arr(${fatts_arr_index}) $fa_list

                    # end has_datatype_p block

                } else { 
                    switch -exact -nocase -- $fatts_arr(${f_hash},tag_type) {
                        radio -
                        checkbox -
                        select {
                            # choice/choices name/values may not exist.
                            # qfo::lol_remake handles those cases also.
                            if { [info exists fav_arr(value) ] } {
                                set fatts_arr(${fatts_arr_index}) [::qfo::lol_remake \
                                                                       -attributes_name_array_name fan_arr \
                                                                       -attributes_value_array_name fav_arr \
                                                                       -is_multiple_p $fatts_arr(${f_hash},multiple_names_p) \
                                                                       -qfv_array_name qfv_arr ]
                                
                            }
                        }
                        default {
                            ns_log Warning "qal_3g.1378 tag_type '${tag_type}' \
 unexpected."
                        }
                        
                    }
                }
                array unset fav_arr
                array unset fan_arr
            }
        }

        # Every f_hash element has a value at this point..

        ### qfo_2g splits the logic here between write_p 0 and 1.
        ### We don't want to break the view with the complexity of
        ### the rendering, so write_p is checked for each tag, and disabled
        ### or the equivalent is added to the attributes.
        
        # build form
        set tabindex $tabindex_start
        
        foreach f_hash $qfi_fields_sorted_list {
            #ns_log Notice "qal_3g.1400. f_hash '${f_hash}'"
            set atts_list $fatts_arr(${f_hash},form_tag_attrs)
            foreach {n v} $atts_list {
                set nlc [string tolower $n]
                set attn_arr(${nlc}) $n
                set attv_arr(${nlc}) $v
            }
            set f_context $fcshtml_arr(${f_hash},${context_c})
            
            if { [info exists attv_arr(tabindex) ] } {
                if { $suppress_tabindex_p } {
                    unset attv_arr(tabindex)
                    unset attn_arr(tabindex)
                } else {
                    set attv_arr(tabindex) $tabindex
                }
            }

            set atts_list [list ]
            foreach nlc [array names attn_arr ] {
                lappend atts_list $attn_arr(${nlc}) $attv_arr(${nlc})
            }
            if { !$write_p } {
                lappend atts_list $disabled_c 1
            }
            array unset attn_arr
            array unset attv_arr
            
            ### add html before tag
            set html_b $fcshtml_arr(${f_hash},${html_before_c})
            if { $html_b ne "" } {
                #qf_append html $html_b
                append $f_context $html_b
            }
            
            if { $fatts_arr(${f_hash},is_datatyped_p) } {

                switch -exact -- $fatts_arr(${f_hash},form_tag_type) {
                    input {
                        #ns_log Notice "qal_3g.1439: qf_input \
                        ## fatts_arr(${f_hash},form_tag_attrs) '${atts_list}'"
                        append $f_context [qf_input $atts_list ]
                    }
                    textarea {
                        #ns_log Notice "qal_3g.1444: qf_textarea \
                        # fatts_arr(${f_hash},form_tag_attrs) '${atts_list}'"
                        append $f_context [qf_textarea $atts_list ]
                    }
                    default {
                        # this is not a form_tag_type
                        # tag attribute 'type' determines if this
                        # is checkbox, radio, select, or select/multiple
                        # This should not happen, because
                        # fatts_arr(${f_hash},is_datatyped_p) is false for 
                        # these cases.
                        ns_log Warning "qal_3g.1455: Unexpected form element: \
 f_hash '${f_hash}' ignored. \
 fatts_arr(${f_hash},form_tag_type) '$fatts_arr(${f_hash},form_tag_type)'"
                    }
                }
            } else {
                # choice/choices

                if { $fatts_arr(${f_hash},multiple_names_p) } {
                    append $f_context [qf_choices $atts_list ]
                } else {
                    append $f_context [qf_choice $atts_list ]
                }

            }

            ### add html after tag
            set html_a $fcshtml_arr(${f_hash},${html_after_c})
            if { $html_a ne "" } {
                #qf_append html $html_a
                append $f_context $html_a
            }
            
            incr tabindex
        }
        #qf_close form_id $form_id
        set form_m_close "</form>"
        append form_m [qf_read form_id $form_id]

    }    
    return $validated_p
}

