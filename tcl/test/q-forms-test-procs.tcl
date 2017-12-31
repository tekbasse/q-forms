ad_library {
    Automated tests for q-forms
    @creation-date 2017-04-09
}

aa_register_case -cats {api smoke} qf_form_checks {
    Test multiple concurrent form generation and tag making features
} {
    aa_run_with_teardown \
        -test_code {
            #         -rollback \
            ns_log Notice "qf_form_tests.12: Begin test"

            aa_log "create three forms with default id"
            set f1_id [qf_form ]
            set f2_id [qf_form ]
            set f3_id [qf_form ]
            set f1_ne_f2 [expr { $f1_id ne $f2_id } ]
            set f2_ne_f3 [expr { $f2_id ne $f3_id } ]
            aa_true "id form1 ${f1_id} does not equal form2 ${f2_id}" $f1_ne_f2
            aa_true "id form2 ${f2_id} does not equal form3 ${f3_id}" $f2_ne_f3
            set f4_id [qf_form form_id test4 id test5]
            set f5_id [qf_form id test5]
            set f4_ne_f5 [expr { $f4_id ne $f5_id } ]
            aa_true "id form4 ${f4_id} does not equal form5 ${f5_id}" $f4_ne_f5

        } 
    # example code
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

