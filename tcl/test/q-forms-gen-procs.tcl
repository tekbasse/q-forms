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

            set fd [list \
                        [list \
                             name test1_text \
                             label Test1 \
                             datatype text \
                             tabindex 1 \
                             default "okay!"]\
                        [list \
                             name test2integer \
                             tabindex 2 \
                             label Test2 \
                             datatype integer \
                             default "0"]\
                        [list \
                             label test_checkboxes \
                             tabindex 3 \
                             type checkbox \
                             value [list \
                                        [list \
                                             name test_card1 \
                                             label " label 1 " \
                                             value visa1 \
                                             selected 1] \
                                        [list \
                                             name test_card2 \
                                             label " label 2 " \
                                             value visa2 \
                                             selected 0] \
                                        [list \
                                             name test_card3 \
                                             label " label 3 " \
                                             value visa3 ] \
                                       ] ] \
                        [list \
                             label test_radios \
                             name creditcard \
                             type radio \
                             tabindex 4 \
                             value [list \
                                        [list \
                                             label " label 1 " \
                                             value visa1 \
                                             selected 1] \
                                        [list \
                                             label " label 2 " \
                                             value visa2 \
                                             selected 0] \
                                        [list \
                                             label " label 3 " \
                                             value visa3 ] \
                                       ] ] \
                       ]
            qfo_form_list_def_to_array \
                -array_name fields_arr \
                -list_of_lists_name fd \
                -ignore_parse_issues_p 0
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

