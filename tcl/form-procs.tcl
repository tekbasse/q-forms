ad_library {

    routines for creating, managing input via html forms
    @creation-date 21 Nov 2010
    @cs-id $Id:
}

# use _ to clear a new default
# use upvar to grab previous defaults and re-use (with qf_input only)
# main namespace vars:
# __form_input_arr = array that contains existing form input and defaults, only one form can be posted at a time
# __form_ids_list  = list that contains existing form ids
# __form_ids_open_list = list that contains ids of forms that are not closed
# __form_ids_fieldset_open_list = list that contains form ids where a fieldset tag is open
# __form_arr contains an array of forms. Each form built as a string by appending tags, indexed by form_id, for example __form_arr($id)
# __qf_arr contains last attribute values of a tag (for all forms), indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
# a blank id passed in anything other than qf_form assumes the current (most recent used form_id)

# to fix:  id for nonform tag should not be same as form_id. use an attribute "form_id" for assigning tags to specific forms.

#use following to limit access to page requests via post.. to reduce vulnerability to url hack and insertion attacks from web:
#if { [ad_conn method] != POST } {
#  ad_script_abort
#}
#also see patch: http://openacs.org/forums/message-view?message_id=182057

# for early example and discussion, see http://openacs.org/forums/message-view?message_id=3602056

ad_proc -private qf_form_key_create {
    {key_id ""}
    {action_url "/"}
    {instance_id ""}
} {
    creates the form key for a more secure form transaction. Returns the security hash. See also qf_submit_key_accepted_p
} {
    # This proc is inspired from sec_random_token
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set time_sec [ns_time]
    if { [ad_conn -connected_p] } {
        set client_ip [ns_conn peeraddr]
        #        set request \[ad_conn request\]
        set secure_p [security::secure_conn_p]
        set start_clicks [ad_conn start_clicks]
        set session_id [ad_conn session_id]
        set action_url [ns_conn url]
 #       set render_timestamp $time_sec
    } else {
        set server_ip [ns_config ns/server/[ns_info server]/module/nssock Address]
        if { $server_ip eq "" } {
            set server_ip "127.0.0.1"
        }
        set client_ip $server_ip
        # time_sec s/b circa clock seconds
        #set request \[string range $time_sec \[expr { floor( ( \[ns_rand\] * \[string length $time_sec\] ) ) }\] end\]
        set secure_p [expr { floor( [ns_rand] + 0.5 ) } ]
        set start_clicks [expr { [int( [clock clicks] * [ns_rand] ) ] } ]
        set session_id [expr { floor( $time_sec / 4 ) } ]
#        set action_url "/"
#        set render_timestamp $time_sec
    }
    append sec_hash_string $start_clicks $session_id $secure_p $client_ip $action_url $time_sec
    set sec_hash [ns_sha1 $sec_hash_string]
    db_dml qf_form_key_create {insert into qf_key_map
                  (instance_id,rendered_timestamp,sec_hash,key_id,session_id,action_url,secure_conn_p,client_ip)
        values (:instance_id,:time_sec,:sec_hash,:key_id,:session_id,:action_url,:secure_p,:client_ip) }
    return $sec_hash
}

ad_proc -private qf_submit_key_accepted_p {
    {sec_hash ""}
    {instance_id ""}
} {
    Checks the form key against existing ones. Returns 1 if matches and unexpired, otherwise returns 0.
} {
    # This proc is inspired from sec_random_token
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set connected_p [ad_conn -connected_p]
    if { $connected_p } {
        set client_ip [ns_conn peeraddr]
        set secure_p [security::secure_conn_p]
        set session_id [ad_conn session_id]
        set action_url [ns_conn url]

    } else {
        set server_ip [ns_config ns/server/[ns_info server]/module/nssock Address]
        if { $server_ip eq "" } {
            set server_ip "127.0.0.1"
        }
        set client_ip $server_ip
        set secure_p ""
        set session_id ""
        set action_url [ns_conn url]
    }
    # the key_id is used to help generate unpredictable hashes, but isn't used at this level of input validation
    set accepted_p [db_0or1row qf_form_key_check_hash { 
        select session_id as session_id_i, action_url as action_url_i, secure_conn_p as secure_conn_p_i, client_ip as client_ip_i from qf_key_map
        where instance_id =:instance_id and sec_hash =:sec_hash and submit_timestamp is null } ]
    if { !$accepted_p } {
        # there is nothing to compare. log current values:
        ns_log Warning "qf_submit_key_accepted_p: is false. action_url '$action_url'"
        if { $connected_p } {
            ns_log Warning "qf_submit_key_accepted_p: session_id '$session_id' secure_conn_p '$secure_conn_p' client_ip '$client_ip'"
        }
    } else {
        # Mark the key expired
        set submit_timestamp [ns_time]
        db_dml qf_form_key_expire { update qf_key_map
            set submit_timestamp = :submit_timestamp where instance_id =:instance_id and sec_hash =:sec_hash and submit_timestamp is null }
    }
    return $accepted_p
}



