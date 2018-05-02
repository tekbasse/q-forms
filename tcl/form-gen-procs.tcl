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


ad_proc -private ::qfo::larr_replace {
    -array_name
    -index
    -attribute_name_index
    -new_value
} {
    Replaces the value in a name/value paired list that is indexed by 'index' 
    in array 'array_name'.
    Returns 1.
    This proc essentially breaks up a long line in to many, more legible ones.
} { 
    upvar 1 $array_name a_larr
    set i $attribute_name_index
    ns_log Notice "::qfo::larr_replace.69 ${array_name}(${index}) '$a_larr(${index})'"
    set a_larr(${index}) [lreplace $a_larr(${index}) $i+1 $i+1 $new_value]
    ns_log Notice "::qfo::larr_replace.71 ${array_name}(${index}) '$a_larr(${index})'"
    return 1
}

ad_proc -private ::qfo::lol_replace {
    -fatts_array_name
    -fatts_array_index
    -fatts_arr_list_index
    -is_multiple_p
    -qfv_array_name
} {
    <code>fatts_array_index</code> is the index of the array where the list is.
    <br><br>
    <code>fatts_arr_list_index</code> is the index of the attribute 'value' 
    in the list referenced by fatts_array_index.
    <br><br>

    Similar to <code>::qfo::larr_replace</code>
    except, instead of an array containing a list,
    the array contains a list, 
    where the target 'value' attribute is a list of lists.
    Replaces the values in a name/value paired list of lists
    that is indexed by 'fatts_array_index' 
    in array 'fatts_array_name'.
    Returns 1.
} { 
    upvar 1 $fatts_array_name fa_larr
    upvar 1 $fatts_array_index fa_index
    upvar 1 $qfv_array_name qfv_arr

    # The value's value is a list of name/value pair lists.
    set x $fatts_arr_list_index
    incr x
    set old_lol $fa_larr(${fatts_array_index})
    set old_val_lol [lindex $old_lol $x ]
    set new_val_lol [list ]
    set selected_c "selected"
    set name_c "name"
    set value_c "value"

    # get name from checkbox/select multiple attributes,
    set attributes_arr [array get $fa_larr(${fa_index}) ]
    set attributes_names_list [array names $attributes_arr]
    set att_names_idx [lsearch -exact -nocase $attributes_names_list ]
    if { $att_n_idx > -1 } {
        set att_n_idx [lindex $attribute_names_list $att_names_idx]
        set att_name_n $attributes_arr(${att_n_idx})
    }
    
    if { $is_multiple_p } {

        # this is a checkbox or select multiple tag configuration.

        # Not every name exists in qfv_arr

        # If name does not exist, 
        # use default value.. and
        # if there is a 'selected' attribute, set it to '0'

        # val = value, as in attribute 'value'
        foreach row_nvl $old_val_lol {
            array set row_arr $row_nvl
            # index may be upper or lower case
            # Use attribute 'value' as it is consistent for 
            # checkbox and select multiple cases.
            # 'name' is only required for checkbox input attributes.
            set n_list [array names row_arr]
            set value_idx [lsearch -exact -nocase $n_list $value_c ]

            # Does the input case exist? Or maybe this is a separator
            if { $value_idx > -1 } {
                set value_n [lindex $n_list $value_idx]

                set name_idx [lsearch -exact -nocase $n_list $name_c]
                if { $name_idx > -1 } {
                    #  input type checkbox
                    set name_n [lindex $n_list $name_idx]
                } elseif { $att_n_idx > -1 } {
                    #  input type select multiple
                    set name_n $att_name_n
                } 

                # Is qvf_arr(name) set to the value of this choice?
                set selected_p 0
                if { [info exists qfv_arr(${name_n}) ] } {
                    # unqoute qfv_arr first
                    set input_unquoted [qf_unquote $qfv_arr(${name_n}) ]
                    # Instead of checking only if input matches original
                    # check also if original is *in* input, because
                    # input may be a list of multiple inputs of same name.
                    if { $input_unquoted eq $row_arr(${value_n}) \
                             || [lsearch -exact $input_unquoted $row_arr(${value_n}) ] > -1 } {
                        set selected_p 1
                    }
                }
                # Is 'selected' an attribute in original declaration?
                set s_idx [lsearch -exact -nocase $n_list $selected_c]
                if { $s_idx > -1 } {
                    # found in original declaration
                    set new_row_nvl [lreplace $row_nvl $s_idx $s_idx $selected_p ]
                } elseif { $selected_p } {
                    set new_row_nvl $row_nvl
                    lappend new_row_nvl $selected_c $selected_p
                }

            } else {
                # selection must be a separator or the like.
                set new_row_nvl $row_nvl
            }
            lappend new_val_lol $new_row_nvl
        }

    } else {
        # Name is a part of tag attributes,
        # so there is only one name to check.

        # index may be upper or lower case
        if { $attn_n_idx > -1 } {

            set selected_count 0
            
            foreach row_nvl $old_val_lol {
                array set row_arr $row_nvl
                # index may be upper or lower case
                set n_list [array names row_arr]
                set value_idx [lsearch -exact -nocase $n_list $value_c ]
                if { $value_idx > -1 } {
                    # Does the input case exist?
                    set name_idx [lsearch -exact -nocase $n_list $name_c ]
                    set name_n [lindex $n_list $name_idx]
                    set selected_p 0
                    if { [info exists qfv_arr(${name_n}) ] } {
                        # unqoute qfv_arr first
                        set input_unquoted [qf_unquote $qfv_arr(${name_n}) ]
                        # Instead of checking only if input matches original
                        # check also if original is *in* input, because
                        # input may be a list of multiple inputs of same name
                        # intentional or not.
                        if { $input_unquoted eq $row_arr(${value_n}) \
                                 || [lsearch -exact $input_unquoted $row_arr(${value_n}) ] > -1 } {
                            incr selected_count
                            if { $selected_count < 2 } {
                                set selected_p 1
                            } else {
                                ns_log Warning "qfo_g2.215: Unexpected: \
 'selected' has multiple selected cases. \
 items for form element '${old_val_lol}', \
 specifically item '${row_nvl}'. Unselected."
                            }
                        } 
                    }
                    # Is 'selected' an attribute in original declaration?
                    set s_idx [lsearch -exact -nocase $n_list $selected_c]
                    if { $s_idx > -1 } {
                        # found in original declaration
                        set new_row_nvl [lreplace $row_nvl $s_idx $s_idx $selected_p ]
                    } else { $selected_p } {
                        set new_row_nvl $row_nvl
                        lappend new_row_nvl $selected_c $selected_p
                    }
                    
                } else {
                    # selection must be a separator or the like.
                    set new_row_nvl $row_nvl
                }
                lappend new_val_lol $new_row_nvl
            }
        }
    }
    if { [llength $new_val_lol ] > 0 } {
        # replace the default choice selections with the ones from input
        ns_log Notice "::qfo::lol_replace.194 ${fatts_array_name}(${fatts_array_index}) '$fa_larr(${fatts_array_index})'"
        set fa_larr(${fatts_array_index}) [lreplace $old_lol $x $x $new_val_lol]
        ns_log Notice "::qfo::lol_replace.196 ${fatts_array_name}(${fatts_array_index}) '$fa_larr(${fatts_array_index})'"
    } 
    # else, use defaults
    return 1
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
    <br><br>
    Note: fieldset tag is not implemented in this paradigm.
    <br><br>
    Note: qf_choices can determine use of type 'select' vs. 'checkbox' using
    just the existence of 'checkbox', anything else can safely be 
    interpreted to be a 'select multiple'.
    With qfo_g2, differentiation is not so simple. 'select' may specify
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
    ##ns_log Notice "qfo_2g.382: array get qdt_types_arr text* '[array get qdt_types_arr "text*"]'"
    if { $qtable_enabled_p } {
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


    ##ns_log Notice "qfo_2g.453: array get fields_arr '[array get fields_arr]'"
    ##ns_log Notice "qfo_2g.454: qfi_fields_list '${qfi_fields_list}'"
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


    set datatype_c "datatype"
    set tabindex_c "tabindex"
    set type_c "type"
    set select_c "select"
    set value_c "value"
    set name_c "name"
    set text_c "text"
    set multiple_c "multiple"
    set form_tag_attrs_c "form_tag_attrs"
    set comma_c ","

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
    ##ns_log Notice "qfo_2g.534: datatype_elements_list '${datatype_elements_list}'"

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
    set default_tag_type $text_c
    # Build dataset validation and making a form

    # make a list of datatype elements that are not made during next loop:
    # element "datatype" already exists, skip that loop:
    # element "form_tag_attrs" already exists, skip that in loop also.
    # e = element
    # Remove from list, last first to use existing index values.
    set e_list $datatype_elements_list
    if { $dedt_idx > $ftat_idx } {
        set e_list [lreplace $e_list $dedt_idx $dedt_idx]
        set e_list [lreplace $e_list $ftat_idx $ftat_idx]
    } else {
        set e_list [lreplace $e_list $ftat_idx $ftat_idx]
        set e_list [lreplace $e_list $dedt_idx $dedt_idx]
    }


    # $f_hash is field_index not field name.
    foreach f_hash $qfi_fields_list {

        set field_nvl $fields_arr(${f_hash})
        foreach {n v} $field_nvl {
            set nlc [string tolower $n]
            set hfv_arr(${nlc}) $v
            set hfn_arr(${nlc}) $n
        }


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
        # If there is no tag_type, the default is 'text'
        # which requires a datatype that defaults to 'text'.
        # The value is used to branch at various points in code,
        # so add an index with a logical value to speed up
        # parsing at these logical branches:  is_datatyped_p

        # default tag_type

        set tag_type $default_tag_type

        if { [info exists hfv_arr(type) ] } {
            set tag_type $hfv_arr(type)
            switch -exact -nocase -- $tag_type {
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
                    set multiple_names_p ""
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
                    # tag_type set to default_tag_type
                    set multiple_names_p ""
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                }
                default {
                    ns_log Notice "qfo_2g.635: field '${f_hash}' \
'type' attribute not recognized '${tag_type}'. Setting to 'text'"
                    # tag_type set to default_tag_type
                    set fatts_arr(${f_hash},is_datatyped_p) 1
                }
            }
            #set fatts_arr(${f_hash},tag_type) $tag_type
        } else {
            ns_log Notice "qfo_2g.642: field '${f_hash}' \
'type' attribute not found. Setting to 'text'"
            # tag_type set to default_tag_type
            #set fatts_arr(${f_hash},tag_type) $tag_type
            set fatts_arr(${f_hash},is_datatyped_p) 1
        }
        set fatts_arr(${f_hash},tag_type) $tag_type

        if { $fatts_arr(${f_hash},is_datatyped_p) } {
            
            if { [info exists hfv_arr(datatype) ] } {
                set datatype $hfv_arr(datatype)
                set fatts_arr(${f_hash},${datatype_c}) $datatype
            } else {
                set datatype $text_c
                set fatts_arr(${f_hash},${datatype_c}) $text_c
            }
            set name $hfv_arr(name)
            set fatts_arr(${f_hash},names) $name

            #  is from datatype form_tag_attrs
            array set temp_attrs_arr $qdt_types_arr(${datatype},form_tag_attrs)

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
                    #array set fc_arr $tag_v_list
                    # Re-written to consider uppercase/lowercase refs
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
                set dt $fatts_arr(${f_hash},datatype)
                lappend fields_w_datatypes_used_arr(${dt}) $f_hash


                foreach e $e_list {
                    # Set field data defaults according to datatype
                    set fatts_arr(${f_hash},${e}) $qdt_types_arr(${datatype},${e})
                    ##ns_log Notice "qfo_2g.733 set fatts_arr(${f_hash},${e}) \
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
                            ns_log Warning "qfo_2g.748: tabindex not integer \
 for  tabindex attribute of field '${f_hash}'. Value is '${val}'"
                        }
                    }
                }
                set fatts_arr(${f_hash},tabindex) $val
            }


        # Fill fatts_arr form_tag_attrs with any modifications 
        set new_field_nvl [list ]
        foreach nlc [array names hfn_arr] {
            lappend new_field_nvl $hfn_arr(${nlc}) $hfv_arr(${nlc})
        }
        set fatts_arr(${f_hash},form_tag_attrs) $new_field_nvl


        }
        ##ns_log Notice "qfo_2g.761: array get fatts_arr '[array get fatts_arr]'"
        ##ns_log Notice "qfo_2g.762: data_type_existing_list '${data_type_existing_list}'"

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
        ns_log Notice "##code array get qfi_arr '[array get qfi_arr]'"
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
    ns_log Notice "##code qfo_g2.903 form_submitted_p '${form_submitted_p}' array get qfi_arr '[array get qfi_arr]'"
