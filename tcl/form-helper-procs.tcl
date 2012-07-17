ad_library {

    routines for helping render form data or presentation for form data
    @creation-date 15 May 2012
    @cs-id $Id:
}

ad_proc -public qss_txt_to_tcl_list_of_lists {
    textarea
    linebreak
    delimiter
} {
    Converts a csv/txt style table into a tcl list_of_lists
} {
    set lists_list [list]
    set row_list [split $textarea $linebreak]
    # clean the rows of any extra linefeeds etc

    foreach row $row_list {
        set columns_list [split $row $delimiter]
        # rebuild columns_list to clean it of any remaining invisible characters
        set column_set [list ]
        foreach column $columns_list {
            regsub -all -- {[\n\r\f\v]} $column {} col_version2
            regsub -expanded -all -- {[[:cntrl:]]} $col_version2 {} col_version3
            lappend column_set $col_version3
        }
        set columns_list $column_set

        set columns [llength $columns_list]
        ns_log Notice "qss_txt_to_tcl_list_of_lists: col len $columns, columns_list ${columns_list}"
        if { $columns > 0 } {
            lappend lists_list $columns_list
        }
    }
    return $lists_list
}

ad_proc -public qss_txt_table_stats { 
    textarea 
} {
    determines the best guess linebreak_char delimiter rows_count columns_count of a cvs/txt table
    and returns these values a list
} {
    # scan to guess # of rows and cols

    set linebreaks_list [list \n \r \f \v ]
    set array table_arr

    # determine row delimiter
    set lineC 0
    set max_rows 0
    foreach linebreak $linebreaks_list {
        set row_set [split $textarea $linebreak]
        set linesC [llength $row_set]
#ns_log Notice "qss_txt_table_stats: rows $linesC for linebreak_idx/lineC $lineC"
        if { $linesC > $max_rows } {
            set linebreak_idx $lineC
            set max_rows $linesC
            set linebreak_char $linebreak
#            set rows_set $row_set 
            # remove any remaining delimiters
            set rows_set [list ]
            foreach line $row_set {
                regsub -all -- {[\n\r\f\v]} $line {} line2
#                regsub -expanded -all -- {[[:cntrl:]]} $line2 {} line3
                lappend rows_set $line2
            }
            set rows_count [llength $rows_set]
        }
        incr lineC
    }
#ns_log Notice "qss_txt_table_stats: rows_set: $rows_set"


    set rowsC [llength $rows_set]
    # determine column delimiter
    set delimiters_list [list "\t" " " "," "|" "!"]

    set delimC 0
    set columns_arr(0-avg) 0.
    foreach delimiter $delimiters_list {
        array unset columns_arr
        set max_cols 0
        set many_cols_sum 0.
        set few_cols_sum 0.
        set many_cols_rows 0
        set few_cols_rows 0
        set colC_list [list]
        set cols_sum 0.
        # get average number of rows and avg variance for each delim
        # When avg cols/row is > 2 ignore rows with (0 or) one column when calculating avg variance
        #   Do this by counting these rows, averaging them, then averaging to the other set if <= 2.

        # if there is a significant median value, use it instead.
        foreach row $rows_set {
            set col_set [split $row $delimiter]
            set colsC [llength $col_set]
 ns_log Notice "qss_txt_table_stats: delimiter $delimiter colsC $colsC"
            if { [info exists columns_arr(${colsC})] } {
                set columns_arr(${colsC}) [expr { $columns_arr(${colsC}) + 1 } ]
            } else {
                set columns_arr(${colsC}) 1
            }
            set cols_sum [expr { $cols_sum + $colsC } ]
            lappend colC_list $colsC
            if { $colsC > 2 } {
                set many_cols_sum [expr { $many_cols_sum + $colsC } ]
                incr many_cols_rows
            } else {
                set few_cols_sum [expr { $few_cols_sum + $colsC } ]
                incr few_cols_rows
            }
        }
        if { $few_cols_rows > 0 } {
            set few_cols_avg [expr { $few_cols_sum / $few_cols_rows } ]
        } else {
            set few_cols_avg 0
        }
        if { $many_cols_rows > 0 } {
            set many_cols_avg [expr { $many_cols_sum / $many_cols_rows } ]
        } else {
            set many_cols_avg 0
        }
        set cols_avg [expr { $cols_sum / $max_rows } ]
        if { $cols_avg > 2 } {
            set cols_avg $many_cols_avg
#            set rowsC $many_cols_rows
        } else {
            set cols_avg $few_cols_avg
#            set rowsC $few_cols_rows
        }
        # determine variance
        set sum2 0.
        set rowCt 0
        foreach colCt $colC_list {
            if { $colCt > 0 } {
                set sum2 [expr { $sum2 + pow( $colCt - $cols_avg , 2. ) } ]
                incr rowCt
            }
        }
        if { $rowCt > 1 } {
            set variance [expr { $sum2 / ( $rowCt - 1. ) } ]
        } else {
            set variance 99999.
        }

        #what is median of columns?
        set median 0
        foreach { column count } [array get columns_arr] {
            if { $count > $median } {
                set median_old $median
                set median $column
            }
        }

        # column count expands (not contracts) if delimeter is shared in data
        if { $median_old == 0 } {
            set median_old $median
        }
        set median_diff [expr { $median - $median_old } ]

        set median_pct_diff [expr { $median_diff / $median_old } ]

            
        if { $median_pct_diff > 1.1 && $median_pct_diff < 2.0 } {
            set median_old2 $median_old
            set median_old $median
            set median $median_old2
        }
# if row and column delimiter are same (such as space), manually step through table collecting info?
# determine likely matrix size and variations, then step through to sqrt(max_rows) looking for data type patterns.
# NOT IMPLEMENTED

        # For best guess, the average converges toward the median..
        set median_diff_abs [expr { abs( $median_diff ) } ]
        if { $variance < $median_diff_abs && $cols_avg < $median } {
            set bguess $cols_avg
            set bguessD $variance
        } else {
            set bguess $median
            set bguessD $median_diff_abs
        }

        set table_arr(${delimC}-avg) $cols_avg
        set table_arr(${delimC}-variance) $variance
        set table_arr(${delimC}-median) $median
        set table_arr(${delimC}-medianD) $median_old
        set table_arr(${delimC}-bguess) $bguess
        set table_arr(${delimC}-bguessD) $bguessD
        set table_arr(${delimC}-rows) $rowCt
        set table_arr(${delimC}-delim) $delimiter
        set table_arr(${delimC}-linebrk) $linebreak_char
        incr delimC
#ns_log Notice "qss_txt_table_stats: delimC $delimC cols_avg $cols_avg variance $variance median $median median_old $median_old bguess $bguess bguessD $bguessD rowCt $rowCt"
    }
    set bguessD $table_arr(0-bguessD)
    set bguess $table_arr(0-bguess)
    set rows_count $table_arr(0-rows)
    set delimiter $table_arr(0-delim)
    for { set i 0 } { $i < $delimC } { incr i } {
        if { $table_arr(${i}-bguessD) <= $bguessD && $table_arr(${i}-bguess) > 1 } {
            if { ( $bguess > 1 && $table_arr(${i}-bguess) < $bguess ) || $bguess < 2 } {
                set bguess $table_arr(${i}-bguess)
                set bguessD $table_arr(${i}-bguessD)
                set rows_count $table_arr(${i}-rows)
                set delimiter $table_arr(${i}-delim)
            }
        }
    }
    set return_list [list $linebreak_char $delimiter $rows_count $bguess]
#    ns_log Notice "qss_txt_table_stats: return_list $return_list"
    return $return_list
}