ad_proc -public qf_get_inputs_as_array {
    {form_array_name "__form_input_arr"}
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
} {
    Get inputs from form submission, quotes all input values. Use ad_unquotehtml to unquote a value.
    Returns 1 if form inputs exist, otherwise returns 0.
    If duplicate_key_check is 1, checks if an existing key/value pair already exists, otherwise just overwrites existing value.  
    Overwriting is programmatically useful to overwrite preset defaults, for example.
} {
    # get args
    upvar 1 $form_array_name __form_input_arr
    set array __form_buffer_arr
    set arg_arr(duplicate_key_check) 0
    set arg_arr(multiple_key_as_list) 0
    set arg_arr(hash_check) 0
    set arg_full_list [list duplicate_key_check multiple_key_as_list hash_check]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 ]
    set args_list [list]
    foreach {name value} $arg_list {
        set arg_index [lsearch -exact $arg_full_list $name]
        if { $arg_index > -1 } {
            set arg_arr($name) $value
        } elseif { $value eq "" } {
            # ignore
        } else {
            ns_log Error "qf_get_inputs_as_array: $name is not a valid name invoked with name value pairs. Separate each with a space."
        }
    }

    # get form variables passed with connection
    set __form_input_exists 0
    set __form [ns_getform]
    if { $__form eq "" } {
        set __form_size 0
    } else {
        set __form_size [ns_set size $__form]
    }
    #ns_log Notice "qf_get_inputs_as_array: formsize $__form_size"
    for { set __form_counter_i 0 } { $__form_counter_i < $__form_size } { incr __form_counter_i } {

        regexp -nocase -- {^[a-z][a-z0-9_\.\:\(\)]*} [ns_set key $__form $__form_counter_i] __form_key
        # Why doesn't work for  regexp -nocase -- {^[a-z][a-z0-9_\.\:\(\)]*$ }    ?
        set __form_key_exists [info exists __form_key]
        # ns_log Notice "qf_get_inputs_as_array: __form_key_exists = ${__form_key_exists}"

        # no inserting tcl commands etc!
        if { $__form_key_exists == 0 || ( $__form_key_exists == 1 && [string length $__form_key] == 0 ) } {
            # let's make this an error for now, so we log any attempts
#            ns_log Notice "qf_get_inputs_as_array: __form_key_exists ${__form_key_exists} length __form_key [string length ${__form_key}]"
 #           ns_log Notice "qf_get_inputs_as_array(ref156: attempt to insert unallowed characters to user input '{__form_key}' as '[ns_set key $__form $__form_counter_i]' for counter ${__form_counter_i}."
            if { $__form_counter_i > 0 } {
                ns_log Notice "qf_get_inputs_as_array: attempt to insert unallowed characters to user input '{__form_key}'."
            }
        } else {
            set __form_key [ad_quotehtml $__form_key]
            # The name of the argument passed in the form
            # no legitimate argument should be affected by quoting:
    
            # This is the value
            set __form_input [ad_quotehtml [ns_set value $__form $__form_counter_i]]

            set __form_input_exists 1
            # check for duplicate key?
            if { $arg_arr(duplicate_key_check) && [info exists __form_buffer_arr($__form_key) ] } {
                if { $__form_input ne $__form_buffer_arr($__form_key) } {
                    # which one is correct? log error
                    ns_log Error "qf_get_form_input: form input error. duplcate key provided for ${__form_key}"
                    ad_script_abort
                    # set __form_input_exists to -1 instead of ad_script_abort?
                } else {
                    ns_log Warning "qf_get_form_input: notice, form has a duplicate key with multiple values containing same info.."
                }
            } elseif { $arg_arr(multiple_key_as_list) } {
                ns_log Notice "qf_get_inputs_as_array: A key has been posted with multible values. Values assigned to the key as a list."
                if { [llength $__form_buffer_arr($__form_key)] > 1 } {
                    # value is a list, lappend
                    lappend __form_buffer_arr($__form_key) $__form_input
                } else {
                    # convert the key value to a list
                    set __value_one $__form_buffer_arr($__form_key)
                    unset __form_buffer_arr($__form_key)
                    set __form_buffer_arr($__form_key) [list $__value_one $__form_input]
                }
            } else {
                set __form_buffer_arr($__form_key) $__form_input
#                ns_log Debug "qf_get_inputs_as_array: set ${form_array_name}($__form_key) '${__form_input}'."
            }

            # next key-value pair
        }
    }
    if { $arg_arr(hash_check) } {
        if { [info exists __form_buffer_arr(qf_security_hash) ] } {
            set accepted_p [qf_submit_key_accepted_p $__form_buffer_arr(qf_security_hash) ]
            if { $accepted_p } {
                unset __form_buffer_arr(qf_security_hash)
                array set __form_input_arr [array get __form_buffer_arr]
                return $__form_input_exists
            } else {
                ns_log Notice "qf_get_inputs_as_array: hash_check with form input of '$__form_buffer_arr(qf_security_hash)' did not match."
                return 0
            }
        } else {
            set accepted_p 0
            ns_log Notice "qf_get_inputs_as_array: hash_check requires qf_security_hash, but was not included with form input."
            return 0
        }
    } else {
        array set __form_input_arr [array get __form_buffer_arr]
        return $__form_input_exists
    }
}