#    ns_log Notice "##code qfo_g2.904 array get fatts_arr '[array get fatts_arr]'"
    ns_log Notice "##code qfo_g2.905 array get fields_arr '[array get fields_arr]'"

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
        ns_log Notice "##code qfo_g2.1018 form_submitted_p '${form_submitted_p}' array get qfv_arr '[array get qfv_arr]'"
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
            if { $fatts_arr(${f_hash},is_datatyped_p) } {
                # Do not set a name to exist here,
                # because then it might validate and provide
                # info different than the user submitted.

                if { [info exists fatts_arr(${f_hash},valida_proc)] } {
                    set name $fatts_arr(${f_hash},names)
                    ns_log Notice "qfo_g2.900. Validating '${name}'"
                    if { [info exists qfv_arr(${name}) ] } {
                        set valid_p [qf_validate_input \
                                         -input $qfv_arr(${name}) \
                                         -proc_name $fatts_arr(${f_hash},valida_proc) \
                                         -form_tag_type $fatts_arr(${f_hash},form_tag_type) \
                                         -form_tag_attrs $fatts_arr(${f_hash},form_tag_attrs) \
                                         -q_tables_enabled_p $qtable_enabled_p ]
                        if { !$valid_p } {
                            lappend invalid_field_val_list $f_hash
                        }
                    } else {
                        ns_log Notice "qfo_2g.870: field '${f_hash}' \
 no validation proc. found"
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
                                ns_log Notice "qfo_2g.886: name '${name}' \
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

    } else {
        # form not submitted

        # Populate form values with defaults if not provided otherwise
        foreach f_hash $qfi_fields_list {
            if { ![info exists fatts_arr(${f_hash},value) ] } {
                # A value was not provided by fields_arr
                if { $fatts_arr(${f_hash},is_datatyped_p) } {
                    set qfv_arr(${f_hash}) [qf_default_val $fatts_arr(${f_hash},default_proc) ]
                } else {
                    ns_log Warning "qfo_g2.1025: Form element '${f_hash}' \
 has no attribute 'value', and is not a datatype."
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

            set selected_c "selected"
            foreach f_hash $qfi_fields_sorted_list {
                set fatts_arr_index $f_hash
                append fatts_arr_index $comma_c $form_tag_attrs_c
                set value_idx [lsearch -exact -nocase \
                                   $fatts_arr(${fatts_arr_index}) \
                                   $value_c ]
                
                switch -exact -nocase -- $fatts_arr(${f_hash},tag_type) {
                    radio -
                    checkbox -
                    select {
                        # choice/choices name/values may not exist.
                        # qfo::lol_replace handles those cases also.
                        ::qfo::lol_replace \
                            -fatts_array_name fatts_arr \
                            -fatts_array_index $fatts_arr_index \
                            -fatts_arr_list_index $value_idx \
                            -is_multiple_p $fatts_arr(${f_hash},multiple_names_p) \
                            -qfv_array_name qfv_arr
                    }
                    default {
                        set index $f_hash
                        append index $comma_c $form_tag_attrs_c
                        set n2 $fatts_arr(${f_hash},names)
                        if { [info exists qfv_arr(${n2}) ] } {
                            set v2 [qf_unquote $qfv_arr(${n2}) ]
                            if { $v2 ne "" \
                                     || ( $v2 eq "" \
                                              && $fatts_arr(${f_hash},empty_allowed_p) ) } {
                                ns_log Notice "qo_g2.1021 n2 '${n2}' v2 '${v2}' qfv_arr(${n2}) '$qfv_arr(${n2})'"
                            
                                ::qfo::larr_replace \
                                    -array_name fatts_arr \
                                    -index $index \
                                    -attribute_name_index $value_idx \
                                    -new_value $v2
                            }
                        } else {
                            # If there is a 'selected' attr, unselect it.
                            array set v2_arr $fatts_arr(${index})
                            set v2_names_ul [array names v2_arr]
                            # s = selected
                            set s_idx [lsearch -exact -nocase $v2_names_ul $selected_c ]
                            if { $s_idx > -1 } {
                                set v2_name [lindex $v2_names_ul $s_idx]
                                set v2_arr(${v2_name}) "0"
                                set fatts_arr(${index}) [array get $v2_arr]
                            }
                            array unset v2_arr
                        }
                    }
                }
            }
        }

        # Every f_hash element has a value at this point..

        # build form
        set tabindex $tabindex_start
        foreach f_hash $qfi_fields_sorted_list {
            set atts_list $fatts_arr(${f_hash},form_tag_attrs)
            set tab_idx [lsearch -exact -nocase $atts_list $tabindex_c ]
            if { $tab_idx > -1 } {
                incr tab_idx
                set atts_list [lreplace $atts_list $tab_idx $tab_idx $tabindex ]
            } else {
                lappend atts_list $tabindex_c $tabindex
                ##ns_log Notice "qfo_2g.999: atts_list ${atts_list}"
            }
            if { $fatts_arr(${f_hash},is_datatyped_p) } {
                switch -- $fatts_arr(${f_hash},form_tag_type) {
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
        set form_m [qf_read form_id $form_id]
        
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
        ad_var_type_check_safefilename_p {
            set valid_p [ad_var_type_check_safefilename_p $input ]
        }
        qf_domain_name_valid_q {
            set valid_p [qf_domain_name_valid_q $input ]
        }
        ad_var_type_check_word_p {
            set valid_p [qf_ad_var_type_check_word_p $input]
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
                    ns_log Warning "qf_validate_input.1153: Broken UI. \
 Unknown validation proc '${proc_name}' proc_params_list '${proc_params_list}'"


                } else {
                    ns_log Notice "qf_validate_input.1158: processing safe_eval '${proc_params_list}'"
                    set valid_p [safe_eval $proc_params_list]
                }
            }
            if { !$allowed_p } {
                ns_log Warning "qf_validate_input.1230: Broken UI. \
 proc_name '${proc_name}' form_tag_type '${form_tag_type}' \
 form_tag_attrs '${form_tag_attrs}'"
            }
        }
    }    
    return $valid_p
}

ad_proc -private qfo_form_list_def_to_array {
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
                        ns_log Warning "qfo_form_list_def_to_array.1241: \
 No 'name' attribute found, and type '$v_arr(type)' \
 not of type 'checkbox' or 'select multiple' for element '${element_nvl}'"
                    }
                }
            }
        } else {
            if { !$ignore_parse_issues_p } {
                ns_log Warning "qfo_form_list_def_to_array.1249: \
 No 'name' or 'type' attribute found for element '${element_nvl}'"
            }
        }
        array unset v_arr
        array unset n_arr
    }
    ##ns_log Notice "qfo_form_list_def_to_array.1267: ${list_of_lists_name} '${elements_lol}'"
    ##ns_log Notice "qfo_form_list_def_to_array.1268: array get ${array_name} '[array get fields_arr ]'"
    return $fields_ordered_list
}
