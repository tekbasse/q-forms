set title "#acs-subsite.Administration#"
set context [list ]

set doc(type) {<!DOCTYPE html>}

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
set page_url [ad_conn url]

set one_choice_tag_attribute_list [list [list label " label A " value a ] \
                                       [list label " label B " value b ] \
                                       [list label " label C " value c selected 1 ] ]

set sample_abc_lol [list type $type1 name sample_abc label "Choose one<br>" value $one_choice_tag_attribute_list ]


set multi_choice_tag_attribute_list [list \
                                         [list name item_d label " label D " value d selected 1 ] \
                                         [list name item_e label " label E " value e selected 0 ] \
                                         [list name item_f label " label F " value f ] ]

set multiple_lol [list type $type2 label "Choose any<br>" name sample_dce value $multi_choice_tag_attribute_list multiple 1 ]

set f_lol_unused [list \
                      ]

set f_lol [list \
               [list name a_decimal datatype decimal label "Enter a decimal number" ] \
               [list name a_nat_num datatype natural_num label "Enter a natural number" ] \
               [list name integer_1_to_6 datatype range_integer min 0 max 6 "An integer between 0 and 6 inclusive" ] \
               [list name integers_0_2_10 datatype range_integers min 0 max 10 label "An integer between 0 and 10 inclusive" ] \
                $sample_abc_lol \
               [list type text value "example textarea value" name "input_text" label "Enter some text<br>" size 40 maxlength 80 ] \
               $multiple_lol \
               [list name nonempty1 datatype text_nonempty label "You must enter something<br>" ] \
               [list name a_word datatype text_word label "A word, just one --or leave emtpy<br>" ] \
               [list type submit name charlie value bravo tabindex 90 datatype text_nonempty label "Use this alternate button to save, if you like:" ] \
               [list tabindex 88 type submit name submit value "#acs-kernel.common_Save#" datatype text_nonempty label "When you are finished click this button:" ] \

              ]

set form_html ""
::qfo::form_list_def_to_array \
    -list_of_lists_name f_lol \
    -fields_ordered_list_name qf_fields_ordered_list \
    -array_name f_arr \
    -ignore_parse_issues_p 0


set validated_p [qfo_2g \
                     -form_id 20180425 \
                     -fields_ordered_list $qf_fields_ordered_list \
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
append content " &nbsp; &nbsp; &nbsp; <a href=\"" ${page_url} "\">clear</a>"
append content "</pre>"



