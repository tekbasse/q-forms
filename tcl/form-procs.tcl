ad_library {

    routines for creating, managing input via html forms
    @creation-date 21 Nov 2010
    @Copyright (c) 2010-5 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl.html
    @project home: http://github.com/tekbasse/q-forms
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com
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
# __qf_hc_arr contains sh_key_id for each form_id
# a blank id passed in anything other than qf_form assumes the current (most recent used form_id)

# Regarding security hash re-work, see discussions:
# http://openacs.org/forums/message-view?message_id=182057
# for early example and discussion, see http://openacs.org/forums/message-view?message_id=3602056

# doc(type) is declared XML DOCTYPE and is passed from main content to blank-master.tcl
# If doc(type) doesn't exist, blank-master.tcl sets default:
# {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">}

# 
#   id for nonform tag should not be relied on as form_id. use an attribute "form_id" for assigning tags to specific forms,
#  when there are more than one form are defined concurrently in page.


ad_proc -private qf_form_key_create {
    {key_id ""}
    {action_url "/"}
    {instance_id ""}
} {
    creates the form key for a more secure form transaction. Returns the security hash.

    @see qf_submit_key_accepted_p
} {
    upvar 1 __qf_hc_arr __qf_hc_arr
    upvar 1 attributes_arr attributes_arr

    # This proc is inspired from sec_random_token
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    #   ns_time doesn't have enough time separation
    if { $key_id eq "" } {
        set key_id [expr { int( [clock clicks] * [ns_rand] ) } ]
    }
    set time_sec [clock clicks -milliseconds]
    set start_clicks [ad_conn start_clicks]
    if { [ad_conn -connected_p] } {
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
        # time_sec s/b circa clock seconds

        set secure_p [expr { floor( [ns_rand] + 0.5 ) } ]

        set session_id [expr { floor( $time_sec / 4 ) } ]
        #        set action_url "/"
        #        set render_timestamp $time_sec
    }
    append sec_hash_string $start_clicks $session_id $secure_p $client_ip $action_url $time_sec $key_id
    set sec_hash [ns_sha1 $sec_hash_string]
    set sh_key_id [db_nextval qf_id_seq]
    db_dml qf_form_key_create {insert into qf_key_map
        (instance_id,sh_key_id,rendered_timestamp,sec_hash,key_id,session_id,action_url,secure_conn_p,client_ip)
        values (:instance_id,:sh_key_id,:time_sec,:sec_hash,:key_id,:session_id,:action_url,:secure_p,:client_ip) }
    if { [info exists attributes_arr(form_id) ] } {
        set __qf_hc_arr($attributes_arr(form_id)) $sh_key_id
    }
    return $sec_hash
}

ad_proc -private qf_submit_key_accepted_p {
    {sec_hash ""}
    {instance_id ""}
} {
    Checks the form key against existing ones. Returns 1 if matches and unexpired, otherwise returns 0.
} {
    # sh_key_id is passed to qf_get_inputs_as_array to collect hidden name value pairs.
    upvar 1 sh_key_id sh_key_id
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
        select session_id as session_id_i, action_url as action_url_i, secure_conn_p as secure_conn_p_i, client_ip as client_ip_i, sh_key_id
        from qf_key_map
        where instance_id=:instance_id 
        and sec_hash=:sec_hash 
        and submit_timestamp is null } ]
    if { !$accepted_p } {
        # there is nothing to compare. log current values:
        ns_log Warning "qf_submit_key_accepted_p.115: is false. action_url '${action_url}' sec_hash '${sec_hash}'"
        if { $connected_p } {
            ns_log Warning "qf_submit_key_accepted_p.117: session_id '${session_id}' secure_p '${secure_p}' client_ip '${client_ip}'"
        }
    } else {
        # Mark the key expired
        set submit_timestamp [ns_time]
        db_dml qf_form_key_expire { update qf_key_map set submit_timestamp=:submit_timestamp 
            where instance_id =:instance_id 
            and sec_hash=:sec_hash 
            and submit_timestamp is null }
    }
    return $accepted_p
}



ad_proc -public qf_get_inputs_as_array {
    {form_array_name "__form_input_arr"}
    {arg1 ""}
    {value1 ""}
    args
} {
    Get inputs from form submission, quotes all input values. Use ad_unquotehtml to unquote a value.
    Returns 1 if form inputs exist, otherwise returns 0.
    <br>
    If <code>duplicate_key_check</code> is 1, checks if an existing key/value pair already exists, otherwise just overwrites existing value.  
    <br>
    If <code>multiple_key_as_list</code> is 1, returns a list of values for duplicate (and multiple) referenced keys.
    <br>
    If <code>hash_check</code> is 1, confirms that input is from one instance of a form generated by q_form 
    by confirming that unique hash passed by form is the same as the hash generated at time form was generated.
    <br>
    If <code>post_only</code> is 1, confirms that input is via cgi POST. Ignores input via GET.

} {
    # For Form input expectations 
    # see https://www.w3.org/TR/html4/interact/forms.html#successful-controls
    # get args
    upvar 1 $form_array_name __form_input_arr
    set array __form_buffer_arr
    set arg_arr(duplicate_key_check) 0
    set arg_arr(multiple_key_as_list) 0
    set arg_arr(hash_check) 0
    set arg_arr(post_only) 0
    set arg_full_list [list duplicate_key_check \
                           multiple_key_as_list \
                           hash_check \
                           post_only]

    set instance_id [ad_conn package_id]
    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }
    # normalize args 
    foreach {name value} $arg_list {
        set attribute_index [lsearch -exact $arg_full_list $name]
        if { $attribute_index > -1 } {
            set arg_arr(${name}) $value
        } else {
            if { $name ne "" } {
                ns_log Error "qf_get_inputs_as_array.170: '${name}' is not a valid name for use with args."
            }
        }
    }

    if { ( $arg_arr(post_only) && [string match -nocase "post" [ad_conn method]] ) || !$arg_arr(post_only) } {
        # get form variables passed with connection
        set __form_input_exists 0
        set __form [ns_getform]
        if { $__form eq "" } {
            set __form_size 0
        } else {
            set __form_size [ns_set size $__form]
        }
        #ns_log Notice "qf_get_inputs_as_array.183: formsize $__form_size"
        for { set __form_counter_i 0 } { $__form_counter_i < $__form_size } { incr __form_counter_i } {
            
            regexp -nocase -- {^[a-z][a-z0-9_\.\:\(\)]*} [ns_set key $__form $__form_counter_i] __form_key
            # Why doesn't work for  regexp -nocase -- {^[a-z][a-z0-9_\.\:\(\)]*$ }    ?
            set __form_key_exists [info exists __form_key]
            # ns_log Notice "qf_get_inputs_as_array.189: __form_key_exists = ${__form_key_exists}"
            
            # no inserting tcl commands etc!
            if { $__form_key_exists == 0 || ( $__form_key_exists == 1 && [string length $__form_key] == 0 ) } {
                # let's make this an error for now, so we log any attempts
                #            ns_log Notice "qf_get_inputs_as_array.194: __form_key_exists ${__form_key_exists} length __form_key \[string length ${__form_key}\]"
                #           ns_log Notice "qf_get_inputs_as_array.196: attempt to insert unallowed characters to user input '{__form_key}' as '\[ns_set key $__form $__form_counter_i\]' for counter ${__form_counter_i}."
                if { $__form_counter_i > 0 } {
                    ns_log Notice "qf_get_inputs_as_array.197: attempt to insert unallowed characters to user input '{__form_key}'."
                }
            } else {
                set __form_key [ad_quotehtml $__form_key]
                # The name of the argument passed in the form
                # no legitimate argument should be affected by quoting:
                
                # This is the value
                set __form_input [ad_quotehtml [ns_set value $__form $__form_counter_i]]
                
                set __form_input_exists 1
                # check for duplicate key?
                set __form_key_exists [info exists __form_buffer_arr(${__form_key}) ]
                if { $arg_arr(duplicate_key_check) && $__form_key_exists } {
                    if { $__form_input ne $__form_buffer_arr(${__form_key}) } {
                        # which one is correct? log error
                        ns_log Error "qf_get_form_input.212: form input error. duplcate key provided for '${__form_key}'"
                        ad_script_abort
                        # set __form_input_exists to -1 instead of ad_script_abort?
                    } else {
                        ns_log Warning "qf_get_form_input.216: notice, form has a duplicate key with multiple values containing same info.."
                    }
                } elseif { $arg_arr(multiple_key_as_list) && $__form_key_exists } {
                    ns_log Notice "qf_get_inputs_as_array.219: A key has been posted with multiple values. Values assigned to the key as a list."
                    if { [llength $__form_buffer_arr(${__form_key})] > 1 } {
                        # value is a list, lappend
                        lappend __form_buffer_arr(${__form_key}) $__form_input
                    } else {
                        # convert the key value to a list
                        set __value_one $__form_buffer_arr(${__form_key})
                        unset __form_buffer_arr(${__form_key})
                        set __form_buffer_arr(${__form_key}) [list $__value_one $__form_input]
                    }
                } else {
                    set __form_buffer_arr(${__form_key}) $__form_input
                    #                ns_log Debug "qf_get_inputs_as_array.231: set ${form_array_name}($__form_key) '${__form_input}'."
                }
                
                # next key-value pair
            }
            
        }
    } else {
        set __form_input_exists 0
        ns_log "qf_get_inputs_as_array.26: form not sent via POST. Ignored."
    }
    if { $__form_input_exists } {
        if { $arg_arr(hash_check) } {
            if { [info exists __form_buffer_arr(qf_security_hash) ] } {
                set accepted_p [qf_submit_key_accepted_p $__form_buffer_arr(qf_security_hash) ]
                if { $accepted_p } {

                    # Are there any hidden name pairs to grab from db?
                    set name_value_lists [db_list_of_lists qf_name_value_pairs_r {select arg_name,arg_value
                        from qf_name_value_pairs
                        where instance_id=:instance_id
                        and sh_key_id=:sh_key_id} ]
                    # clear any external input and warn if it is different
                    foreach pair_list $name_value_lists {
                        set __form_key [lindex $pair_list 0]
                        set __form_input [lindex $pair_list 1]
                        if { [info exists __form_buffer_arr(${__form_key}) ] } {
                            set test [ad_unquotehtml $__form_buffer_arr(${__form_key})]
                            if { $test ne $__form_input } {
                                ns_log Warning "qf_get_inputs_as_array.12000: input of type 'hidden' from form does not match for name '${__form_key}'. Internal used. internal '${__form_input}' from form '${test}'"
                                array unset __form_buffer_arr $__form_key
                            }
                        }
                    }
                    foreach pair_list $name_value_lists {
                        set __form_key [lindex $pair_list 0]
                        set __form_input [lindex $pair_list 1]
                        # For consistency, this is a repeat of external form logic checks above.
                        
                        # check for duplicate key?
                        if { $arg_arr(duplicate_key_check) && [info exists __form_buffer_arr(${__form_key}) ] } {
                            if { $__form_input ne $__form_buffer_arr(${__form_key}) } {
                                # which one is correct? log error
                                ns_log Error "qf_get_form_input.312: form input error. duplcate key provided for '${__form_key}'"
                                ad_script_abort
                                # set __form_input_exists to -1 instead of ad_script_abort?
                            } else {
                                ns_log Warning "qf_get_form_input.316: notice, form has a duplicate key with multiple values containing same info.."
                            }
                        } elseif { $arg_arr(multiple_key_as_list) } {
                            ns_log Notice "qf_get_inputs_as_array.319: A key has been posted with multible values. Values assigned to the key as a list."
                            if { [llength $__form_buffer_arr(${__form_key})] > 1 } {
                                # value is a list, lappend
                                lappend __form_buffer_arr(${__form_key}) $__form_input
                            } else {
                                # convert the key value to a list
                                set __value_one $__form_buffer_arr(${__form_key})
                                unset __form_buffer_arr(${__form_key})
                                set __form_buffer_arr(${__form_key}) [list $__value_one $__form_input]
                            }
                        } else {
                            set __form_buffer_arr(${__form_key}) $__form_input
                            #                ns_log Debug "qf_get_inputs_as_array.231: set ${form_array_name}($__form_key) '${__form_input}'."
                        }
                        
                        # next key-value pair
                    }

                    unset __form_buffer_arr(qf_security_hash)
                    array set __form_input_arr [array get __form_buffer_arr]
                    return $__form_input_exists
                } else {
                    ns_log Notice "qf_get_inputs_as_array.346: hash_check with form input of '$__form_buffer_arr(qf_security_hash)' did not match."
                    return 0
                }
            } else {
                set accepted_p 0
                ns_log Notice "qf_get_inputs_as_array.351: hash_check requires qf_security_hash, but was not included with form input."
                return 0
            }
        } else {
            array set __form_input_arr [array get __form_buffer_arr]
            return $__form_input_exists
        }
    } else {
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
    return $__qf_remember_atributes
}

