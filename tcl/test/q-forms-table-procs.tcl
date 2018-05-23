ad_library {
    Automated tests for q-forms
    @creation-date 2017-04-09
}

aa_register_case -cats {api smoke} qf_form_table_checks {
    Test table UI generation features
} {
    aa_run_with_teardown \
        -test_code {
            #         -rollback \
            ns_log Notice "qf_form_table_checks.12: Begin test"
            aa_log "Build tables to be sorted."
            # Should have at least one of each sort type.
            set sort_type_list [list "-ascii" "-integer" "-real" "-ignore" "-dictionary"]
            set table_row_count_list [list 3 9 12 70 100 120 1000]
            set sort_type_list [util::randomize_list $sort_type_list ]
            foreach rows $table_row_count_list {
                set table_larr(${rows}) [list ]
                for {set r 0} {$r < $table_row_count_list } {incr r} {
                    set row_list [list ]
                    foreach type $sort_type_list {
                        set t [string range $type 1 end]
                        switch -exact -- $t {
                            dictionary -
                            ignore -
                            ascii {
                                set v [ad_generate_random_string ]
                            }
                            integer {
                                set v [randomRange $rows ]
                            }
                            real {
                                set v [random]
                            }
                        }
                        lappend row_list $v
                    }
                    lappend table_larr(${rows}) $row_list
                }
            }
            # tables exist. Now process and verify
            # by sorting from right most column first to trigger all features.
            set sort_type_reverse_list [list ]
            for {set i 4} {$i > -1} {incr i -1 } {
                lappend sort_type_reverse_list [lindex $sort_type_list $i]
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