ad_proc -public qss_list_of_lists_to_html_table { 
    table_list_of_lists 
    {table_attribute_list ""}
    {td_attribute_lists ""}
} {
    Converts a tcl list_of_lists to an html table, returns table as text/html
    table_attribute_list can be a list of attribute pairs to pass to the TABLE tag: attribute1 value1 attribute2 value2..
    The td_attribute_lists adds attributes to TD tags at the same position as table_list_of_lists 
    the list is represented {row1 {cell1} {cell2} {cell3} .. {cell x} } {row2 {cell1}...}
    Note that attribute - value pairs in td_attribute_lists can be added uniquely to each TD tag.
} {
    set table_html "<table"
    foreach {attribute value} $table_attribute_list {
        regsub -all -- {\"} $value {\"} value
        append table_html " $attribute=\"$value\""
    }
    append table_html ">\n"
    set row_i 0
    set column_i 0
    #setup repeat pattern for formatting rows, if last formatting row is not blank
    set repeat_last_row_p 0
    if { [llength [lindex $td_attribute_lists end] ] > 0 } {
        # this feature only comes into play if td_attrubte_lists is not as long as table_list_of_lists
        set repeat_last_row_p 1
        set repeat_row [expr { [llength $td_attribute_lists] - 1 } ]
    }
    foreach row_list $table_list_of_lists {
        append table_html "<tr>"
        foreach column $row_list {
            append table_html "<td"
            if { $repeat_last_row_p && $row_i > $repeat_row } {
                set attribute_value_list [lindex [lindex $td_attribute_lists $repeat_row] $column_i]

            } else {
                set attribute_value_list [lindex [lindex $td_attribute_lists $row_i] $column_i]
            }
            foreach {attribute value} $attribute_value_list {
                regsub -all -- {\"} $value {\"} value
                append table_html " $attribute=\"$value\""
            }
            append table_html ">${column}</td>"
            incr column_i
        }
        append table_html "</tr>\n"
        incr row_i
        set column_i 0
    }
    append table_html "</table>\n"
    return $table_html
}

ad_proc -public qss_lists_to_text { 
    table_list_of_lists
    {row_delimiter "\n"}
    {column_delimiter ","}
 } {
    Converts a tcl list_of_lists to content suitable to be used with a textarea tag.
} {
    foreach row_list $table_list_of_lists {
        set col_delim ""
        foreach column $row_list {
            append table_html $col_delim
            append table_html $column
            set col_delim $column_delimiter
        }
        append table_html $row_delimiter
    }
    return $table_html
}


ad_proc -public qss_form_table_to_table_lists {
    table_array_name
} {
    returns a table represented as a list of lists from a table represtented as an array.
} {
    upvar $table_array_name table_array

    # get array indices as a sorted list
    set array_idx_list [lsort [array names table_array]]
}

ad_proc -public qss_table_lists_normalize {
    table_lists
    new_min
    new_max
} {
    given a list_of_lists table, returns the table normalized to max/min parameters
} {
    set element_1 [lindex [lindex $table_lists 0] 0]
    set element_max $element_1
    set element_min $element_1
    foreach row_list $table_lists {
        foreach element $row_list {
            if { $element > $element_max } {
                set element_max $element
            }
            if { $element < $element_min } {
                set element_min $element
            }
        }
    }
    set delta_old [expr { $element_max - $element_min } ]
    set delta_new [expr { $new_max - $new_min } ]

    foreach row_list $table_lists {
        foreach element $row_list {
            # transform value to new range
            set element_new [expr { ( $element - $element_min ) * $delta_new  / $delta_old + $new_min } ]
        }
    }
}



ad_proc -public qss_progression_x1x2xc {
    min
    max
    count
} {
    given:  x1 start, x2 end, and xc (the number of points)

    returns a list of xc elements starting from x1 to x2
} {

    set dx [expr { $x2 - $x1 } ]
    set x_list [list ]
    if { $xc != 0 && $dx != 0 } {
        if { $x1 > $x2 } { 
            set step [expr { $dx / $xc } ]
            for { set x $x1 } { $x >= $x2 } { set x [expr { $x + $step } ] } {
                lappend x_list $x
            }
        } else {
            set step [expr { $dx / $xc } ]
            for { set x $x1 } { $x <= $x2 } { set x [expr { $x + $step } ] } {
                lappend x_list $x
            }
        }
    }
    return $x_list
}