ad_proc -public qf_form { 
    {arg1 ""}
    {value1 ""}
    args
} {
    Initiates a form with form tag and supplied attributes. 
    Returns an id. 
    A clumsy url-based id is provided if not passed (not recommended).
    If hash_check passed, creates a hash to be checked on submit for server-client transaction continuity.
    <pre>
    To create a form that uploads a file, set attribute enctype to "multipart/form-data", set method to "post".
    Also, create an input tag with type attribute  set to "file" to choose a file to upload, 
    and set name attribute to name of file as it will be received at the server along with
    other input from the form.

    In the following example, name is set to "clientfile".
    
    After the form has been submitted, data can be retreived via ns_queryget (or qf_get_inputs_as_array ):

    set uploaded_filename \[ns_queryget clientfile \]

    set file_pathname_on_server \[ns_queryget clientfile.tmpfile \]
    </pre><p>
    For more info, see <a href="http://naviserver.sourceforge.net/n/naviserver/files/ns_queryget.html">Naviserver documentation for ns_queryget</a></p>

    @see qf_get_inputs_as_array
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    # __qf_hc_arr(form_id) contains value of hash_check. 
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __form_ids_open_list __form_ids_open_list
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __qf_hc_arr __qf_hc_arr
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }

    # was
    #set attributes_tag_list /list action class id method name style target title encytype/
    set __qf_doctype [qf_doctype]
    set attributes_tag_list [qf_doctype_tag_attributes $__qf_doctype form]

    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list form_id hash_check key_id

    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact -nocase $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attribute_lc [string tolower $attribute ]
            set attributes_arr(${attribute_lc}) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute_lc
            }
        } else {
            ns_log Error "qf_form.337: '${attribute}' is not a valid attribute."
        }
    }
    if { ![info exists attributes_arr(action)] } {
        set attributes_arr(action) [ad_conn url]
        lappend attributes_list "action"
    }
    if { ![info exists attributes_arr(method)] } {
        set attributes_arr(method) "post"
        lappend attributes_list "method"
    }
    if { ![info exists attributes_arr(enctype)] && $attributes_arr(method) eq "post" } {
        set attributes_arr(enctype) "application/x-www-form-urlencoded"
        lappend attributes_list "enctype"
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
            if { $attribute ne "id" && ![info exists attributes_arr(${attribute})] && [info exists __qf_arr(form_${attribute})] } {
                set attributes_arr(${attribute}) $__qf_arr(form_${attribute})
            }
        }
    }
    # every form gets a form_id
    set form_id_exists [info exists attributes_arr(form_id) ]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set id_exists [info exists attributes_arr(id) ]
        if { $id_exists == 0 || ( $id_exists == 1 && $attributes_arr(id) eq "" ) } { 
            regsub -all -- {/} [ad_conn url] {_} form_key
            append form_key "-[llength ${__form_ids_list}]"
        } else {
            # since a FORM id has to be unique, lets use it
            set form_key $attributes_arr(id)
        }
        set attributes_arr(form_id) $form_key
        ns_log Notice "qf_form.380: generating form_id $attributes_arr(form_id)"
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(form_${attribute}) $attributes_arr(${attribute})
        # if a form tag requires an attribute, the following test needs to  be forced true
        if { $attributes_arr(${attribute}) ne "" } {
            lappend tag_attributes_list $attribute $attributes_arr(${attribute})
        }
    }
    
    set tag_html "<form"
    append tag_html [qf_insert_attributes $tag_attributes_list]
    append tag_html ">"
    # set results  __form_arr 
    append __form_arr($attributes_arr(form_id)) ${tag_html} "\n"
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
        set tag_html "<input"
        set input_val [qf_form_key_create $attributes_arr(key_id) $attributes_arr(action)]
        #set __qf_hc_arr($attributes_arr(form_id)) $sh_key_id (done by qf_form_key_create)
        append tag_html [qf_insert_attributes [list type hidden name qf_security_hash value $input_val]]
        append tag_html ">"
        append __form_arr($attributes_arr(form_id)) ${tag_html} "\n"
        ns_log Notice "qf_form.411: adding ${tag_html}"
    } else {
        set __qf_hc_arr($attributes_arr(form_id)) 0
    }
    
    set __qf_arr(form_id) $attributes_arr(form_id)
    return $attributes_arr(form_id)
}


ad_proc -public qf_fieldset { 
    {arg1 ""}
    {value1 ""}
    args
} {
    Starts a form fieldset by appending a fieldset tag.  Fieldset closes when form is closed or another fieldset defined in same form.
    <br><br>
    If a 'label' attribute is included, the attribute is converted to
    a 'legend' tag and added immediately following the fieldset tag.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }

    # was
    #set attributes_tag_list  /list align class id style title valign/
    set __qf_doctype [qf_doctype]
    set attributes_tag_list [qf_doctype_tag_attributes $__qf_doctype fieldset]

    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list form_id label

    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr(${attribute}) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute
            }
        } else {
            ns_log Error "qf_fieldset.460: '${attribute}' is not a valid attribute."
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_fieldset.466: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_fieldset.470: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_fieldset.479: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr(${attribute})] && [info exists __qf_arr(fieldset_${attribute})] } {
                set attributes_arr(${attribute}) $__qf_arr(form_${attribute})
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(fieldset_${attribute}) $attributes_arr(${attribute})
        lappend tag_attributes_list $attribute $attributes_arr(${attribute})
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
    append tag_html "<fieldset"
    append tag_html [qf_insert_attributes ${tag_attributes_list}]
    append tag_html ">"

    if { [info exists attributes_arr(label) ] } {
        append tag_html "<legend>" $attributes_arr(label) "</legend>"
    }

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
    append tag_html "\n"
    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) $tag_html
    return $tag_html
}

