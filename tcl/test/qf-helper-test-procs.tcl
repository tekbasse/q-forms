ad_library {
    Automated tests for q-forms
    @creation-date 2017-04-09
}

aa_register_case -cats {api smoke} qf_helper_proc_checks {
    Test functionality of test procs.
    Some are used regularly in other procs and subsquently
    tested indirectly.

    Any changes to existing procs should include adding tests
    here to verify there have been no changes to expected performance.
} {
    aa_run_with_teardown \
        -test_code {
            #         -rollback \
            ns_log Notice "qf-hlper-test-procs.tcl.12: Begin test"
            aa_log "test qf_ helper procs"

            set email "an_account@a123-22342-2.co.uk"
            set t_p [qf_email_valid_q $email]
            aa_true "qf_email_valid_q '${email}' " $t_p

            set domain "asdfskja.sd.sdf"
            set t_p [qf_domain_name_valid_q $domain]
            aa_true "qf_domain_name_valid_q '${domain}'" $t_p

            set tf_p [randomRange 1]
            set t_p [qf_is_boolean $tf_p]
            aa_true "qf_is_boolean '${tf_p}'" $t_p

            set c "12.345,00DKr"
            set t_p [qf_is_currency_like $c]
            aa_true "qf_is_currency_like '${c}'" $t_p

            set c "12,234.56USD"
            set t_p [qf_is_currency $c]
            aa_true "qf_is_currency '${c}'" $t_p

        }
    # example code
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

