set title "#acs-subsite.Administration#"
set context [list ]



set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set admin_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
if { !$admin_p } {
    ad_redirect_for_registration
    ad_script_abort
}

set one_choice_tag_attribute_list [list [list label " label1 " value visa1] [list label " label2 " value visa2] [list label " label3 " value visa3] ]

set multi_choice_tag_attribute_list [list [list name card1 label " label1 " value visa1 selected 1] [list name card2 label " label2 " value visa2 selected 0] [list name card3 label " label3 " value visa3] ]

set f_lol [list \
               [list type text value "example value" name "input_text" label "input text" size 40 maxlength 80 ] \
               [list type radio name creditcard value $one_choice_tag_attribute_list ] \
               [list type checkbox value $multi_choice_tag_attribute_list ] \
               [list type submit name charlie value bravo tabindex 9] \
               [list tabindex 8 type submit name submit value "#acs-kernel.common_Save#"]
              ]

qfo_form_list_def_to_array \
    -array_name f_arr \
    -list_of_lists_name f_lol \
    -ignore_parse_issues_p 0

set validated_p [qfo_2g \
                     -form_id 20180425 \
                     -fields_array f_arr \
                     -form_varname form_html \
                     -hash_check 1]



append content "<pre>\n"
append content $form_html
append content " &nbsp; &nbsp; &nbsp; <a href=\"test-qfo_g2\">clear</a>"
append content "</pre>"


