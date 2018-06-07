set title "#acs-subsite.Administration#"
set context [list ]

set doc(type) {<!DOCTYPE html>}


set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set admin_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
if { !$admin_p } {
    ad_redirect_for_registration
    ad_script_abort
}
set page_url [ad_conn url]
if { [string match "*b" $page_url ] } {
    set page_num_p 1
} else {
    set page_num_p 0
}

set input_array(s) "0"
set input_array(p) ""
set input_array(this_start_row) ""

set form_posted_p [qf_get_inputs_as_array input_array]


# Build example table
# Should have at least one of each sort type.

# This here just creates a table that has a little visual consistency
# between page renderings, to better demonstrate UI with 
# a consistent type of data
set sort_type_list [list ]
set seed [expr { int(fmod( int([clock seconds] / 600) , 6 )) } ]
switch -- $seed {
    0 {
        set sort_type_list [list "-ascii" "-integer" "-real"]
    }
    1 {
        set sort_type_list [list "-ascii" "-real" "-integer"]
    }
    2 {
        set sort_type_list [list "-integer" "-ascii" "-real"]
    }
    3 {
        set sort_type_list [list "-integer" "-real" "-ascii"]
    }
    4 {
        set sort_type_list [list "-real" "-ascii" "-integer"]
    }
    5 {
        set sort_type_list [list "-real" "-integer" "-ascii"]
    }
}
ns_log Notice "seed '${seed}' sort_type_list '${sort_type_list}'"
lappend sort_type_list "-ignore" "-dictionary"


set titles_list [list ]
foreach t $sort_type_list {
    lappend titles_list [string totitle [string range $t 1 end]]
}

# Output tables should have the 'ignore' column on right
# with the other columns reversed.
# Also, alternate sort bias increasing or decreasing.
# Track bias and original column number for S and P parameters
# to pass to test proc.

# Populate table with test data

set rows 1000
set char_len [expr { round(sqrt( $rows ) ) } ]



set table_lists [list ]
for {set r 0} {$r < $rows } {incr r} {
    set row_list [list ]
    
    foreach type $sort_type_list {
        set t [string range $type 1 end]
        switch -exact -- $t {
            dictionary {
                # Show power of dictionary sort by using a timestamp
                set v [qf_clock_format [randomRange [clock seconds ] ] ]
            }
            ignore {
                set v "Row '"
                append v $t "' "
                append v "A unique view | edit | delete button could go here"
            }
            ascii {
                # Just make long enough to most likely have
                # no duplicates.
                set v [ad_generate_random_string $char_len ]
            }
            integer {
                # Duplicate numbers can cause issues in 
                # testing, so avoid by using a sequence here.
                set v $r
            }
            real {
                set v [string range [random ] 0 ${char_len}+2 ]
            }
        }
        lappend row_list $v
    }
    
    lappend table_lists $row_list
}




qfo_sp_table_g2 \
    -table_lists_varname table_lists \
    -table_html_varname table_html \
    -p_varname input_array(p) \
    -s_varname input_array(s) \
    -titles_list_varname titles_list \
    -titles_html_list_varname titles_html_list \
    -sort_type_list $sort_type_list \
    -this_start_row $input_array(this_start_row) \
    -page_num_p $page_num_p


set content ""

append content $table_html