ad_proc -public qf_textarea { 
    {arg1 ""}
    {value1 ""}
    args
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
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }

    #was
    #set attributes_tag_list list accesskey align class cols id name readonly rows style tabindex title wrap
    set __qf_doctype [qf_doctype]
    set attributes_tag_list [qf_doctype_tag_attributes $__qf_doctype textarea]

    set attributes_full_list $attributes_tag_list

    # datatype and form_tag_type is used with qfo_2g paradigm. See proc qfo_2g.
    lappend attributes_full_list value label form_id datatype form_tag_type

    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr(${attribute}) $value
            if { [lsearch -exact $attributes_tag_list $attribute ] > -1 } {
                lappend attributes_list $attribute
            }
        } else {
            ns_log Error "qf_textarea.568: '${attribute}' is not a valid attribute for doctype '${__qf_doctype}'."
            ad_script_abort
        }
    }
    if { [info exists attributes_arr(label)] } {
        set attributes_arr(label) [string trim $attributes_arr(label)]
    }
    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_textarea.574: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_textarea.578: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_textarea.587: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr(${attribute})] && [info exists __qf_arr(textarea_${attribute})] } {
                set attributes_arr(${attribute}) $__qf_arr(textarea_${attribute})
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
        set attributes_arr(id) $attributes_arr(form_id)
        append attributes_arr(id) "-" $attributes_arr(name)
        lappend attributes_list id
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(textarea_${attribute}) $attributes_arr(${attribute})
        lappend tag_attributes_list $attribute $attributes_arr(${attribute})
    }

    # by default, wrap the input with a label tag for better UI
    if { [info exists attributes_arr(id) ] && [info exists attributes_arr(label)] && $attributes_arr(label) ne "" } {
        set tag_html "<label for=\""
        append tag_html $attributes_arr(id) "\">" $attributes_arr(label) 
        append tag_html "</label><textarea" [qf_insert_attributes $tag_attributes_list]
        append tag_html ">" $attributes_arr(value) "</textarea>"
    } else {
        set tag_html "<textarea"
        append tag_html [qf_insert_attributes $tag_attributes_list]
        append tag_html ">" $attributes_arr(value) "</textarea>"
    }
    # set results  __form_arr, we checked form_id above.
    append tag_html "\n"
    append __form_arr($attributes_arr(form_id)) $tag_html
    return $tag_html
}

ad_proc -public qf_select { 
    {arg1 ""}
    {value1 ""}
    args
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
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }

    set __qf_doctype [qf_doctype]
    set attributes_tag_list [qf_doctype_tag_attributes $__qf_doctype select]

    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list value form_id value_html multiple type

    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact -nocase $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attribute_lc [string tolower $attribute ]
            set attributes_arr($attribute_lc) $value
            if { [lsearch -exact $attributes_tag_list $attribute_lc] > -1 } {
                lappend attributes_list $attribute_lc
            }
        } else {
            ns_log Error "qf_select.673: '[ad_quotehtml [string range ${attribute} 0 15]]' is not a valid attribute. attributes_full_list '${attributes_full_list}' attributes_tag_list '${attributes_tag_list}' arg_list '${arg_list}'"
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_select.679: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_select.683: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form_id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_select.691: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr(${attribute})] && [info exists __qf_arr(select_${attribute})] } {
                set attributes_arr(${attribute}) $__qf_arr(select_${attribute})
            }
        }
    }

    # propagate the tabindex value to tabindex attribute in options?
    # Code is added in qf_select instead of qf_options,
    # because qf_options is not configured to pass extra parameters such as tabindex.
    if { [info exists attributes_arr(tabindex) ] } {
        # parse the options, add tabindex if it doesn't exist, or
        # change its value to be consistent.
        set tabindex_c "tabindex"
        # unselected tabindex assigned a value of -1 according to:
        # https://developers.google.com/web/fundamentals/accessibility/focus/using-tabindex
        set unselected "-1"
        set new_value_lol [list ]
        foreach option_att_list $attributes_arr(value) {
            array set option_att_arr $option_att_list
            set oa_names_list [array names option_att_arr]
            set tab_idx [lsearch -exact -nocase $oa_names_list $tabindex_c ]
            if { $tab_idx > -1 } {
                set ti_name [lindex $oa_names_list $tab_idx]
            } else {
                set ti_name $tabindex_c
            }
            if { [info exists option_att_arr(selected) ] } {
                if { $option_att_arr(selected) eq 1 } {
                    set option_att_arr(${ti_name}) $attributes_arr(tabindex)
                } else {
                    set option_att_arr(${ti_name}) $unselected
                }
            } elseif { [info exists option_att_arr(checked) ] } {
                if { $option_att_arr(checked) eq 1 } {
                    set option_att_arr(${ti_name}) $attributes_arr(tabindex)
                } else {
                    set option_att_arr(${ti_name}) $unselected
                }
            } else {
                set option_att_arr(${ti_name}) $unselected
            }
            set new_option_att_list [array get option_att_arr]
            array unset option_att_arr
            lappend new_value_lol $new_option_att_list
        }
        set attributes_arr(value) $new_value_lol

    }
    

    # prepare attributes to process
    set tag_attributes_list [list]
    set tag_suffix_html ""
    foreach attribute $attributes_list {
        set __qf_arr(select_${attribute}) $attributes_arr(${attribute})
        if { [string match -nocase "multiple" $attribute] } {
            if { $__qf_doctype eq "xml" } {
                lappend tag_attributes_list $attribute $attribute
            } else {
                if { $attributes_arr(${attribute}) } {
                    set tag_suffix_html " multiple"
                }
            }
        } else {
            lappend tag_attributes_list $attribute $attributes_arr(${attribute})
        }
    }

    set tag_html ""
    # Auto closing the select tag via qf_close has been deprecated,
    # because qf_choice and qf_choices exist.
    # It adds too much complexity for a nonstandard api usage case.
    # To add this feature requires checking other input tags etc too.
    # This code will be ignored for now, but left in place for future expansion.
    set previous_select 0
    # first close any existing selects tag with form_id
    set __select_open_list_exists [info exists __form_ids_select_open_list]
    if { $__select_open_list_exists } {
        if { [lsearch $__form_ids_select_open_list $attributes_arr(form_id)] > -1 } {
            #            append tag_html "</select>\n"
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

    append tag_html "<select" [qf_insert_attributes ${tag_attributes_list}]
    append tag_html $tag_suffix_html 
    append tag_html ">" $value_list_html "</select>"

    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) $tag_html
    return $tag_html
}

ad_proc -private qf_options {
    {options_list_of_lists ""}
} {
    Returns the sequence of options tags usually associated with SELECT tag. 
    Does not append to an open form. These results are usually passed to qf_select that appends an open form.
    Option tags are added in sequential order. A blank list in a list_of_lists is ignored. 
    To add a blank option, include the value attribute with a blank/empty value; 
    The option tag will wrap an attribute called "name".  
    To indicate "SELECTED" attribute, include the attribute "selected" with the paired value of 1.
} {
    # following three upvars are for qf_doctype embedded in qf_option
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    # options_list is expected to be a list like this:
    # list list attribute1 value attribute2 value attribute3 value attribute4 value attribute5 value... 
    #      list {second option tag attribute-value pairs} etc

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
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    #was set attributes_tag_list /list class dir disabled id label lang language selected style title value/
    set __qf_doctype [qf_doctype]
    set attributes_tag_list [qf_doctype_tag_attributes $__qf_doctype option]

    set attributes_full_list $attributes_tag_list
    lappend attributes_full_list label name tabindex
    # type form_id
    set arg_list $option_attributes_list
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact -nocase $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attribute_lc [string tolower $attribute ]
            set attributes_arr(${attribute_lc}) $value
            if { [lsearch -exact $attributes_tag_list $attribute] > -1 } {
                lappend attributes_list $attribute_lc
            }
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_option.806: '${attribute}' is not a valid attribute. Invoke with attribute value pairs. \n attributes_full_list '${attributes_full_list}' \n attributes_tag_list '${attributes_tag_list}' "
            ad_script_abort
        }
    }
    if { [info exists attributes_arr(label)] } {
        set attributes_arr(label) [string trim $attributes_arr(label)]
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne "selected" && $attribute ne "disabled" && $attribute ne "checked" } {
            lappend tag_attributes_list $attribute $attributes_arr(${attribute})
        } 
    }
    set name_html " "
    if { [info exists attributes_arr(label)] } {
        append name_html $attributes_arr(label)
    } elseif { [info exists attributes_arr(name)] } {
        append name_html $attributes_arr(name)
    } elseif { [info exists attributes_arr(value)] } {
        append name_html $attributes_arr(value)
    } 
    append name_html " "
    if { [info exists attributes_arr(checked)] && ![info exists attributes_arr(selected)] } {
        set attributes_arr(selected) "1"
    }
    if { ([info exists attributes_arr(selected)] && $attributes_arr(selected) eq "1") && $attributes_arr(selected) eq "1" } {
        set option_html "<option"
        append option_html [qf_insert_attributes $tag_attributes_list]
        append option_html "selected>" $name_html "</option>\n"
    } elseif { [info exists attributes_arr(disabled)] && $attributes_arr(disabled) eq "1" } {
        set option_html "<option"
        append option_html [qf_insert_attributes $tag_attributes_list]
        if { $__qf_doctype eq "xml" } {
            append option_html "disabled=\"disabled\">"
        } else {
            append option_html "disabled>"
        }
        append option_html $name_html "</option>\n"
    } else {
        set option_html "<option"
        append option_html [qf_insert_attributes $tag_attributes_list]
        append option_html ">" $name_html "</option>\n"
    }
    return $option_html
}


