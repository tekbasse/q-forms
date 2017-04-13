ad_library {
    Automated tests for database timestamp api
    @creation-date 2017-04-12
}

aa_register_case -cats {api db} qf_db_api_checks {
    Test timestamps to and from database
} {
    aa_run_with_teardown \
        -test_code {
            #         -rollback \
            ns_log Notice "qf_db_api_checks.12: Begin test"
            set ref0 [randomRange 10241024]
            # make sure ref0 hasn't been used before
            set ck $ref0
            while { $ck == $ref0 } {
                set ref0 [randomRange 10241024]
                db_0or1row qf_test_types_r1v {
                    select ref as ck from qf_test_types where ref=:ref0
                }
            }
            set nowts_utc_s [clock seconds]
            db_dml qf_test_types_w {
                insert into qf_test_types 
                (ref,timestamp_wo_tz,timestamp_w_tz,bigint_val)
                values (:ref0,now(),now(),:nowts_utc_s)
            }
            db_1row qf_test_types_r1 {
                select timestamp_wo_tz,timestamp_w_tz,bigint_val from qf_test_types where ref=:ref0
            }
            set timestamp_wo_tz_s [qf_clock_scan_from_db $timestamp_wo_tz]
            set timestamp_wo_tz_s2 [qf_clock_scan_from_db_wo_tz $timestamp_wo_tz]
            set timestamp_w_tz_s [qf_clock_scan_from_db $timestamp_w_tz]
            aa_log "from db: timestamp_wo_tz '${timestamp_wo_tz}', timestamp_w_tz '${timestamp_w_tz}', bigint_val '${bigint_val}'"
            aa_equals "A. ref equals nowts_utc_s" $bigint_val $nowts_utc_s
            set not_equals_p [expr { $timestamp_wo_tz_s != $nowts_utc_s } ]
            #aa_equals "B. qf_clock_scan_from_db timestamp_wo_tz equals nowts_utc_s" $timestamp_wo_tz_s $nowts_utc_s
            aa_true "B. FAILS ie. qf_clock_scan_from_db timestamp_wo_tz DOES NOT equal nowts_utc_s" $not_equals_p
            aa_log "Failure of test 'B' is why only timestamp_w_tz should be used. now() assumes localized tz adjustments for timestamp_wo_tz."
            aa_log "Here's a correction proc for cases of timestamp_wo_tz using localized references, such as now() etc."
            aa_equals "B2. qf_clock_scan_from_db_wo_tz timestamp_wo_tz equals nowts_utc_s" $timestamp_wo_tz_s2 $nowts_utc_s
            aa_log "To help avoid any timestamp issues with timestamps_wo_tz, write timestamps to database in UTC only."
            aa_equals "C. qf_clock_scan_from_db timestamp_w_tz equals nowts_utc_s" $timestamp_w_tz_s $nowts_utc_s
            #truncation any decimal seconds
            regsub -- {[\.][0-9]+} $timestamp_w_tz {} timestamp_w_tz_wo_ms
            set timestamp_w_tz_in_ts_w_tz [qf_timestamp_w_tz_to_tz $timestamp_w_tz_wo_ms]
            aa_log "timestamp_w_tz_in_ts_w_tz '${timestamp_w_tz_in_ts_w_tz}' (\[qf_timestamp_w_tz_to_tz '${timestamp_w_tz_wo_ms}'\])"
            if { $timestamp_w_tz_wo_ms eq [string range $timestamp_w_tz_in_ts_w_tz 0 [string length $timestamp_w_tz_wo_ms]-1] } {
                set equiv_p 1
            } else {
                set equiv_p 0
            }
            aa_true "D. qf_clock_format timestamp_w_tz_in_ts_w_tz equivalent to timestamp_w_tz" $equiv_p

        } 
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