ad_proc -public qf_remember_attributes {
    {arg1 "1"}
} {
    Changes qf_* form building procs to use the previous attributes and their values used with the last tag of same type (input,select,button etc) if arg1 is 1. 
} {
    upvar __qf_remember_attributes __qf_remember_attributes
    if { $arg1 eq 0 } {
        set __qf_remember_attributes 0
    } else {
        set __qf_remember_attributes 1
    }
}

ad_proc -public qf_form { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
} {
    Initiates a form with form tag and supplied attributes. Returns an id. A clumsy url based id is provided if not passed (not recommended). 
    If hash_check passed, creates a hash to be checked on submit for server-client transaction continuity.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __form_ids_open_list __form_ids_open_list
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_tag_list [list action class id method name style target title]
    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list form_id hash_check key_id
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute
            }
        } elseif { $value eq "" } {
            # ignore
        } else {
            ns_log Error "qf_form: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }
    if { ![info exists attributes_arr(method)] } {
        set attributes_arr(method) "post"
        lappend attributes_list "method"
    }
# if html5 should we default novalidate to novalidate? No for now.

    if { ![info exists __qf_remember_attributes] } {
        set __qf_remember_attributes 0
    }
    if { ![info exists __form_ids_list] } {
        set __form_ids_list [list]
    }
    if { ![info exists __form_ids_open_list] } {
        set __form_ids_open_list [list]
    }
    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(form_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(form_$attribute)
            }
        }
    }
    # every form gets a form_id
    set form_id_exists [info exists attributes_arr(form_id) ]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set id_exists [info exists attributes_arr(id) ]
        if { $id_exists == 0 || ( $id_exists == 1 && $attributes_arr(id) eq "" ) } { 
            regsub {/} [ad_conn url] {-} form_key
            append form_key "-[llength $__form_ids_list]"
        } else {
            # since a FORM id has to be unique, lets use it
            set form_key $attributes_arr(id)
        }
        set attributes_arr(form_id) $form_key
        ns_log Notice "qf_form: generating form_id $attributes_arr(form_id)"
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(form_$attribute) $attributes_arr($attribute)
        # if a form tag requires an attribute, the following test needs to  be forced true
        if { $attributes_arr($attribute) ne "" } {
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        }
    }
    
    set tag_html "<form[qf_insert_attributes $tag_attributes_list]>"
    # set results  __form_arr 
    append __form_arr($attributes_arr(form_id)) "$tag_html\n"
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        lappend __form_ids_list $attributes_arr(form_id)

    }
    if { [lsearch $__form_ids_open_list $attributes_arr(form_id)] == -1 } {
        lappend __form_ids_open_list $attributes_arr(form_id)
    }

    #  append an input tag for qf_security_hash?
    if { [info exists attributes_arr(hash_check)] && $attributes_arr(hash_check) eq 1 } {
        if { ![info exists attributes_arr(key_id) ] } {
            set attributes_arr(key_id) ""
        }
        set tag_html "<input[qf_insert_attributes [list type hidden name qf_security_hash value [qf_form_key_create $attributes_arr(key_id) $attributes_arr(action)]]]>"
        append __form_arr($attributes_arr(form_id)) "$tag_html\n"
        ns_log Notice "qf_form: adding $tag_html"
    }
    
    set __qf_arr(form_id) $attributes_arr(form_id)
    return $attributes_arr(form_id)
}


ad_proc -public qf_fieldset { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
} {
    Starts a form fieldset by appending a fieldset tag.  Fieldset closes when form is closed or another fieldset defined in same form.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_tag_list  [list align class id style title valign]
    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list form_id
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute
            }
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_fieldset: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_fieldset: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(fieldset_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(form_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(fieldset_$attribute) $attributes_arr($attribute)
        lappend tag_attributes_list $attribute $attributes_arr($attribute)
    }
    set tag_html ""
    set previous_fs 0
    # first close any existing fieldset tag with form_id
    set __fieldset_open_list_exists [info exists __form_ids_fieldset_open_list]
    if { $__fieldset_open_list_exists } {
        if { [lsearch $__form_ids_fieldset_open_list $attributes_arr(form_id)] > -1 } {
            append tag_html "</fieldset>\n"
            set previous_fs 1
        }
    }
    append tag_html "<fieldset[qf_insert_attributes $tag_attributes_list]>"

    # set results __form_ids_fieldset_open_list
    if { $previous_fs } {
        # no changes needed, "fieldset open" already indicated
    } else {
        if { $__fieldset_open_list_exists } {
            lappend __form_ids_fieldset_open_list $attributes_arr(form_id)
        } else {
            set __form_ids_fieldset_open_list [list $attributes_arr(form_id)]
        }
    }
    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) "$tag_html\n"
}

