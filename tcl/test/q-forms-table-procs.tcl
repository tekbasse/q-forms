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
            set titles_list [list ]


            # Output tables should have the 'ignore' column on right
            # with the other columns reversed.
            # Also, alternate sort bias increasing or decreasing.
            # Track bias and original column number for S and P parameters
            # to pass to test proc.
            set primary_sort_increasing_p [qf_is_true [randomRange 1]]
            set increasing_c "-increasing"
            set decreasing_c "-decreasing"
            set col_num 0
            foreach t $sort_type_list {
                lappend titles_list [string [string range $t 1 end] totitle]


                # if primary_sort_increasing_p, then sort increasing on even_p
                if { ( $primary_sort_increasing_p \
                           && [f::even_p $col_num ] ) \
                         || ( !$primary_sort_increasing_p \
                                  && [f::odd_p $col_num ] ) } {
                    set bias $increasing_c
                } else {
                    set bias $decreasing_c
                }
                lappend row_bias_list $bias
                lappend row_col_num_list $col_num

                incr col_num
            }

            # Populate tables with test data
            set seq 0
            foreach rows $table_row_count_list {
                set char_len [expr { round(pow( $rows , .3) ) } ]
                set table_larr(${rows}) [list ]
                for {set r 0} {$r < $table_row_count_list } {incr r} {
                    set row_list [list ]

                    foreach type $sort_type_list {
                        set t [string range $type 1 end]
                        switch -exact -- $t {
                            dictionary -
                            ignore -
                            ascii {
                                # Just make long enough to most likely have
                                # no duplicates.
                                set v [ad_generate_random_string $char_len ]
                            }
                            integer {
                                # Duplicate numbers can cause issues in 
                                # testing, so avoid by using a sequence here.
                                set v $seq
                            }
                            real {
                                set v [random ]
                            }
                        }
                        lappend row_list $v
                    }
                    lappend table_larr(${rows}) $row_list
                }
                incr seq
            }



            # Now essentially duplicate the function of the test proc, 
            # so that results can be checked those of test proc.

            # Sorting from right most column first to trigger all features.
            set sort_type_reverse_list [list ]
            set titles_revers_list [list ]
            set index_list [list ]
            set pos 4
            for {set i 4} {$i > -1} {incr i -1 } {
                set type [lindex $sort_type_list $i ]
                if { $type ne "-ignore" } {
                    lappend sort_type_reverse_list $type
                    lappend titles_reverse_list [lindex $titles_list $i ]
                    lappend index_list $pos
                    lappend row_rev_bias_list [lindex $row_bias_list $i ]
                    lappend row_rev_col_num_list [lindex $row_rev_col_num_list $i]
                    incr pos -1
                } else {
                    set ignore_col_num [lindex $row_bias_list $i ]
                }

            }
            lappend sort_type_reverse_list "-ignore"
            lappend titles_reverse_list "Ignore"
            lappend list_index $pos
            # No need to add a row_rev_bias_list entry.. becuase it is ignored
            lappend row_rev_col_num_list $ignore_col_num

            if { $pos ne 0 } {
                ns_log Warning "q-forms-table-procs.tcl.72. pos '${pos}' \
 Should be '0'. Error in code. "
            }

            # Reverse the columns, then sort.

            foreach rows $table_row_count_list {
                foreach table_lists $table_larr(${rows}) {
                    foreach row_list $table_lists {
                        foreach i $index_list {
                            set cell [lindex $row_list $i]
                            lappend new_row_list $cell
                        }
                        lappend $new_table_list $new_row_list
                    }
                    # index 4 is ignore, so start with 3:
                    for {set i 3} {$i > -1} {incr i -1} {
                        set type [lindex $sort_type_reverse_list $i]
                        set new_table_list [lsort $type -index $i $bias $new_table_list ]
                    }
                    set new_table_larr(${rows}) $new_table_list
                }
            }

            # Test tables are in new_table_larr(${rows})

            # Generate output using qfo_sp_table_g2
            # Testing P as well as S features.
            # We need to know what the original column references are


            # Compare outputs to $new_table_larr(${rows}) cell by cell


        }
    # example code
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

