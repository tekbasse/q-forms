ad_library {
    Automated tests for q-forms
    @creation-date 2017-04-09
}

aa_register_case -cats {api smoke} qf_form_gen_checks {
    Test form generation features
} {
    aa_run_with_teardown \
        -test_code {
            #         -rollback \
            ns_log Notice "qf_form_gen_checks.12: Begin test"

            array set fields_arr [list \
                                      test1 [list \
                                                 datatype text \
                                                 name Test1 \
                                                 default "okay!"]\
                                  ]
            set validated_p [qfo_2g -fields_array fields_arr]
            aa_log "qfo_gen x = '${x}'"
        } 
    # example code
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