ad_proc -public qf_textarea { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
    {arg23 ""}
    {arg24 ""}
    {arg25 ""}
    {arg26 ""}
    {arg27 ""}
    {arg28 ""}
    {arg29 ""}
    {arg30 ""}
} {
    Creates a form textarea tag, supplying attributes where nonempty values are supplied.
    Attribute "label" places a label tag just before textarea tag, instead of wrapping around textarea
    in order to facilitate practical alignment variations between label and textarea. 
    To remove label tag, pass label attribute with empty string value.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_tag_list [list accesskey align class cols id name readonly rows style tabindex title wrap]
    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list value label form_id
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24 $arg25 $arg26 $arg27 $arg28 $arg29 $arg30]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            if { [lsearch -exact $attributes_tag_list $attribute ] > -1 } {
                lappend attributes_list $attribute
            }
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_textarea: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_textarea: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_textarea: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_textarea: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(textarea_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(textarea_$attribute)
            }
        }
    }

    # value defaults to blank
    if { ![info exists attributes_arr(value) ] } {
        set attributes_arr(value) ""
        lappend attributes_list "value"
    }

    # id defalts to form_id+name if label exists..
    if { [info exists attributes_arr(label)] && ![info exists attributes_arr(id)] && [info exists attributes_arr(name)] } {
        set attributes_arr(id) "${attributes_arr(form_id)}-${attributes_arr(name)}"
        lappend attributes_list id
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(textarea_$attribute) $attributes_arr($attribute)
        lappend tag_attributes_list $attribute $attributes_arr($attribute)
    }

    # by default, wrap the input with a label tag for better UI
    if { [info exists attributes_arr(id) ] && [info exists attributes_arr(label)] && $attributes_arr(label) ne "" } {
        set tag_html "<label for=\"${attributes_arr(id)}\">${attributes_arr(label)}</label><textarea[qf_insert_attributes $tag_attributes_list]>${attributes_arr(value)}</textarea>"
    } else {
        set tag_html "<textarea[qf_insert_attributes $tag_attributes_list]>${attributes_arr(value)}</textarea>"
    }
    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) "${tag_html}\n"
     
}

ad_proc -public qf_select { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
    {arg23 ""}
    {arg24 ""}
    {arg25 ""}
    {arg26 ""}
    {arg27 ""}
    {arg28 ""}
} {
    Creates a SELECT tag with nested OPTIONS, supplying necessary attributes where nonempty values are supplied. Set "multiple" to 1 to activate multiple attribute.
    The argument for the "value" attribute is a list_of_lists passed to qf_options, where the list_of_lists represents a list of OPTION tag attribute/value pairs. 
    Alternate to passing the "value" attribute, you can pass pure html containing literal Option tags as "value_html"
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_tag_list [list accesskey align class cols id name readonly rows style tabindex title wrap]
    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list value form_id value_html
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24 $arg25 $arg26 $arg27 $arg28]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute
            }
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_select: [ad_quotehtml [string range $attribute 0 15]] is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_select: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_select: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_select: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(select_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(select_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
            set __qf_arr(select_$attribute) $attributes_arr($attribute)
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
    }

    set tag_html ""
    set previous_select 0
    # first close any existing selects tag with form_id
    set __select_open_list_exists [info exists __form_ids_select_open_list]
    if { $__select_open_list_exists } {
        if { [lsearch $__form_ids_select_open_list $attributes_arr(form_id)] > -1 } {
            append tag_html "</select>\n"
            set previous_select 1
        }
    }
    # set results __form_ids_select_open_list
    if { $previous_select } {
        # no changes needed, "select open" already indicated
    } else {
        if { $__select_open_list_exists } {
            lappend __form_ids_select_open_list $attributes_arr(form_id)
        } else {
            set __form_ids_select_open_list [list $attributes_arr(form_id)]
        }
    }

    # add options tag
    if { [info exists attributes_arr(value_html)] } {
        set value_list_html $attributes_arr(value_html)
    } else {
        set value_list_html ""
    }
    if { [info exists attributes_arr(value)] } {
        append value_list_html [qf_options $attributes_arr(value)]
    }

    append tag_html "<select[qf_insert_attributes $tag_attributes_list]>$value_list_html</select>"
    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) "${tag_html}\n"

}