ad_proc -public qf_close { 
    {arg1 ""}
    {arg2 ""}
} {
    Closes a form by appending a close form tag (and fieldset tag if any are open). if form_id supplied, only closes that referenced form and any fieldsets associated with it. 

@return Number of forms that are closed.
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
            set attributes_arr(${attribute}) $value
            lappend attributes_list $attribute
        } else {
            if { $attribute ne "" } {
                ns_log Error "qf_close.863: '${attribute}' is not a valid attribute."
                ad_script_abort
            }
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_close.870: invoked before qf_form or used in a different namespace than qf_form.."
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
        set form_id_position [lsearch -exact $__form_ids_open_list $form_id]
        if { $form_id_position == -1 } {
            ns_log Warning "qf_close.887: unknown form_id '${form_id}' in __form_ids_open_list '${__form_ids_open_list}' of '$attributes_arr(form_id)'"
        } else {
            if { $a_fieldset_exists } {
                # close fieldset tag if form has an open one.
                set form_id_fs_position [lsearch -exact $__form_ids_fieldset_open_list $form_id]
                if { $form_id_fs_position > -1 } {
                    append __form_arr(${form_id}) "</fieldset>\n"
                    # remove form_id from __form_ids_fieldset_open_list
                    set __form_ids_fieldset_open_list [lreplace $__form_ids_fieldset_open_list $form_id_fs_position $form_id_fs_position]
                }
            }
            # close form
            append __form_arr(${form_id}) "</form>\n"    
            # remove form_id from __form_ids_open_list            
            set __form_ids_open_list [lreplace $__form_ids_open_list $form_id_position $form_id_position]
        }
    }
    set forms_count [llength $attributes_arr(form_id) ]
    return $forms_count
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
            set attributes_arr(${attribute}) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_read.928: '${attribute}' is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_read.934: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # normalize code using id instead of form_id
    if { [info exists attributes_arr(form_id)] } {
        set attributes_arr(id) $attributes_arr(form_id)
        unset attributes_arr(form_id)
    }
    # defaults to all form ids
    set form_id_exists [info exists attributes_arr(id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(id) eq "" ) } { 
        # note, attributes_arr(id) might become a list or a scalar..
        if { [llength $__form_ids_list ] == 1 } {
            set specified_1 1
            set attributes_arr(id) [lindex $__form_ids_list 0]
        } else {
            set specified_1 0
            set attributes_arr(id) $__form_ids_list
        }
    } else {
        set specified_1 1
    }

    if { $specified_1 } {
        # a form specified in argument
        if { ![info exists __form_arr($attributes_arr(id)) ] } {
            ns_log Warning "qf_read.960: unknown form_id $attributes_arr(id)"
        } else {
            set form_s $__form_arr($attributes_arr(id))
        }
    } else {
        set forms_list [list]
        foreach form_id $attributes_arr(id) {
            # check if form_id is valid
            set form_id_position [lsearch $__form_ids_list $form_id]
            if { $form_id_position == -1 } {
                ns_log Warning "qf_read.970: unknown form_id '${form_id}'"
            } else {
                lappend forms_list $__form_arr(${form_id})
            }
        }
        set form_s $forms_list
    }
    return $form_s
}


ad_proc -public qf_bypass {
    args
} {
    Places a name value pair in a temporary db cache for passing between form generation and form post.
    qf_bypass is expected to be used in context of a form_id. Data is retrieved via qf_get_inputs_as_array.
    Input is similar to qf_input. Acceptable attributes: name, value, form_id
    Returns 1 if successful. Otherwise returns 0.
} {
    upvar 1 __qf_arr __qf_arr
    upvar 1 __qf_hc_arr __qf_hc_arr
    upvar 1 __form_ids_list __form_ids_list

    if { ![info exists __form_ids_list] } {
        ns_log Warning "qf_bypass.1083: invoked before qf_form or used in a different namespace than qf_form.."
        set __form_ids_list [list [random]]
        set __qf_arr(form_id) $__form_ids_list
    }
    # default to last modified form_id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    # defaults
    set arg_name ""
    set arg_value ""
    set success_p 1
    foreach {attribute value} $args {
        switch -exact -- $attribute {
            name {
                set arg_name $value
            }
            value {
                set arg_value $value
            }
            form_id {
                if { $value in $__form_ids_list } {
                    set attributes_arr(form_id) $value
                } else {
                    ns_log Notice "qf_bypass.1106: form_id '${value}' not found; Using last modified form form_id."
                }
            }
            type {
                # if hidden. Ignore without logging.
                if { ![string match -nocase "hidden" $value] } {
                    ns_log Notice "qf_bypass.1109: type specified not required. FYI is '${value}' but should be 'hidden'."
                }
            }
            default {
                ns_log Notice "qf_bypass.1110: attribute '${attribute}' unrecognized. skipped. value '${value}'"
            }
        }
    }
    if { $arg_name ne "" } {
        # pass via db for integrity of internal references
        set instance_id [ad_conn package_id]
        set sh_key_id $__qf_hc_arr($attributes_arr(form_id))
        db_dml qf_name_value_pairs_c { insert into qf_name_value_pairs
            (instance_id,sh_key_id,arg_name,arg_value) 
            values (:instance_id,:sh_key_id,:arg_name,:arg_value) }
    } else {
        set success_p 0
    }
    return $success_p
}

ad_proc -public qf_bypass_nv_list {
    args_list
    {form_id ""}
} {
    Places name value pairs in a temporary db cache for passing between form generation and form post.
    qf_bypass_nv_list is expected to be used in context of a form_id. Data is retrieved via qf_get_inputs_as_array.
    
} {
    upvar 1 __qf_arr __qf_arr
    upvar 1 __qf_hc_arr __qf_hc_arr
    upvar 1 __form_ids_list __form_ids_list

    if { ![info exists __form_ids_list] } {
        ns_log Warning "qf_bhypass_nv_list.1140: invoked before qf_form or used in a different namespace than qf_form.."
        set __form_ids_list [list [random]]
        set __qf_arr(form_id) $__form_ids_list
    }
    # default to last modified form_id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { $form_id ne "" } {
        if { $form_id in $__form_ids_list } {
            set attributes_arr(form_id) $form_id
        } else {
            ns_log Notice "qf_bypass_nv_list.1154: form_id '${form_id}' not known. Using last modified form."
        }
    }

    set instance_id [ad_conn package_id]
    set sh_key_id $__qf_hc_arr($attributes_arr(form_id))
    foreach {arg_name arg_value} $args_list {
        if { $arg_name ne "" } {
            # pass via db for integrity of internal references
            db_dml qf_name_value_pairs_c { insert into qf_name_value_pairs
                (instance_id,sh_key_id,arg_name,arg_value) 
                values (:instance_id,:sh_key_id,:arg_name,:arg_value) }
        }
    }
    return 1
}



