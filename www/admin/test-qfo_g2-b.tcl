set title "#acs-subsite.Administration#"
set context [list ]

# choice
set type1 "radio"
#set type1 "select"
# choices
set type2 "checkbox"
#set type2 "select"


set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set admin_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
if { !$admin_p } {
    ad_redirect_for_registration
    ad_script_abort
}


set one_choice_tag_attribute_list [list [list label " label A " value a ] \
                                       [list label " label B " value b ] \
                                       [list label " label C " value c selected 1 ] ]

set sample_abc_lol [list type $type1 name sample_abc label "Choose one" value $one_choice_tag_attribute_list ]


set multi_choice_tag_attribute_list [list \
                                         [list name item_d label " label D " value d selected 1 ] \
                                         [list name item_e label " label E " value e selected 0 ] \
                                         [list name item_f label " label F " value f ] ]

set multiple_lol [list type $type2 label "Choose any" name sample_dce value $multi_choice_tag_attribute_list multiple 1 ]


set f_lol [list \
               $sample_abc_lol \
               [list type text value "example textarea value" name "input_text" label "input text" size 40 maxlength 80 ] \
               $multiple_lol \
               [list type submit name charlie value bravo tabindex 9 datatype text_nonempty] \
               [list tabindex 8 type submit name submit value "#acs-kernel.common_Save#" datatype text_nonempty]
              ]

set form_html ""
qfo_form_list_def_to_array \
    -list_of_lists_name f_lol \
    -array_name f_arr \
    -ignore_parse_issues_p 0


set validated_p [qfo_2g \
                     -form_id 20180425 \
                     -fields_array f_arr \
                     -form_varname form_html \
                     -multiple_key_as_list 1 ]

set content "choice type: $type1<br>choices type: $type2<br><br>"
if { $validated_p } {

    append content "<pre>f_arr:<br>"
    append content "<ul>"
    foreach name [array names f_arr] {
        append content "<li>'${name}' : '$f_arr(${name})'</li>\n"
        ns_log Notice "test-qo_g2.tcl f_arr(${name}) '$f_arr(${name})'"
    }
    append content "</ul>"

    # output inputs
    append content "<pre>Validated name values returned:<br>"
    append content "<ul>"
    foreach name [array names qfi_arr] {
        append content "<li>'${name}' : '$qfi_arr(${name})'</li>\n"
        ns_log Notice "test-qo_g2.tcl qfi_arr(${name}) '$qfi_arr(${name})'"
    }
    append content "</ul>"

}



append content "<pre>\n"
append content $form_html
append content " &nbsp; &nbsp; &nbsp; <a href=\"test-qfo_g2\">clear</a>"
append content "</pre>"