ad_proc -private qf_options {
    {options_list_of_lists ""}
} {
    Returns the sequence of options tags usually associated with SELECT tag. 
    Does not append to an open form. These results are usually passed to qf_select that appends an open form.
    Option tags are added in sequentail order. A blank list in a list_of_lists is ignored. 
    To add a blank option, include the value attribute with a blank/empty value; 
    The option tag will wrap an attribute called "name".  
    To indicate "SELECTED" attribute, include the attribute "selected" with the paired value of 1.
} {
    # options_list is expected to be a list like this:
    # \[list \[list attribute1 value attribute2 value attribute3 value attribute4 value attribute5 value...\] \[list {second option tag attribute-value pairs} etc\] \]

    # for this proc, we need to check the individual options for each OPTION tag, to provide the most flexibility.
    set list_length [llength $options_list_of_lists]
    # is this a list of lists, or just a list (1 list of list)
    # test the second row to see if it has multiple list members
    set multiple_option_tags_p [expr { [llength [lindex $options_list_of_lists 1] ] > 1 } ]
    if { $list_length > 1 && $multiple_option_tags_p == 0 } {
        # options_list is malformed, by providing only a list, not list of lists, adjust it:
        set options_list_of_lists [list $options_list_of_lists]
    }

    set options_html ""
    foreach option_tag_attribute_list $options_list_of_lists {
        append options_html [qf_option $option_tag_attribute_list]
    }
    return $options_html
}

ad_proc -private qf_option {
    {option_attributes_list ""}
} {
    returns an OPTION tag usually associated with SELECT tag. Does not append to an open form. These results are usually passed to qf_select that appends an open form.
    Creates only one option tag. For multiple OPTION tags, see qf_options
    To add a blank attribute, include attribute with a blank/empty value; 
    The option tag will wrap an attribute called "name".  
    To indicate "SELECTED" or "DISABLED" attribute, include the attribute ("selected" or "disabled") with the paired value of 1.
} {
    set attributes_tag_list [list class dir disabled id label lang language selected style title value]
    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list label name
    set arg_list $option_attributes_list
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute
            }
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_options: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne "selected" && $attribute ne "disabled" && $attribute ne "checked" } {
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        } 
    }
    if { [info exists attributes_arr(label)] } {
        set name_html $attributes_arr(label)
    } elseif { [info exists attributes_arr(name)] } {
        set name_html $attributes_arr(name)
    } elseif { [info exists attributes_arr(value)] } {
        set name_html $attributes_arr(value)
    } else {
        set name_html ""
    }
    if { [info exists attributes_arr(checked)] && ![info exists attributes_arr(selected)] } {
        set attributes_arr(selected) "1"
    }
    if { [info exists attributes_arr(selected)] && $attributes_arr(selected) == 1 } {
        set option_html "<option[qf_insert_attributes $tag_attributes_list] selected>$name_html</option>\n"
    } elseif { [info exists attributes_arr(disabled)] && $attributes_arr(disabled) == 1 } {
        set option_html "<option[qf_insert_attributes $tag_attributes_list] disabled>$name_html</option>\n"
    } else {
        set option_html "<option[qf_insert_attributes $tag_attributes_list]>$name_html</option>\n"
    }
    return $option_html
}


ad_proc -public qf_close { 
    {arg1 ""}
    {arg2 ""}
} {
    closes a form by appending a close form tag (and fieldset tag if any are open). if id supplied, only closes that referenced form and any fieldsets associated with it.  
} {
    # use upvar to set form content, set/change defaults
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __form_ids_open_list __form_ids_open_list
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list form_id]
    set arg_list [list $arg1 $arg2]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_close: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_close: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to all open form ids
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set attributes_arr(form_id) $__form_ids_open_list
        if { [lsearch -exact $attributes_list form_id] == -1 } {
            lappend attributes_list "form_id"
        }
    }
    # attributes_arr(form_id) might be a list or a single value. Following loop should work either way.
    # close chosen form_id(s) 
    set a_fieldset_exists [info exists __form_ids_fieldset_open_list]
    foreach form_id $attributes_arr(form_id) {
        # check if form_id is valid
        set form_id_position [lsearch -exact $__form_ids_list $attributes_arr(form_id)]
        if { $form_id_position == -1 } {
            ns_log Warning "qf_close: unknown form_id $attributes_arr(form_id)"
        } else {
            if { $a_fieldset_exists } {
                # close fieldset tag if form has an open one.
                set form_id_fs_position [lsearch -exact $__form_ids_fieldset_open_list $form_id]
                if { $form_id_fs_position > -1 } {
                    append __form_arr($form_id) "</fieldset>\n"
                    # remove form_id from __form_ids_fieldset_open_list
                    set __form_ids_fieldset_open_list [lreplace $__form_ids_fieldset_open_list $form_id_fs_position $form_id_fs_position]
                }
            }
            # close form
            append __form_arr($form_id) "</form>\n"    
            # remove form_id from __form_ids_open_list            
            set __form_ids_open_list [lreplace $__form_ids_open_list $form_id_position $form_id_position]
        }
    }
}