ad_proc -public qf_input {
    {arg1 ""}
    {value1 ""}
    args
} {
    Creates a form input tag, supplying attributes where nonempty values are supplied. when using CHECKED, set the attribute to 1.
    <br><br>
    Allowed attributes: type accesskey align alt border checked class id maxlength name readonly size src tabindex value title.
    <br><br>
    Other allowed: form_id label. label is used to wrap the input tag with a label tag containing a label that is associated with the input.
    <br><br>
    checkbox and radio inputs present label after input tag, other inputs are preceeded by label. Omit label attribute to not use this feature. Attribute label defaults to value of title attribute.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list
    upvar 1 __qf_hc_arr __qf_hc_arr
    # following two upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype


    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }

    # If mime type contains 'xml' self-closing tags are required.
    # The purpose of checking mime type is for helping to differentiate 
    # when to use the forwardslash before end angle-bracket 
    # in a markup language.  
    #  Only xhtml and xml require a forwardslash before end angle-bracket 
    # in tags without end tags.. and only for INPUT tag in FORMs paradigm.
    # Adding a forwardslash may break markup language validation
    # in some html4 and is optional in html5. 
    # Subsequently, only xml needs to be differentiated.
    # For more discussion, see:
    # https://stackoverflow.com/questions/3558119/are-non-void-self-closing-tags-valid-in-html5#5047150
    #  This code based on template::get_mime_type

    set __qf_doctype [qf_doctype]
    set forwardslash ""
    if { $__qf_forwardslash_p } {
        set forwardslash "/"
    }

    
    #was
    #set attributes_tag_list /list type accesskey align alt border checked class id maxlength name readonly size src tabindex value/
    set attributes_tag_list [qf_doctype_tag_attributes $__qf_doctype input]

    set attributes_full_list $attributes_tag_list

    # datatype and form_tag_type is used with qfo_2g paradigm. See proc qfo_2g.
    lappend attributes_full_list form_id label selected title datatype form_tag_type

    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact -nocase $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attribute_lc [string tolower $attribute]
            set attributes_arr(${attribute_lc}) $value
            if { [lsearch -exact $attributes_tag_list $attribute_lc] > -1 } {
                lappend attributes_list $attribute_lc
            }
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_input.1027: '${attribute}' is not a valid attribute. arg_list '${arg_list}' doctype '${__qf_doctype}'"
        }
    }

    if { [info exists attributes_arr(label)] } {
        set attributes_arr(label) [string trim $attributes_arr(label)]
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Notice "qf_input.1032: invoked before qf_form or used in a different namespace than qf_form.."
        set __qf_remember_attributes 0
    }
    if { ![info exists __form_ids_list] } {
        ns_log Warning "qf_input.1036: invoked before qf_form or used in a different namespace than qf_form.."
        set __form_ids_list [list [random]]
        set __qf_arr(form_id) $__form_ids_list
    }
    # default to last modified form_id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_input.1045: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr(${attribute})] && [info exists __qf_arr(input_${attribute})] } {
                set attributes_arr(${attribute}) $__qf_arr(input_${attribute})
            }
        }
    }

    # provide a blank value by default
    if { ![info exists attributes_arr(value)] } {
        set attributes_arr(value) ""
        lappend attributes_list "value"
    }
    # convert a "selected" parameter to checked
    if { ([info exists attributes_arr(selected)] && $attributes_arr(selected) eq "1") && ![info exists attributes_arr(checked)] } {
        set attributes_arr(checked) $attributes_arr(selected)
        lappend attributes_list "checked"
    }

    # by default, wrap the input with a label tag for better UI, part 1
    if { [info exists attributes_arr(label)] && [info exists attributes_arr(type) ] && $attributes_arr(type) ne "hidden" } {
        if { ![info exists attributes_arr(id) ] && [info exists attributes_arr(name) ] } {
            set attributes_arr(id) $attributes_arr(name)
            append attributes_arr(id) "-" [string range [clock clicks -milliseconds] end-3 end] "-" [string range [random ] 2 end]
            lappend attributes_list "id"
        }
        if { [info exists attributes_arr(title) ] } {
            set label_title $attributes_arr(title)
            unset attributes_arr(title)
            set title_idx [lsearch -exact $attributes_list "title" ]
            set attributes_list [lreplace $attributes_list $title_idx $title_idx ]
        }
    }
    # prepare attributes to process
    set tag_attributes_list [list]
    set tag_suffix ""
    foreach attribute $attributes_list {
        set __qf_arr(input_${attribute}) $attributes_arr(${attribute})
        if { $attribute ne "checked" && $attribute ne "disabled" } {
            lappend tag_attributes_list $attribute $attributes_arr(${attribute})
        } else {
            if { $__qf_doctype eq "xml" } {
                lappend tag_attributes_list $attribute $attribute
            } else {
                set tag_suffix " "
                append tag_suffix $attribute
                # set to checked or disabled
            }
        }
    }

    if { ![info exists attributes_arr(id) ] && [info exists attributes_arr(value) ] } {
        set attributes_arr(id) [string range [clock clicks -milliseconds] end-3 end]
        append attributes_arr(id) "-" [string range [random ] 2 end]
        lappend attributes_list "id"
    }

    # by default, wrap the input with a label tag for better UI, part 2
    if { [info exists attributes_arr(label)] && [info exists attributes_arr(type) ] && $attributes_arr(type) ne "hidden" } {
        if { $attributes_arr(type) eq "checkbox" || $attributes_arr(type) eq "radio" } {
            set tag_html "<label for=\""
            append tag_html $attributes_arr(id) "\""
            if { [info exists label_title] } {
                append tag_html " title=\"" $label_title "\""
            }
            append tag_html "><input" [qf_insert_attributes ${tag_attributes_list}]
            append tag_html $tag_suffix $forwardslash ">"
            append tag_html $attributes_arr(label) "</label>"
        } else {
            set tag_html "<label for=\""
            append tag_html $attributes_arr(id) "\""
            if { [info exists label_title] } {
                append tag_html " title=\"" $label_title "\""
            }
            append tag_html ">" $attributes_arr(label) "<input"
            append tag_html [qf_insert_attributes $tag_attributes_list] 
            append tag_html $forwardslash "></label>"
        }
    } else {
        if { [info exists attributes_arr(type)] && $attributes_arr(type) eq "hidden" } {
            if { [info exists __qf_hc_arr($attributes_arr(form_id))] && $__qf_hc_arr($attributes_arr(form_id)) > 0 } {
                # pass via db for integrity of internal references
                set instance_id [ad_conn package_id]
                set sh_key_id $__qf_hc_arr($attributes_arr(form_id))
                set arg_name_idx [lsearch -exact $tag_attributes_list name]
                set arg_name [lindex $tag_attributes_list $arg_name_idx+1]
                set arg_value_idx [lsearch -exact $tag_attributes_list value]
                set arg_value [lindex $tag_attributes_list $arg_value_idx+1]
                db_dml qf_name_value_pairs_c { insert into qf_name_value_pairs
                    (instance_id,sh_key_id,arg_name,arg_value) 
                    values (:instance_id,:sh_key_id,:arg_name,:arg_value) }
            }
            # and create some honey for sweet tooths regardless.
        }
        set tag_html "<input"
        append tag_html [qf_insert_attributes $tag_attributes_list] 
        append tag_html $tag_suffix $forwardslash ">"

    }

    # set results  __form_arr, we checked form_id above.
    append tag_html "\n"
    append __form_arr($attributes_arr(form_id)) $tag_html

    return $tag_html
}

ad_proc -public qf_append { 
    {arg1 ""}
    {value1 ""}
    args
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

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }

    set attributes_full_list [list html form_id]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr(${attribute}) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_append.1157: '${attribute}' is not a valid attribute."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Warning "qf_append.1163: invoked before qf_form or used in a different namespace than qf_form.."
        set __form_ids_list [list [random]]
        set __qf_arr(form_id) $__form_ids_list
    }
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
        lappend attributes_list form_id
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_append.1174: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }
    if { ![info exists attributes_arr(html)] } {
        set attributs_arr(html) ""
        ns_log Notice "qf_append.1179: no argument 'html'"
        if { [lsearch -exact $attributes_list "html"] == -1 } {
            set attributes_arr(html) ""
            lappend attributes_list "html"
        }
    }

    # set results  __form_arr, we checked form_id above.
    append __form_arr($attributes_arr(form_id)) $attributes_arr(html)
    return $attributes_arr(html)
}

