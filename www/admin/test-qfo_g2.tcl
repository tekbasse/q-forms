set title "#acs-subsite.Administration#"
set context [list ]



set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set admin_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
if { !$admin_p } {
    ad_redirect_for_registration
    ad_script_abort
}
set f_lol [list ]

qfo_form_list_def_to_array \
    -array_name f_arr \
    -list_of_lists_name f_lol \
    -ignore_parse_issues_p 0

set validated_p [qfo_2g \
                     -fields_array f_arr \
                     -form_varname form_html \
                     -hash_check 1]

append content "<pre>\n"
append content $form_html
append content "</pre>"

set input_text $input_arr(input_text)
qf_form action test method post id 20160904 hash_check 1
qf_bypass_nv_list [list name1 val1 name2 val2 name3 3 name4 4 name5 -5.14 -name6 -6.268]
qf_bypass name qf_bypass_name value qf_bypass_value
qf_input type text value $input_text name "input_text" label "input text" size 40 maxlength 80
qf_input type hidden name blank1 value ""
qf_bypass name blank2 value ""
qf_bypass value qf_value2 name qf_name2
qf_bypass_nv_list [list n1 v1 n2 v2 n3 3 n4 4 n5 -5 -n6 6 blank3 ""]

set one_choice_tag_attribute_list [list [list label " label1 " value visa1] [list label " label2 " value visa2] [list label " label3 " value visa3] ]

qf_choice type radio name creditcard value $one_choice_tag_attribute_list

set multi_choice_tag_attribute_list [list [list name card1 label " label1 " value visa1 selected 1] [list name card2 label " label2 " value visa2 selected 0] [list name card3 label " label3 " value visa3] ]

qf_choices type checkbox value $multi_choice_tag_attribute_list

qf_input type submit name charlie value bravo

qf_input type submit value "#acs-kernel.common_Save#"
qf_append html " &nbsp; &nbsp; &nbsp; <a href=\"test\">"
qf_close
append content [qf_read]
