ad_library {
    Automated tests for q-forms
    @creation-date 2017-04-09
}

aa_register_case -cats {api smoke} qf_timestamp_checks {
    Test encoding decoding api of timestamps
} {
    aa_run_with_teardown \
        -test_code {
            #         -rollback \
            ns_log Notice "qf_timestamp_checks.12: Begin test"
            set format_str "%Y-%m-%d %H:%M:%S%z"

            set nowts_utc_s [clock seconds]
            ns_log Notice "qf_ts_checks.1   nowts_utc_s $nowts_utc_s"
            aa_log "A. nowts_utc_s $nowts_utc_s"

            set nowts [qf_clock_format $nowts_utc_s]
            aa_log "B. nowts $nowts"
            set nowts_w_tz [qf_clock_format $nowts_utc_s $format_str]
            aa_log "C. nowts_w_tz $nowts_w_tz"
            #compare nowts with pre-write timestamp_wo_tz timestamp_w_tz and

            set nowts_s [qf_clock_scan $nowts]
            ns_log Notice "qf_ts_checks.25  nowts_s ${nowts_s}"
            aa_log "D. nowts_s = 'qf_clock_scan ${nowts}' = ${nowts_s}"
            set diff1 [expr { $nowts_utc_s - $nowts_s } ]
            ns_log Notice "qf_ts_checks.28 diff1 ${diff1}"
            aa_log "E. Diff1: nowts_utc_s - nowts_s = ${diff1}"
            aa_equals "F. qf_clock_scan nowts equals nowts_utc_s" $nowts_s $nowts_utc_s

            set nowts_w_tz_s [qf_clock_scan $nowts_w_tz $format_str]
            set diff2 [expr { $nowts_utc_s - $nowts_w_tz_s } ]
            aa_log "G. Diff2: nowts_utc_s - nowts_w_tz_s = ${diff2}"
            aa_equals "H. qf_clock_scan nowts_w_tz_s equals nowts_utc_s" $nowts_w_tz_s $nowts_utc_s

            set ref0 [randomRange 10241024]
            # make sure ref0 hasn't been used before
            set ck $ref0
            while { $ck == $ref0 } {
                set ref0 [randomRange 10241024]
                db_0or1row qf_test_types_r1v {
                    select ref as ck from qf_test_types where ref=:ref0
                }
            }

            db_dml qf_test_types_w {
                insert into qf_test_types 
                (ref,timestamp_wo_tz,timestamp_w_tz,bigint_val)
                values (:ref0,:nowts,:nowts_w_tz,:nowts_utc_s)
            }

            db_1row qf_test_types_r1 {
                select timestamp_wo_tz,timestamp_w_tz,bigint_val from qf_test_types where ref=:ref0
            }
            set timestamp_wo_tz_s [qf_clock_scan_from_db $timestamp_wo_tz]
            set ts_wo_tz_s [qf_clock_scan $timestamp_wo_tz]
            set timestamp_w_tz_s [qf_clock_scan_from_db $timestamp_w_tz]
            set ts_w_tz_s [qf_clock_scan $timestamp_w_tz]
            #compare nowts with read from database
            aa_log "from db: timestamp_wo_tz '${timestamp_wo_tz}' timestamp_w_tz '${timestamp_w_tz}' bigint_val '${bigint_val}'"
            aa_equals "I. ref equals nowts_utc_s" $bigint_val $nowts_utc_s
            aa_equals "J. qf_clock_scan_from_db timestamps equal" $timestamp_wo_tz_s $timestamp_w_tz_s
            aa_equals "J. qf_clock_scan_from_db timestamp_wo_tz equals nowts_utc_s" $timestamp_wo_tz_s $nowts_utc_s
            aa_equals "J. qf_clock_scan_from_db timestamp_w_tz equals nowts_utc_s" $timestamp_w_tz_s $nowts_utc_s
            aa_equals "K. qf_clock_format nowts equals timestamp_wo_tz" $timestamp_wo_tz $nowts 
            aa_equals "L. qf_clock_format nowts_w_tz equals timestamp_w_tz" $timestamp_w_tz $nowts_w_tz

        } 
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

