ad_library {
    Automated tests for q-forms
    @creation-date 2017-04-09
}

aa_register_case -cats {api smoke} qf_form_checks {
    Test multiple concurrent form and tag making features
} {
    aa_run_with_teardown \
        -test_code {
            #         -rollback \
            ns_log Notice "qf_form_tests.12: Begin test"
            foreach doctype [list html4 html5] {
                array unset f_net_len_arr
                array unset f_arr
                array unset f_str_len_arr
                array unset f_id_len_arr
                if { [info exists __form_ids_list] } {
                    unset __form_ids_list
                    array unset __form_arr
                    array unset __form_ids_open_list
                    array unset __qf_arr
                    array unset qf_hc_arr
                }
                aa_log "Using doctype '$doctype'"
                qf_doctype $doctype
                aa_log "create three forms with default id"
                set f1_id [qf_form ]
                set f2_id [qf_form ]
                set f3_id [qf_form ]
                set f1_ne_f2 [expr { $f1_id ne $f2_id } ]
                set f2_ne_f3 [expr { $f2_id ne $f3_id } ]
                aa_true "1. id form1 ${f1_id} does not equal form2 ${f2_id}" $f1_ne_f2
                aa_true "2. id form2 ${f2_id} does not equal form3 ${f3_id}" $f2_ne_f3
                set f4_id [qf_form form_id test4 id test7]
                set f5_id [qf_form id test5]
                set f4_ne_f5 [expr { $f4_id ne $f5_id } ]
                aa_true "3. id form4 ${f4_id} does not equal form5 ${f5_id}" $f4_ne_f5

                set form_ids_list [list $f1_id $f2_id $f3_id $f4_id $f5_id]
                aa_log "Adding one of each kind of form element to each form id: ${form_ids_list}"
                foreach id $form_ids_list {
                    qf_input form_id $id label L1 name input1 value $id
                    qf_textarea form_id $id label L2 name input2 value $id
                    set val_lol [list [list value $id]]
                    qf_select form_id $id name input3 value $val_lol
                }
                qf_close
                aa_log "Verifying each form is consistent and different."
                foreach id $form_ids_list {
                    set f_id_len_arr(${id}) [string length $id]
                    set f_arr(${id}) [qf_read form_id $id]
                    set f_str_len_arr(${id}) [string length $f_arr(${id})]
                    set f_net_len_arr(${id}) [expr { $f_str_len_arr(${id}) - 6 * $f_id_len_arr(${id}) } ]
                    if { $id eq $f4_id } {
                        # 11 = length of id='test7'
                        set f_net_len_arr(${id}) [expr { $f_net_len_arr(${id}) - 11 } ]
                    }
                    if { $id eq $f5_id } {
                        # 11 = length of id='test5'
                        set f_net_len_arr(${id}) [expr { $f_net_len_arr(${id}) - 11 } ]
                    }

                }
                foreach id $form_ids_list {
                    aa_equals "4. base form id '${id}' size is equal to f1_id's" $f_net_len_arr(${id}) $f_net_len_arr(${f1_id})
                    if { $f_net_len_arr(${id}) ne $f_net_len_arr(${f1_id}) } {
                        aa_log "id '${id}' form: $f_arr(${id}) \n\n f1_id form: $f_arr(${f1_id})"
                    }
                }
            } 
        }
    # example code
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