ad_proc -public qf_read { 
    {arg1 ""}
    {arg2 ""}
} {

    returns the content of forms. If a form is not closed, returns the form in its partial state of completeness. If a form_id is supplied, returns the content of a specific form. Defaults to return all forms in a list.
} {
    # use upvar to set form content, set/change defaults
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr

    set attributes_full_list [list form_id]
    set arg_list [list $arg1 $arg2]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_read: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_read: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # normalize code using id instead of form_id
    if { [info exists attributes_arr(form_id)] } {
        set attributes_arr(id) $attributes_arr(form_id)
        unset attributes_arr(form_id)
    }
    # defaults to all form ids
    set form_id_exists [info exists attributes_arr(id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        # note, attributes_arr(id) might become a list or a scalar..
        if { [llength $__form_ids_list ] == 1 } {
            set specified_1 1
            set attributes_arr(form_id) [lindex $__form_ids_list 0]
        } else {
            set specified_1 0
            set attributes_arr(form_id) $__form_ids_list
        }
    } else {
        set specified_1 1
    }

    if { $specified_1 } {
        # a form specified in argument
        if { ![info exists __form_arr($attributes_arr(form_id)) ] } {
            ns_log Warning "qf_read: unknown form_id $attributes_arr(form_id)"
        } else {
             set form_s $__form_arr($attributes_arr(form_id))
        }
    } else {
        set forms_list [list]
        foreach form_id $attributes_arr(form_id) {
            # check if form_id is valid
            set form_id_position [lsearch $__form_ids_list $form_id]
            if { $form_id_position == -1 } {
                ns_log Warning "qf_read: unknown form_id $form_id"
            } else {
                lappend forms_list $__form_arr($form_id)
            }
        }
        set form_s $forms_list
    }
    return $form_s
}


ad_proc -public qf_input {
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
    {arg23 ""}
    {arg24 ""}
    {arg25 ""}
    {arg26 ""}
    {arg27 ""}
    {arg28 ""}
    {arg29 ""}
    {arg30 ""}
    {arg31 ""}
    {arg32 ""}
} {
    creates a form input tag, supplying attributes where nonempty values are supplied. when using CHECKED, set the attribute to 1.
    allowed attributes: type accesskey align alt border checked class id maxlength name readonly size src tabindex value.
    other allowed: form_id label. label is used to wrap the input tag with a label tag containing a label that is associated with the input.
    checkbox and radio inputs present label after input tag, other inputs are preceeded by label. Omit label attribute to not use this feature.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_tag_list [list type accesskey align alt border checked class id maxlength name readonly size src tabindex value]
    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list form_id label selected
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24 $arg25 $arg26 $arg27 $arg28 $arg29 $arg30 $arg31 $arg32]

    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute
            }
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_input: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_input(L801): invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_input:(L805) invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_input: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(input_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(input_$attribute)
            }
        }
    }

    # provide a blank value by default
    if { ![info exists attributes_arr(value)] } {
        set attributes_arr(value) ""
    }
    # convert a "selected" parameter to checked
    if { [info exists attributes_arr(selected)] && ![info exists attributes_arr(checked)] } {
        set attributes_arr(checked) $attributes_arr(selected)
        lappend attributes_list "checked"
    }

    # by default, wrap the input with a label tag for better UI, part 1
    if { [info exists attributes_arr(label)] && [info exists attributes_arr(type) ] && $attributes_arr(type) ne "hidden" } {
        if { ![info exists attributes_arr(id) ] } {
            set attributes_arr(id) $attributes_arr(name)
            append attributes_arr(id) "-[string range [clock clicks -milliseconds] end-3 end]-[string range [expr { rand() }] 2 end]"
            lappend attributes_list "id"
        }
    }
    # prepare attributes to process
    set tag_attributes_list [list]
    set tag_suffix ""
    foreach attribute $attributes_list {
        set __qf_arr(input_$attribute) $attributes_arr($attribute)
        if { $attribute ne "checked" && $attribute ne "disabled" } {
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        } else {
            set tag_suffix " ${attribute}"
           # set to checked or disabled
        }
    }

    # by default, wrap the input with a label tag for better UI, part 2
    if { [info exists attributes_arr(label)] && [info exists attributes_arr(type) ] && $attributes_arr(type) ne "hidden" } {
        if { $attributes_arr(type) eq "checkbox" || $attributes_arr(type) eq "radio" } {
            set tag_html "<label for=\"${attributes_arr(id)}\"><input[qf_insert_attributes $tag_attributes_list]${tag_suffix}>${attributes_arr(label)}</label>"
        } else {
            set tag_html "<label for=\"${attributes_arr(id)}\">${attributes_arr(label)}<input[qf_insert_attributes $tag_attributes_list]></label>"
        }
    } else {
        set tag_html "<input[qf_insert_attributes $tag_attributes_list]${tag_suffix}>"
    }

    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) "${tag_html}\n"
     
    return 
}