ad_proc -private qf_insert_attributes {
    args_list
} {
    returns args_list of tag attribute pairs (attribute,value) as html to be inserted into a tag
} {
    set args_html ""
    foreach {attribute value} $args_list {
        # following range 1 1 changed to 0 0. Provided in case someone puts a dash as prefix to attribute
        if { [string range $attribute 0 0] eq "-" } {
            set $attribute [string range $attribute 1 end]
        }
        regsub -all -- {\"} $value {\"} value
        append args_html " " ${attribute} "=\"" ${value} "\""
    }
    return $args_html
}


ad_proc -public qf_choice {
    {arg1 ""}
    {value1 ""}
    args
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
    <p>For a complete example case, see tcl/adp files at q-forms/www/admin/test.tcl and test.adp</p>
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }

    #was set attributes_select_list /list value accesskey align class cols name readonly rows style tabindex title wrap/
    set __qf_doctype [qf_doctype]
    set attributes_select_list [qf_doctype_tag_attributes $__qf_doctype select]
    set attributes_input_list [qf_doctype_tag_attributes $__qf_doctype input]
    set attributes_full_list [concat $attributes_select_list $attributes_input_list]

    # datatype is used by qfo_g2 paradigm. See qfo_g2 proc.
    lappend attributes_full_list type form_id label datatype

    # A subset of attributes_list gets passed to wrapping tag (select or ul/input)
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact -nocase $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            # Force attribute to lowercase to reduce complexity in code later
            set attribute_lc [string tolower $attribute ]
            set attributes_arr(${attribute_lc}) $value
            lappend attributes_list $attribute_lc
        } elseif { $value eq "" } {
            # do nothing
        } else {
            ns_log Error "qf_choice.1283: '[string range ${attribute} 0 15]' is not a valid attribute."
            ad_script_abort
        }
    }

    # form_id needs to be passed to any qf_ api
    # default to last modified form_id
    set form_id_exists [info exists attributes_arr(form_id)]
    if { $form_id_exists == 0 || ( $form_id_exists == 1 && $attributes_arr(form_id) eq "" ) } { 
        set attributes_arr(form_id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_choice.1294: unknown form_id '$attributes_arr(form_id)'"
        ad_script_abort
    }
    lappend attributes_list form_id $attributes_arr(form_id)


    # if attributes_arr(type) = select, then items are option tags wrapped by a select tag
    # if attributes_arr(type) = radio, then items are input tags, wrapped in a list for now
    # if needing to paginate radio buttons, build the radio buttons using qf_input directly.
    if { ![string match -nocase "radio" $attributes_arr(type) ] } {
        set type "select"
        set label_wrap_tag "label"
    } else {
        # This forces a lowercase 'radio' to reduce complexity in logic
        set type "radio"
        set label_wrap_tag "fieldset"
    }

    # If a label is supplied, wrap the output with a LABEL tag.
    set label_wrap_start_html ""
    set label_wrap_end_html ""

    if { [info exists attributes_arr(label)] } {
        # wrap html with a LABEL tag. Wrap instead
        # of referring by id attribute, because html4 does not validate
        # when ID attribute is in a SELECT tag.
        set label_wrap_start_html "<${label_wrap_tag}>"
        if { $label_wrap_tag eq "fieldset" } {
            append label_wrap_start_html "<legend>"
            append label_wrap_start_html $attributes_arr(label)
            append label_wrap_start_html "</legend>\n"
        } else {

            append label_wrap_start_html $attributes_arr(label)
        }

        set label_wrap_end_html "</${label_wrap_tag}>"
    }

    # At this point, the buffer for returned html vs. value supplied to form_id diverge,
    # because return_html collects all output, whereas args_html is supplied to form_id
    # as needed by the convenience of calling qf_input, qf_append etc.

    set args_html $label_wrap_start_html    
    set return_html [qf_append form_id $attributes_arr(form_id) html $args_html]
    set args_html ""

    # call qf_select if type is "select" instead of duplicating purpose of that code
    if { $type eq "radio" } {

        # create wrapping tag
        set tag_wrapping "ul"
        append args_html "<"
        append args_html $tag_wrapping

        # ignore proc parameters that are not tag attributes for the tag_wrapping tag
        # This is coded, so that later code can be adapted to change UL to 
        # something custom by parameter without changing code much.
        if { $tag_wrapping ne "" } {
            set attributes_wrap_list [qf_doctype_tag_attributes $__qf_doctype $tag_wrapping]
            foreach attribute $attributes_list {
                if { [lsearch -exact -nocase $attributes_wrap_list $attribute] > -1 } {
                    # quoting unquoted double quotes in attribute values, so as to not inadvertently break the tag
                    regsub -all -- {\"} $attributes_arr(${attribute}) {\"} attributes_arr(${attribute})
                    append args_html " " $attribute "=\"" $attributes_arr(${attribute}) "\""
                }
            }
        }
        append args_html ">\n"
        append return_html [qf_append form_id $attributes_arr(form_id) html $args_html]
        
        set args_html ""

        set tabindex_att_exists_p [info exists attributes_arr(tabindex) ]
        set label_c "label"
        set value_c "value"
        set name_c "name"
        set tabindex_c "tabindex"
        set unselected -1

        # input needs to be able to pass label..
        lappend attributes_input_list "label" "selected"

        foreach input_attributes_list $attributes_arr(value) {
            if { ![qf_is_even [llength $input_attributes_list ] ] } {
                ns_log Error "qf_choice.1804 'value' attribute count is odd. \
 arg_list '${arg_list}'. Issue at: value '${input_attributes_list}'"
                ad_script_abort
            }

            array set input_arr $input_attributes_list
            set input_names_list [array names input_arr]

            # screen out unqualified attributes
            foreach input_att_name $input_names_list {
                if { [lsearch -exact -nocase $attributes_input_list $input_att_name ] < 0 } {
                    ns_log Notice "qf_choice.1802: filtering attribute '${input_att_name}' from list '${input_attributes_list}'"
                    unset input_arr(${input_att_name})
                }
            }

            # Add a label based on value, if there isn't a label, but there is a value.
            set label_idx [lsearch -exact -nocase $input_names_list $label_c]
            if { $label_idx < 0 } {
                set value_idx [lsearch -exact -nocase $input_names_list $value_c]
                if { $value_idx > -1 } {
                    set v_name [lindex $input_names_list $value_idx]
                    set input_arr(label) $input_arr(${v_name}) 
                }
            }

            # pass the name from tag attribute to choice item, if name isn't included and this 
            if { [lsearch -exact -nocase $input_names_list $name_c ] < 0 } {
                if { [info exists attributes_arr(name)] } {
                    set input_arr(name) $attributes_arr(name)
                }
            }

            if { $tabindex_att_exists_p } {
                # pass tabindex from tag attribute to choice item (maybe), if tabindex isn't included
                set tab_idx [lsearch -exact -nocase $input_names_list $tabindex_c ] 
                if { $tab_idx > -1 } {
                    set ti_name [lindex $input_names_list $tab_idx]
                } else {
                    set ti_name $tabindex_c
                }
                if { [info exists input_arr(selected) ] } {
                    if { $input_arr(selected) eq 1 } {
                        set input_arr(${ti_name}) $attributes_arr(tabindex)
                    } else {
                        set input_arr(${ti_name}) $unselected
                    }
                } elseif { [info exists input_arr(checked) ] } {
                    if { $input_arr(checked) eq 1 } {
                        set input_arr(${ti_name}) $attributes_arr(tabindex)
                    } else {
                        set input_arr(${ti_name}) $unselected
                    }
                } else {
                        set input_arr(${ti_name}) $unselected
                }
            }

            set input_arr(type) "radio"
            set input_atts_list [array get input_arr]
            array unset input_arr

            lappend input_atts_list form_id $attributes_arr(form_id)

            append return_html [qf_append form_id $attributes_arr(form_id) html "<li>"]
            append return_html [qf_input $input_atts_list]
            append return_html [qf_append form_id $attributes_arr(form_id) html "</li>"]
            
        }
        append args_html "</" $tag_wrapping ">"

    } else {
        # type = select

        set select_list [list]
        lappend attributes_select_list value
        foreach attribute $attributes_list {
            if { [lsearch -exact $attributes_select_list $attribute] > -1 } {
                # create a list to pass to qf_select without it balking at unknown parameters
                lappend select_list $attribute $attributes_arr(${attribute})
            } 
        }

        append return_html [qf_select $select_list]

    }
    # \n is added here instead of after SELECT tag, in case a LABEL tag
    # wraps $args_html.
    append args_html $label_wrap_end_html "\n"
    append return_html [qf_append form_id $attributes_arr(form_id) html $args_html]
    return $return_html
}

ad_proc -public qf_choices {
    {arg1 ""}
    {value1 ""}
    args
} {
    returns html of a select multiple box or list  of checkboxes (where multiple values may be sent with form post).
    Required attributes:  name, value.  

    Set "type" to "select" for multi select box, or "checkbox" for checkboxes.


    The value of the "value" attribute is a list_of_lists, each list item contains attribute/value pairs for a radio or option/bar item.


    If "label" not provided for tags in the list_of_lists, the value of the "value" attribute is also used for label.


    Set "selected" attribute to 1 in the value list_of_lists to indicate item selected. Default is unselected (if selected attributed is not included, or its value not 1)..

<pre>
    Example usage. This code:

    set multi_choice_tag_attribute_list [list [list name card1 label " label1 " value visa1 selected 1] [list name card2 label " label2 " value visa2 selected 0] [list name card3 label " label3 " value visa3] ]
    qf_choices type checkbox value $multi_choice_tag_attribute_list

    Generates:

&lt;ul>
&lt;li>&lt;label for="card1-9713-9984053497942387">&lt;input value="visa1" name="card1" type="checkbox" id="card1-9713-9984053497942387" checked> label1 &lt;/label>
&lt;/li>&lt;li>&lt;label for="card2-9713-37947959533607684">&lt;input value="visa2" name="card2" type="checkbox" id="card2-9713-37947959533607684"> label2 &lt;/label>
&lt;/li>&lt;li>&lt;label for="card3-9713-7510373799725651">&lt;input value="visa3" name="card3" type="checkbox" id="card3-9713-7510373799725651"> label3 &lt;/label>
&lt;/li>&lt;/ul>

</pre>
    <p>The id and for attributes are auto generated when not supplied.</p>
    <p>For a complete example case, see tcl/adp files at q-forms/www/admin/test.tcl and test.adp</p>
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }


    # attributes_list are attribute/value pairs passed to structural, wrapping tag such as UL.
    set attributes_list [list]

    # Type attribute is needed to know attributes_full_list elements.
    # Save on overall processing by pre-processing 'type' attribute.
    # Avoid creating a blind array that may contain garbage input.
    set i 0
    set type_idx [lsearch -exact -nocase $arg_list "type"]
    set counter 0
    set arg_list_len [llength $arg_list]
    while { $type_idx > -1 && ![f::even_p $type_idx] && $counter < $arg_list_len } {
        incr type_idx
        incr counter
        ns_log Notice "qf_choices.1378. 'type' found as a value.. lsearching again. counter '${counter}' arg_list_len '${arg_list_len}'"
        set type_idx [lsearch -exact -index $type_idx -nocase $arg_list "type"]
    }
    if { $type_idx > -1 && [f::even_p $type_idx] } {
        set attributes_arr(type) [lindex $arg_list $type_idx+1]
    } else {
        set attributes_arr(type) ""
    }

    # if attributes_arr(type) = select, then items are option tags wrapped by a select tag
    # if attributes_arr(type) = checkbox, then items are input tags, wrapped in a list for now
    # if needing to paginate checkboxes, build the checkboxes using qf_input directly.
    # qf_doctype_tag_attributes requires calling qf_doctype first.
    set __qf_doctype [qf_doctype]
    if { $attributes_arr(type) ne "checkbox" } {
        set type "select"
        set attributes_select_list [qf_doctype_tag_attributes $__qf_doctype select]
        set attributes_full_list $attributes_select_list

        # datatype is used by qfo_g2 paradigm. See proc qfo_g2
        lappend attributes_full_list value datatype
    } else {
        set type "checkbox"
        set attributes_input_list [qf_doctype_tag_attributes $__qf_doctype input]
        set attributes_full_list $attributes_input_list
    }

    # datatype is used by qfo_g2 paradigm. See proc qfo_g2
    lappend attributes_full_list type form_id id label datatype multiple
    
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact -nocase $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attribute_lc [string tolower $attribute ]
            set attributes_arr(${attribute_lc}) $value
            lappend attributes_list $attribute_lc
        } else {
            ns_log Error "qf_choices.1416: [string range ${attribute} 0 15] is not a valid attribute. invoke with attribute value pairs. attributes_full_list '${attributes_full_list}' type '${type}' arg_list '${arg_list}'"
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
        ns_log Error "qf_choices.1428: unknown form_id $attributes_arr(form_id)"
        ad_script_abort
    }


    set return_html ""
    set label_wrap_start_html ""
    set label_wrap_end_html ""
    if { [info exists attributes_arr(label)] } {

        if { $type eq "checkbox" } {
            set label_wrap_tag "fieldset"
        } else {
            set label_wrap_tag "label"
        }
        # wrap html with a LABEL tag. Wrap instead
        # of referring by id attribute, because html4 does not validate
        # when ID attribute is in a SELECT tag.

        # FIELDSET/LEGEND may be more appropriate to avoid nested LABEL tags
        
        set label_wrap_start_html "<${label_wrap_tag}>"

        if { $label_wrap_tag eq "fieldset" } {
            append label_wrap_start_html "<legend>"
            append label_wrap_start_html $attributes_arr(label)
            append label_wrap_start_html "</legend>\n"
        } else {
            append label_wrap_start_html $attributes_arr(label)
        }

        append return_html [qf_append html $label_wrap_start_html form_id $attributes_arr(form_id)]

        append label_wrap_end_html "</${label_wrap_tag}>"
    }

    
    # call qf_select if type is "select" instead of duplicating purpose of that code
    set args_html ""
    if { $type eq "checkbox" } {

        # input_list are attribute_value pairs passed to qf_input
        set input_list [list]
        lappend input_list form_id $attributes_arr(form_id)

        foreach attribute $attributes_list {
            if { [lsearch -exact $attributes_input_list $attribute ] > -1 } {
                # create a list to pass to qf_input without it balking at unknown parameters
                lappend input_list $attribute $value
            }
        }

        # create wrapping tag
        set tag_wrapping "ul"
        set attributes_wrap_list [qf_doctype_tag_attributes $__qf_doctype $tag_wrapping]
        append args_html "<"
        append args_html $tag_wrapping
        foreach attribute $attributes_list {
            # ignore proc parameters that are not tag attributes
            if { [lsearch -exact -nocase $attributes_wrap_list $attribute] > -1 } {
                # quoting unquoted double quotes in attribute values, so as to not inadvertently break the tag
                regsub -all -- {\"} $attributes_arr(${attribute}) {\"} attributes_arr(${attribute})
                append args_html " " $attribute "=\"" $attributes_arr(${attribute}) "\""
            }
        }
        append args_html ">\n"
        set return_html [qf_append form_id $attributes_arr(form_id) html $args_html]
        set args_html ""

        set unselected -1
        set label_c "label"
        set value_c "value"
        set name_c "name"
        set tabindex_c "tabindex"
        foreach input_attributes_list $attributes_arr(value) {
            if { ![qf_is_even [llength $input_attributes_list ] ] } {
                ns_log Error "qf_choices.2091 'value' attribute count is odd. \
 arg_list '${arg_list}'. Issue at: value '${input_attributes_list}'"
                ad_script_abort
            }

            array set input_arr $input_attributes_list
            set input_names_list [array names input_arr]
            set label_idx [lsearch -exact -nocase $input_names_list $label_c ]
            set value_idx [lsearch -exact -nocase $input_names_list $value_c ]
            if { $label_idx < 0 && $value_idx > -1 } {
                set label_n [lindex $input_names_list $label_idx ]
                set value_n [lindex $input_names_list $value_idx ]
                set input_arr(${label_n}) $input_arr(${value_n})
            } 
            set name_idx [lsearch -exact -nocase $input_names_list $name_c ]
            if { $name_idx < 0 && [info exists attributes_arr(name)] } {
                set name_n [lindex $input_names_list $name_idx ]
                set input_arr(${name_n}) $attributes_arr(name)
            }
            if { [info exists attributes_arr(tabindex)] } {
                set tab_idx [lsearch -exact -nocase $input_names_list $tabindex_c ]
                if { $tab_idx > -1 } {
                    set ti_name [lindex $input_names_list $tab_idx]
                } else {
                    set ti_name $tabindex_c
                }
                # set the tabindex the same for all for consistent context
                set input_arr(${ti_name}) $attributes_arr(tabindex)

            }
            set input_attributes_list [array get input_arr]
            array unset input_arr

            lappend input_attributes_list form_id $attributes_arr(form_id) type checkbox
            append return_html [qf_append form_id $attributes_arr(form_id) html "<li>"]
            append return_html [qf_input $input_attributes_list]
            append return_html [qf_append form_id $attributes_arr(form_id) html "</li>"]

        }
        set tag_wrapping_arg "</"
        append tag_wrapping_arg $tag_wrapping ">"

        append return_html [qf_append form_id $attributes_arr(form_id) html $tag_wrapping_arg]
            


    } else {
        # select_list are attribute/value pairs passed to qf_select
        set select_list [list]
        lappend attributes_select_list value
        foreach attribute $attributes_list {
            if { [lsearch -exact $attributes_select_list $attribute ] > -1 } {
                # create a list to pass to qf_select without it balking at unknown parameters
                lappend select_list $attribute $attributes_arr(${attribute})
            }
        }
        lappend select_list multiple 1
        append return_html [qf_select $select_list]
    }

    append label_wrap_end_html "\n"

    append return_html [qf_append form_id $attributes_arr(form_id) html $label_wrap_end_html ]
    
    return $return_html
}

