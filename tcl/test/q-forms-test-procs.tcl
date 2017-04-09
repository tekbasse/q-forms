ad_library {
    Automated tests for q-forms
    @creation-date 2017-04-09
}

aa_register_case -cats {api smoke} qf_timestamp_checks {
    Test encoding decoding api of timestamps
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            ns_log Notice "qf_timestamp_checks.12: Begin test"
            set nowts_s [clock seconds]
            set qf_clock_format $nowts_s
            set ref0 [clock clicks]
            db_dml qf_test_table_w {
                insert into qf_test_table 
                (ref,timestamp_wo_tz,timestamp_w_tz,bigint_val)
                values (:ref0,:nowts_utc,:nowts_utc_w_tz,:nowts_s)
            }
            db_1row qf_test_table_r1 {
                select timestamp_wo_tz,timestamp_w_tz,bigint_val from qf_test_table where ref=:ref0
            }
            #compare nowts with pre-write timestamp_wo_tz timestamp_w_tz and

            #compare nowts with read from database
        } 
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