ad_proc -public qf_append { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
} {
    param html required
    param form_id
    inserts html in a form by appending supplied html. if form_id supplied, appends form with supplied form_id.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list html form_id]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_append: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_append: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
        lappend attributes_list form_id
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_append: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }
    if { ![info exists attributes_arr(html)] } {
        set attributs_arr(html) ""
        ns_log Notice "qf_append: no argument 'html'"
        if { [lsearch -exact $attributes_list "html"] == -1 } {
            set attributes_arr(html) ""
            lappend attributes_list "html"
        }
    }

    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) $attributes_arr(html)
    return 
}

ad_proc -private qf_insert_attributes {
    args_list
} {
    returns args_list of tag attribute pairs (attribute,value) as html to be inserted into a tag
} {
     set args_html ""
     foreach {attribute value} $args_list {
         if { [string range $attribute 1 1] eq "-" } {
             set $attribute [string range $attribute 1 end]
         }
         regsub -all -- {\"} $value {\"} value
         append args_html " $attribute=\"$value\""
     }
     return $args_html
}

ad_proc -public qf_choice {
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
    {arg23 ""}
    {arg24 ""}
} {
    Returns html of a select/option bar or radio button list (where only 1 value is returned to a posted form).
    Set "type" to "select" for select bar, or "radio" for radio buttons
    Required attributes:  name, value
    "value" argument is a list_of_lists, each list item contains a list of attribute/value pairs for generating a radio or option/bar item.
    "selected" is not required. Each choice is "unselected" by default. Set "selected" attribute to 1 to indicate item selected.
    For this proc, "label" refers to the text that labels a radio buttion or select option item. If a "label" attribute/value pair is not included, The tag's value attribute is used for label as well.
<pre>
Example usage. This code:
    set tag_attribute_list [list [list label " label1 " value visa1] [list label " label2 " value visa2] [list label " label3 " value visa3] ]
    qf_choice type radio name creditcard value $tag_attribute_list

Generates:

"&lt;label>&lt;input type="radio" name="creditcard" value="visa1"> label1 &lt;/label>
 &lt;label>&lt;input type="radio" name="creditcard" value="visa2"> label2 &lt;/label>
 &lt;label>&lt;input type="radio" name="creditcard" value="visa3"> label3 &lt;/label>"

By switching type to select like this:

    qf_choice type select name creditcard value $tag_attribute_list

the code generates:

"&lt;select name="creditcard">
&lt;option value="visa1"> label1 &lt;/option>
&lt;option value="visa2"> label2 &lt;/option>
&lt;option value="visa3"> label3 &lt;/option>
&lt;/select>"
</pre>
    <!-- &lt; is used to prevent browser views from rendering the code presented here -->
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list
    set attributes_select_list [list value accesskey align class cols name readonly rows style tabindex title wrap]
    set attributes_full_list $attributes_select_list
    lappend attributes_full_list type form_id id
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24]
    set attributes_list [list]
    set select_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
            if { [lsearch -exact $attributes_select_list $attribute] > -1 } {
                # create a list to pass to qf_select without it balking at unknown parameters
                lappend select_list $attribute $value
            } 
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_choice: [string range $attribute 0 15] is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }
    # for passing select_list, we need to pass form_id literally
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_choice: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }
    lappend select_list form_id $attributes_arr(form_id)

 

    # if attributes_arr(type) = select, then items are option tags wrapped by a select tag
    # if attributes_arr(type) = radio, then items are input tags, wrapped in a list for now
    # if needing to paginate radio buttons, build the radio buttons using qf_input directly.

    if { $attributes_arr(type) ne "radio" } {
        set type "select"
    } else {
        set type "radio"
    }
    
    # call qf_select if type is "select" instead of duplicating purpose of that code

    if { $type eq "radio" } {
        # create wrapping tag
        set tag_wrapping "ul"
        set args_html "<${tag_wrapping}"
        foreach attribute $attributes_list {
            # ignore proc parameters that are not tag attributes for the tag_wrapping tag
            if { $attribute eq "id" || $attribute eq "style" || $attribute eq "class"  } {
                # quoting unquoted double quotes in attribute values, so as to not inadvertently break the tag
                regsub -all -- {\"} $attributes_arr($attribute) {\"} attributes_arr($attribute)
                append args_html " $attribute=\"$attributes_arr($attribute)\""
            }
        }
        append args_html ">\n"
        qf_append form_id $attributes_arr(form_id) html $args_html
        set args_html ""

        # verify this is a list of lists.
        set list_length [llength $attributes_arr(value)]
        # test on the second input, less chance its a special case
        set second_input_attributes_count [llength [lindex $attributes_arr(value) 1]]
        if { $list_length > 1 && $second_input_attributes_count < 2 } {
            # a list was passed instead of a list of lists. Adjust..
            set attributes_arr(value) [list $attributes_arr(value)]
        }
        foreach input_attributes_list $attributes_arr(value) {
            if { [f::even_p [llength $input_attributes_list]] } {
                array unset input_arr
                array set input_arr $input_attributes_list
                if { ![info exists input_arr(label)] && [info exists input_arr(value)] } {
                    set input_arr(label) $input_arr(value)
                } 
                if { ![info exists input_arr(name)] && [info exists attributes_arr(name)] } {
                    set input_arr(name) $attributes_arr(name)
                }
                set input_attributes_list [array get input_arr]
                lappend input_attributes_list form_id $attributes_arr(form_id) type radio
                qf_append form_id $attributes_arr(form_id) html "<li>"
                qf_input $input_attributes_list
                qf_append form_id $attributes_arr(form_id) html "</li>"
            } else {
                ns_log Notice "qf_choice: list not even number of members, skipping rendering of value attribute with list: $input_attributes_list"
            }
        }
        append args_html "</${tag_wrapping}>"
        qf_append form_id $attributes_arr(form_id) html $args_html

    } else {

        set args_html [qf_select $select_list]

    }
    return $args_html
}