ad_proc -private qf_doctype_tag_attributes {
    doctype
    tag
} {
    Returns a list of valid attributes for a specific markup tag. 
    For example, if doctype is 'html4', and markup_tag is INPUT, returns a list including 'name' 'value' and like.
} {
    switch -- $doctype {
        html4 {
            set attrs_list [qf_html4_tag_attributes $tag]
        }
        html5 {
            set attrs_list [qf_html5_tag_attributes $tag]
        }
        xml {
            set attrs_list [qf_xml_tag_attributes $tag]
        }
        default {
            set attrs_list [list ]
        }
    }
    return $attrs_list
}

ad_proc -private qf_html4_tag_attributes {
    tag
} {
    Returns a list of valid attributes for a generic strict html4.
    For example, if tag is INPUT, returns a list including 'name' 'value' and like.  
    Does not include event attributes such as 'onsubmit' or 'onreset'.
} {
    # This could parse the DTD spec if full DOCTYPE available..
    # Does not include event attributes
    set attr_list [list id class style title lang dir]
    switch -- $tag {
        form {
            lappend attr_list action method enctype accept name
        }
        fieldset {
            lappend attr_list accesskey]
        }
        textarea {
            lappend attr_list name rows cols disabled readonly tabindex accesskey
        }
        select {
            lappend attr_list name size multiple disabled tabindex disabled
        }
        input {
            lappend attr_list type name value checked disabled readonly size maxlength src alt usemap ismap tabindex accesskey alt align accept
        }
        optgroup {
            lappend attr_list selected disabled label
        }
        option {
            lappend attr_list selected value label disabled
        }
        default {
            set attr_list [list ]
        }
    }
    return $attr_list
}

ad_proc -private qf_html5_tag_attributes {
    tag
} {
    Returns a list of valid attributes for a generic strict html5.
    For example, if tag is INPUT, returns a list including 'name' 'value' and like.  
    Does not include event attributes such as 'onsubmit' or 'onreset'.
} {
    # This could parse the DTD spec if full DOCTYPE available..
    # Does not include event attributes

    # global attributes
    set attr_list [list title lang translate dir style]
    switch -- $tag {
        form {
            lappend attr_list action method enctype accept name autocomplete novalidate
        }
        fieldset {
            lappend attr_list accesskey
        }
        textarea {
            lappend attr_list name rows cols disabled readonly tabindex accesskey maxlength autofocus dirname form placeholder required wrap
        }
        select {
            lappend attr_list name size multiple disabled tabindex id class lang title style disabled tabindex
        }
        input {
            lappend attr_list type name value checked disabled readonly size maxlength src alt usemap ismap tabindex accesskey accept id class alt align autocomplete autofocus height width list min max multiple pattern placeholder required step
        }
        optgroup {
            lappend attr_list selected disabled label id class
        }
        option {
            lappend attr_list selected value label id class disabled
        }
        default {
            set attr_list [list ]
        }
    }
    return $attr_list
}


