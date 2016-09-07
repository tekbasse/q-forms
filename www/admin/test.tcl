set title "#acs-subsite.Administration#"
set context [list ]



set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set admin_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
if { !$admin_p } {
    ad_redirect_for_registration
    ad_script_abort
}

set input_arr(input_text) "some text"
set form_posted_p [qf_get_inputs_as_array input_arr hash_check 1]
set content "<pre>\n"
if { !$form_posted_p } {
   append content "form not posted."
} else {
    append content "form posted.

values:\n\n"
    foreach key [array names input_arr] {
        append content "${key}: '$input_arr(${key})' \n"
    }
    #set content $input_arr(a)
    # flush old forms
}
append content "
</pre>"

set input_text $input_arr(input_text)
qf_form action test method post id 20160904 hash_check 1
qf_bypass_nv_list [list name1 val1 name2 val2 name3 3 name4 4 name5 -5.14 -name6 -6.268]
qf_bypass name qf_bypass_name value qf_bypass_value
qf_input type text value $input_text name "input_text" label "input text" size 40 maxlength 80
qf_bypass value qf_value2 name qf_name2
qf_bypass_nv_list [list n1 v1 n2 v2 n3 3 n4 4 n5 -5 -n6 6]
qf_input type submit value "#acs-kernel.common_Save#"
qf_append html " &nbsp; &nbsp; &nbsp; <a href=\"test\">"
qf_close
append content [qf_read]