ad_proc -public qf_choices {
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
    {arg23 ""}
    {arg24 ""}
 } {
    returns html of a select/option bar or radio button list (where only 1 value is returned to a posted form).
     Required attributes:  name, value.  
     Set "type" to "select" for select bar, or "checkbox" for checkboxes.
     The value of the "value" attribute is a list_of_lists, each list item contains attribute/value pairs for a radio or option/bar item.
     If "label" not provided for tags in the list_of_lists, the value of the "value" attribute is also used for label.
     Set "selected" attribute to 1 in the value list_of_lists to indicate item selected. Default is unselected.
 } {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list

    set attributes_select_list [list value accesskey align class cols name readonly rows style tabindex title wrap]
    set attributes_full_list $attributes_select_list
    lappend attributes_full_list type form_id id
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24]
    set attributes_list [list]
    set select_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
            if { [lsearch -exact $attributes_select_list $attribute ] > -1 } {
                # create a list to pass to qf_select without it balking at unknown parameters
                lappend select_list $attribute $value
            } 
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_choices: [string range $attribute 0 15] is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    # for passing select_list, we need to pass form_id literally
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_choice: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }
    lappend select_list form_id $attributes_arr(form_id)

    # if attributes_arr(type) = select, then items are option tags wrapped by a select tag
    # if attributes_arr(type) = checkbox, then items are input tags, wrapped in a list for now
    # if needing to paginate checkboxes, build the checkboxes using qf_input directly.

    if { $attributes_arr(type) ne "checkbox" } {
        set type "select"
    } else {
        set type "checkbox"
    }
    
    # call qf_select if type is "select" instead of duplicating purpose of that code

    if { $type eq "checkbox" } {
        # create wrapping tag
        set tag_wrapping "ul"
        set args_html "<${tag_wrapping}"
        foreach attribute $attributes_list {
            # ignore proc parameters that are not tag attributes
            if { $attribute eq "id" || $attribute eq "style" || $attribute eq "class"  } {
                # quoting unquoted double quotes in attribute values, so as to not inadvertently break the tag
                regsub -all -- {\"} $attributes_arr($attribute) {\"} attributes_arr($attribute)
                append args_html " $attribute=\"$attributes_arr($attribute)\""
            }
        }
        append args_html ">\n"
        qf_append form_id $attributes_arr(form_id) html $args_html
        set args_html ""

        # verify this is a list of lists.
        set list_length [llength $attributes_arr(value)]
        # test on the second input, less chance its a special case
        set second_input_attributes_count [llength [lindex $attributes_arr(value) 1]]
        if { $list_length > 1 && $second_input_attributes_count < 2 } {
            # a list was passed instead of a list of lists. Adjust..
            set attributes_arr(value) [list $attributes_arr(value)]
        }
        
        foreach input_attributes_list $attributes_arr(value) {
            array unset input_arr
            array set input_arr $input_attributes_list
            if { ![info exists input_arr(label)] && [info exists input_arr(value)] } {
                set input_arr(label) $input_arr(value)
            } 
            if { ![info exists input_arr(name)] && [info exists attributes_arr(name)] } {
                set input_arr(name) $attributes_arr(name)
            }
            set input_attributes_list [array get input_arr]
            lappend input_attributes_list form_id $attributes_arr(form_id) type radio
            qf_append form_id $attributes_arr(form_id) html "<li>"
            qf_input $input_attributes_list
            qf_append form_id $attributes_arr(form_id) html "</li>"
        }
        append args_html "</${tag_wrapping}>"
    } else {
        set args_html [qf_select $select_list]
    }
    return $args_html
}    