ad_proc -private qf_xml_tag_attributes {
    tag
} {
    Returns a list of valid attributes for generic strict xml.
    For example, if doctype is 'html4', and markup_tag is INPUT, returns a list including 'name' 'value' and like.
    Does not include Event Attributes, such as onmouseup, onkeypress, onmouseover and the like.
} {
    # not included: xml:lang and other xml:* attributes
    # See: https://www.w3.org/2010/04/xhtml10-strict.html
    # This could parse the DTD spec if full DOCTYPE available..
    switch -- $tag {
        form {
            set attr_list [list style onreset accept accept-charset id title method onsubmit class enctype lang action dir]
        }
        fieldset {
            set attr_list [list style lang title id class dir]
        }
        textarea {
            set attr_list [list style cols disabled onchange rows readonly onselect onfocus accesskey onblur name inputmode tabindex]
        }
        select {
            set attr_list [list style disabled onchange id size title onfocus onblur multiple class lang name dir tabindex]
        }
        input {
            set attr_list [list style accesskey accept disabled usemap alt onchange id size checked title readonly onselect onfocus type onblur class lang src name value maxlength dir tabindex]
        }
        optgroup {
            set attr_list [list style disabled id class lang title label dir]
        }
        option {
            set attr_list [list style disabled id class lang title selected value label dir]
        }
        default {
            set attr_list [list ]
        }
    }
    return $attr_list
}


ad_proc -public qf_doctype {
    {doctype ""}
} {
    Returns the root DOCTYPE from doc(type) if it exists, otherwise from doctype. If doctype is empty string, uses value from q-forms parameter defaultDocType. If doctype is html, also returns version of html if inferable in reference.
    <br><br>
    The purpose of this proc is for helping to determine the standard validation doctype used to assist in generating valid markup. For example, to see if a form attribute is valid or not for the doc type.
    <br><br>
    For faster repeat processing, make sure any namespace relying on this proc repeats the set of <code>upvar</code> delcared in this proc's source.
}  {
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __forwardslash_p
    upvar 1 __qf_doctype __doctype


    # This proc should validate doctype against mime type to be consistent.
    if { ![info exists __forwardslash_p ] } {
        # Following line is based on template::get_mime_type
        set mime_type [ns_set iget [ns_conn outputheaders] "content-type"]
        if { $mime_type ne "" } {
            # check for xml and xhtml
            set __forwardslash_p [string match "*x*ml" $mime_type]
        } else {
            set __forwardslash_p 0
        }
    }

    if { ![info exists __doctype] } {
        set doc_type ""
        if { [info exists doc(type)] } {
            set doctype $doc(type)
        }
        if { $doctype ne "" } {
            if { [string match -nocase "*doctype*" $doctype] } {
                # parse 
                switch -glob -nocase -- $doctype {
                    "*html*4*" {
                        set doc_type "html4"
                    }
                    "*html*5*" {
                        set doc_type "html5"
                    }
                    "*x*ml*" {
                        # pattern works for xhtml or xml
                        set doc_type "xml"
                    }
                    default {
                        if { [string match -nocase "*html*" $doctype ] } {
                            set doc_type "html5"
                        } else {
                            ns_log Warning "qf_doctype.2377 \
 Unable to parse doctype '${doctype}'."
                        }
                    }
                }
            } else {
                ns_log Warning "qf_doctype.2382 \
 Unable to parse doctype '${doctype}'."
            }
        }
        if { $doc_type eq "" } {
            # Is parameter defined locally in package?
            set doc_type [parameter::get \
                              -parameter defaultDocType \
                              -package_id [ad_conn package_id] \
                              -default ""]
            
            if { $doc_type eq "" } {
                # Use the q-forms package parameter.
                set doc_type [parameter::get_from_package_key \
                                  -parameter defaultDocType \
                                  -package_key q-forms \
                                  -default "html4"]
            }
            
        }
        set xml_doctype_p [string match -nocase "x*" $doc_type]
        if { $__forwardslash_p != $xml_doctype_p } {
            ns_log Warning "qf_doctype.1873: mime type does not match doctype.\
 __forwardslash_p '${__forwardslash_p} xml_doctype_p '${xml_doctype_p}'"
        }
        set __doc_type $doc_type
    } else {
        set doc_type $__doctype
    }
    return $doc_type
}


ad_proc -public qf_element {
    {arg1 ""}
    {value1 ""}
    args
} {
    Returns an html or xml element consisting of a consistent structure based on tag type and passed content and/or attributes (as a tcl name value list).
    Does not get passed to a form_id.
<br><br>
    Accepts name value pairs, where name is: tag, attribute_nv_list or content.
<br><br>
    tag is the tag of the element.
    For example, if element is '&lt;hr />', tag is 'hr'.
<br><br>
    attribute_nv_list is the name value list to add to the element as attributes. 
If list consists of 'class test', then continuing the hr example, attributes are added like so:
    &lt;hr class="test" />
<br><br>
    content is the information wrapped by the element, if any.
    For example, if tag is 'p', then content is: &lt;p>content&lt;/p>.
<br><br>
    No validation is performed on generated markup.
} {
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __forwardslash_p
    upvar 1 __qf_doctype __doctype

    # collect args
    if { [llength $arg1] > 1 && $value1 eq "" } {
        set arg_list $arg1
        foreach arg $args {
            lappend args_list $arg
        }
    } elseif { $arg1 ne "" } {
        lappend args $arg1 $value1
        set arg_list $args
    } else {
        set arg_list [list ]
    }
    
    set names_list [list tag attribute_nv_list content]
    foreach n $names_list {
        set n_idx [lsearch -exact -nocase $arg_list $n] 
        if { $n_idx > -1 } {
            set $n [lindex $arg_list $n_idx+1]
        } else {
            set $n ""
        }
    }
    set element ""
    if { $tag ne "" } {
        set empty_tag_list [list br hr img input link meta param base]
        set __qf_doctype [qf_doctype]
        set element "<"
        append element $tag 
        # append attributes. Some Empty tags may have attributes.
        foreach {n v} $attribute_nv_list {
            append element " \"" $n "\"=\"" $v "\""
        }
        if { $__qf_doctype ne "xml" \
                 && [lsearch -nocase -exact $empty_tag_list $tag] > -1 } {
            # self closed tags are allowed and expected
            append element " />"
        } else {
            # Use a separate close tag, do not use single tag and />
            append element ">" $content "</" $tag ">"
        }
    } else {
        ns_log Warning "qf_element: tag is empty. Ignoring. arg_list '${arg_list}'"
    }
    return $element
}

ad_proc -public qf_button_form {
    args
} {
    Accepts name value pairs as attributes of FORM and INPUT type SUBMIT form.
    Returns html of a form with one button.
    The first name,value, and label are assigned to the button.
    Subsequent name/value pairs are assigned to INPUT tags of type 'hidden'.
    Names other than ones attributable to qf_form are ignored.
    This proc doesn't provide style, class, or id to qf_form.
} {
    # add upvars from qf_form, in case multiple qf_forms invoked
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __form_ids_open_list __form_ids_open_list
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __qf_hc_arr __qf_hc_arr
    # following three upvars are for qf_doctype
    upvar 1 doc doc
    upvar 1 __qf_forwardslash_p __qf_forwardslash_p
    upvar 1 __qf_doctype __qf_doctype

    set form_list [list action id method hash_check ]
    set button_list [list name value class style id label ]
    set hidden_list [list name value ]
    # set defaults
    set names_list [concat $form_list $button_list $hidden_list ]
    foreach name $names_list {
	set name_larr(${name}) [list ]
    }
    foreach {n v} $args {
	set nlc [string tolower $n]
	lappend name_larr(${nlc}) $v
    }

    
    # Reverse button/form order, because style class expected to go with button
    set button_atts_list [list type submit ]
    # set default button_id
    set button_id "button"
    foreach name $button_list {
	set value [lindex $name_larr(${name}) 0]
	if { $value eq "" && $name ne "value" } {
	    # skip
	} else {
	    lappend button_atts_list $name $value
	    if { $name eq "id" } {
		set button_id $value
	    }
	}
	
	set name_larr(${name}) [lrange $name_larr(${name}) 1 end]
    }

    set form_atts_list [list ]
    foreach name $form_list {
	set value [lindex $name_larr(${name}) 0]
	if { $value eq "" && $name ne "value" } {
	    # mostly skip
	    if { $name eq "id" } {
		append button_id "-form"
		lappend form_atts_list $name $button_id
	    }
	} else {
	    lappend form_atts_list $name $value
	}
	set name_larr(${name}) [lrange $name_larr(${name}) 1 end]
    }
    

    set form_id [qf_form $form_atts_list]

    qf_input $button_atts_list

    set i 0
    foreach name $name_larr(name) {
	if { $name ne "" } {
	    qf_input type hidden name $name value [lindex $name_larr(value) $i]
	}
	incr i
    }
    qf_close form_id $form_id
    
    set form_html [qf_read form_id $form_id ]
    return $form_html
    
}
