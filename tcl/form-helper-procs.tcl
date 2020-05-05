ad_library {
    
    procedures for helping render form data or presentation for form data
    @creation-date 15 May 2012
    @Copyright (c) 2012-5 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl.html
    @project home: http://github.com/tekbasse/q-forms
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com

    to vertically align textarea label, add to css: 

    textarea { vertical-align: top; }
    # replace top with middle or other options to adjust alignment.
    # textarea's border is used for alignment, so alignment is affected by font-size and line-height ratio 
    # in addition to borders and margins.

}

ad_proc -public qf_lists_to_vars {
    values_list
    keys_list
    {only_these_keys_list ""}
} {
    Returns variables assigned to the values in values_list, paired by index.
    For example the fourth index of keys_list is assigned the value of the 
    fourth index of values_list.
    If values_list is shorter, the orphaned keys are assigned an empty string.
    If keys_list is shorter, excess values are returned as a list.
    If only_these_keys_list is not empty, only these keys will be converted. 
    Anything in only_these_keys_list that is not in keys_list is ignored.
} {
    set remainder_list [list ]
    set values_list_len [llength $values_list]
    set keys_list_len [llength $keys_list]
    if { $values_list_len > $keys_list_len } {
        set remainder_list [lrange $values_list $keys_list_len end]
        set values_list [lrange $values_list 0 ${keys_list_len}-1]
    }

    if { $only_these_keys_list eq "" } {
        set i 0
        foreach key $keys_list {
            upvar 1 $key val_${key}
            set val_${key} [lindex $values_list $i]
            incr i
        }
    } else {
        # fkey = filtered key
        set otk_list [split $only_these_keys_list]
        foreach fkey $otk_list {
            set i [lsearch -exact $keys_list $fkey]
            if { $i > -1 } {
                upvar 1 $fkey val_${fkey}
                set val_${fkey} [lindex $values_list $i]
            }
        }
    }
    return $remainder_list
}


ad_proc -public qf_nv_list_to_vars {
    name_val_list
    {only_these_keys_list ""}
} {
    Returns names as variables assigned to the values in name_val_list,
    For example the third index of name_val_list is assigned the value of the 
    fourth index of name_val_list.
    If name_val_list is missing a last value, name is assigned an empty string.
    If only_these_keys_list is not empty, only these keys will be converted. 
    Any key in only_these_keys_list that is not a name in name_val_list will be
    assigned an empty string value.
    Any name value pair not made a variable with value will be returned in a name_value_list.
} {
    set remainder_list [list ]
    set name_val_list_len [llength $name_val_list]
    if { ![qf_is_even $name_val_list_len] } {
        lappend name_val_list ""
    }
    if { $only_these_keys_list eq "" } {
        foreach {name val} $name_val_list {
            upvar 1 $name val_${name}
            set val_${name} $val
        }
    } else {
        set done_list [list ]
        foreach {name val} $name_val_list {
            if { $name in $only_these_keys_list } {
                upvar 1 $name val_${name}
                set val_${name} $val
                lappend done_list
            } else {
                lappend remainder_list $name $val
            }
        }
        set diff_list [set_difference $only_these_keys_list $done_list]
        set val ""
        foreach name $diff_list {
            upvar 1 $name val_${name}
            set val_${name} $val
        }
    }
    return $remainder_list
}


ad_proc -public qf_lists_to_array {
    array_name
    values_list
    keys_list
} {
    Returns an array with elements in key_list assigned to the values in values_list, paired by list index.
    For example the fourth index of keys_list is an element assigned the value of the 
    fourth index of values_list.
    If values_list is shorter, the orphaned keys are assigned an empty string.
    If keys_list is shorter, excess values are returned as a list.
} {
    upvar 1 $array_name name_arr
    set remainder_list [list ]
    set values_list_len [llength $values_list]
    set keys_list_len [llength $keys_list]
    if { $values_list_len > $keys_list_len } {
        set remainder_list [lrange $values_list $keys_list_len end]
        set values_list [lrange $values_list 0 ${keys_list_len}-1]
    }
    set i 0
    foreach key $keys_list {
        set name_arr(${key}) [lindex $values_list $i]
        incr i
    }
    return $remainder_list
}


ad_proc -public qf_array_to_vars {
    array_name
    keys_list
} {
    Returns variables assigned to the values in array(variable) for variables named in keys_list.
    This returns a selection of array values, not all elements as done by template::util::array_to_vars 
    If a key doesn't exist, the variable is created and assigned the empty string.
} {
    upvar 1 $array_name an_arr
    foreach key $keys_list {
        if { [info exists an_arr(${key}) ] } {
            uplevel [list set $key $an_arr(${key}) ]
        } else {
            uplevel [list set $key ""]
        }
    }
    return 1
}


ad_proc -public qss_table_cols_filter {
    table_lists
    col_names
    {blank_missing_cols_p "0"}
} {
    Excludes all columns not referenced by name. 
    Columns are ordered in order of names.
    If column not found in table and blank_missing_cols_p is 1,
    an empty column is included in returned table.
    Otherwise, column is not included in table.
} {
    set col_names_list [split $col_names]

    # create an index list of column titles
    set titles_list [lindex $table_lists 0]
    set cols_idx_list [list ]
    foreach name $col_names_list {
        set col_name [string trim $name]
        set col_idx [lsearch -exact $col_name $titles_list]
        if { $col_idx > -1 || $blank_missing_cols_p } {
            lappend cols_idx_list $col_idx
        }
    }
    # build new table with column titles index
    set new_table_lists [list ]
    foreach row_list $table_lists {
        set new_row_list [list ]
        foreach col_idx $cols_idx_list {
            if { $col_idx > -1 } {
                set col_value [lindex $row_list $col_idx]
            } else {
                set col_value ""
            }
            lappend new_row_list $col_value
        }
        lappend new_table_lists $new_row_list
    }
    return $new_table_lists
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
#        ns_log Notice "qss_txt_to_tcl_list_of_lists: col len $columns, columns_list ${columns_list}"
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
    set delimiters_list [list "\t" " " "," "|" "!" ":" ";"]

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
# ns_log Notice "qss_txt_table_stats: delimiter $delimiter colsC $colsC"
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
        ns_log Notice "qss_txt_table_stats: delimC '$delimC' delimiter '${delimiter}' cols_avg $cols_avg variance $variance median $median median_old $median_old bguess $bguess bguessD $bguessD rowCt $rowCt"
        incr delimC
    }

    # convert the table into a sortable list of lists
    # First choice:
    # select bguess >= 2 with smallest variance.
    set bguess_lists [list ]
    for { set i 0 } { $i < $delimC } { incr i } {
        if { $table_arr(${i}-bguess) >= 2. } {
            set bg_list [list $i $table_arr(${i}-avg) $table_arr(${i}-variance) ]
            ns_log Notice "qss_txt_table_stats.215: i $i table_arr(${i}-bguess) $table_arr(${i}-bguess) table_arr(${i}-bguessD) $table_arr(${i}-bguessD) bg_list ${bg_list}"
            lappend bguess_lists $bg_list
        }
    }
    # sort by smallest variance
    if { [llength $bguess_lists] > 0 } {
        set sorted_bg_lists [lsort -increasing -real -index 2 $bguess_lists]
        ns_log Notice "qss_txt_table_stats.220: sorted_bg_lists '${sorted_bg_lists}'"
        set i [lindex [lindex $sorted_bg_lists 0] 0]
        set bguess $table_arr(${i}-bguess)
        set bguessD $table_arr(${i}-bguessD)
        set rows_count $table_arr(${i}-rows)
        set delimiter $table_arr(${i}-delim)
        
        # If there are no bguesses over 2, then use this process:
        if { [llength $bguess_lists] == 0 } {
            # This following techinque is not dynamic enough to handle all conditions.
            set bguessD $table_arr(0-bguessD)
            set bguess $table_arr(0-bguess)
            set rows_count $table_arr(0-rows)
            set delimiter $table_arr(0-delim)
            # bguessD is absolute value of bguess from variance
            for { set i 0 } { $i < $delimC } { incr i } {
                if { ( $table_arr(${i}-bguessD) <= $bguessD ) && $table_arr(${i}-bguess) > 1 } {
                    if { ( $bguess > 1 && $table_arr(${i}-bguess) < $bguess ) || $bguess < 2 } {
                        set bguess $table_arr(${i}-bguess)
                        set bguessD $table_arr(${i}-bguessD)
                        set rows_count $table_arr(${i}-rows)
                        set delimiter $table_arr(${i}-delim)
                    }
                }
            }
        }
        ns_log Notice "qss_txt_table_stats linebreak '${linebreak_char}' delim '${delimiter}' rows '${rows_count}' columns '${bguess}'"
    } else {
        # There appears to be no rows or columns
        # create defaults
        set linebreak_char "\n"
        set delimiter "\t"
        set rows_count 1
        set bguess 1
    }
    ns_log Notice "qss_txt_table_stats linebreak '${linebreak_char}' delim '${delimiter}' rows '${rows_count}' columns '${bguess}'"
    set return_list [list $linebreak_char $delimiter $rows_count $bguess]
#    ns_log Notice "qss_txt_table_stats: return_list $return_list"
    return $return_list
}



ad_proc -public qss_list_of_lists_to_html_table { 
    table_list_of_lists 
    {table_attribute_list ""}
    {td_attribute_lists ""}
    {th_rows "1"}
    {tr_even_attribute_list ""}
    {tr_odd_attribute_list ""}
    {tr_header_attribute_list ""}
} {
    Converts a tcl list_of_lists to an html table, returns table as text/html
    table_attribute_list can be a list of attribute pairs to pass to the TABLE tag: attribute1 value1 attribute2 value2..
    td_attribute_lists adds attributes to TD tags at the same position as table_list_of_lists 
    First row(s) use html accessibility guidelines TH tag inplace of TD.
    Number of th_rows sets the number of rows that use TH tag. Default is 1.
    the list is represented {row1 {cell1} {cell2} {cell3} .. {cell x} } {row2 {cell1}...}
    Note that attribute - value pairs in td_attribute_lists can be added uniquely to each TD tag.
} {
    set fs "/"
    set th "th"
    set gt ">"
    set lt "<"
    set quote "\""
    set eq_quote "=\""
    set td "td"
    set sp " "
    set nl "\n"
    set tr "tr"
    set lttr "<tr"

    set table_html "<table"
    foreach {attribute value} $table_attribute_list {
        regsub -all -- {\"} $value {\"} value
        append table_html ${sp} ${attribute} ${eq_quote} ${value} ${quote}
    }
    append table_html ${gt} ${nl}
    set row_i 0
    set column_i 0
    # Setup repeat pattern for formatting rows, 
    # if last formatting row is not blank.
    set repeat_last_row_p 0
    if { [llength [lindex $td_attribute_lists end] ] > 0 } {
        # This feature only comes into play
        # if td_attribute_lists is not as long as table_list_of_lists
        set repeat_last_row_p 1
        set repeat_row [llength $td_attribute_lists]
        incr repeat_row -1
    }

    set td_tag ${th}
    set td_tag_html ${lt}
    append td_tag_html $td_tag

    set tr_hr_tag_html ${lttr}
    foreach {attribute value} $tr_header_attribute_list {
        append tr_hr_tag_html ${sp} ${attribute} ${eq_quote} ${value} ${quote}
    }
    append tr_hr_tag_html ${gt} ${nl}

    set tr_even_tag_html ${lttr}
    foreach {attribute value} $tr_even_attribute_list {
        append tr_even_tag_html ${sp} ${attribute} ${eq_quote} ${value} ${quote}
    }
    append tr_even_tag_html ${gt} ${nl}

    set tr_odd_tag_html ${lttr}
    foreach {attribute value} $tr_odd_attribute_list {
        append tr_odd_tag_html ${sp} ${attribute} ${eq_quote} ${value} ${quote}
    }
    append tr_odd_tag_html ${gt} ${nl}

    append table_html "<thead>"
    foreach row_list $table_list_of_lists {

        if { $row_i == $th_rows } {
            set td_tag ${td}
            set td_tag_html ${lt}
            append td_tag_html ${td_tag}
            append table_html "</thead><tbody>"
        }

        set data_row_nbr [expr { ${row_i} - ${th_rows} + 1 } ]
        if { $data_row_nbr < 1 } {
            append table_html ${tr_hr_tag_html}
        } elseif { [qf_is_even $data_row_nbr ] } {
            append table_html ${tr_even_tag_html}
        } else {
            append table_html ${tr_odd_tag_html}
        }

        foreach column $row_list {
            append table_html $td_tag_html
            if { $repeat_last_row_p && $row_i > $repeat_row } {
                set attribute_value_list [lindex [lindex $td_attribute_lists $repeat_row] $column_i]

            } else {
                set attribute_value_list [lindex [lindex $td_attribute_lists $row_i] $column_i]
            }
            foreach {attribute value} $attribute_value_list {
                regsub -all -- {\"} $value {\"} value
                append table_html ${sp} ${attribute} ${eq_quote} ${value} ${quote}
            }
            append table_html ${gt} ${column} ${lt} ${fs} ${td_tag} ${gt}
            incr column_i
        }
        append table_html ${lt} ${fs} ${tr} ${gt} ${nl}
        incr row_i
        set column_i 0
    }
    append table_html "</tbody></table>\n"
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

ad_proc -public qf_is_natural_number {
    value
} {
    answers question: is value a natural counting number (non-negative integer)?
    returns 0 or 1
} {
    set is_natural [regexp {^(0*)(([1-9][0-9]*|0))$} $value match zeros value]
    return $is_natural
}

ad_proc -public qf_is_integer {
    value
} {
    answers question: is value an integer?
    Integer can be negative or start with zeros, but not -0..
    returns 0 or 1
} {
    # Is this the most permissive?
    # Why not allow -0056 for example?  TODO: answer question
    set is_integer [regexp {^(0*)(([\-]?[1-9][0-9]*|0))$} $value match zeros value]
    return $is_integer
}

ad_proc -public qf_remove_from_list {
    value value_list
} {
    removes multiple of a specific value from a list
    returns list without the passed value
} {

    set value_indexes [lsearch -all -exact $value_list $value]
    while { [llength $value_indexes] > 0 } {
        set next_index [lindex $value_indexes 0]
        set value_list [lreplace $value_list $next_index $next_index]
        set value_indexes [lsearch -all -exact $value_list $value]
    }
    return $value_list
}

ad_proc -public qf_get_contents_from_tag {
    start_tag
    end_tag
    page
    {start_index 0}
} {
    Returns content of an html/xml or other bracketing tag that is uniquely identified within a page fragment or string.
    helps pan out the golden nuggets of data from the waste text when given some garbage with input for example
} {
    set tag_contents ""
    set start_col [string first $start_tag $page $start_index]
    set end_col [string first $end_tag $page $start_col]
    if { $end_col > $start_col && $start_col > -1 } {
        set tag_contents [string trim [string range $page [expr { $start_col + [string length $start_tag] } ] [expr { $end_col -1 } ]]]
    } else {
        set starts_with "${start_tag}.*"
        set ends_with "${end_tag}.*"
        if { [regexp -- ${starts_with} $page tag_contents ]} {
            if { [regexp -- ${ends_with} $tag_contents tail_piece] } {
                set tag_contents [string range $tag_contents 0 [expr { [string length $tag_contents] - [string length $tail_piece] - 1 } ] ]
            } else {
                ns_log Notice "Warning no contents for tag $start_tag"
                set tag_contents ""
            }
        }
    }
    return $tag_contents
}

ad_proc -public qf_get_contents_from_tags_list {
    start_tag
    end_tag
    page
} {
    Returns content (as a list) of all occurances of an html/xml or other bracketing tag that is somewhat uniquely identified within a page fragment or string.
    helps pan out the golden nuggets of data from the waste text when given some garbage with input for example
} {
    set start_index 0
    set tag_contents_list [list]
    set start_tag_len [string length $start_tag]
    set start_col [string first $start_tag $page 0]
    set end_col [string first $end_tag $page $start_col]
    set tag_contents [string range $page [expr { $start_col + $start_tag_len } ] [expr { $end_col - 1 } ]]
    while { $start_col != -1 && $end_col != -1 } {
#        lappend tag_contents_list [string trim $tag_contents]
        lappend tag_contents_list $tag_contents

        set start_index [expr { $end_col + 1 }]
        set start_col [string first $start_tag $page $start_index]
        set end_col [string first $end_tag $page $start_col]
        set tag_contents [string range $page [expr { $start_col + $start_tag_len } ] [expr { $end_col - 1 } ]]
    }
    return $tag_contents_list
}

ad_proc -public qf_remove_tag_contents {
    start_tag
    end_tag
    page
} {
    Returns everything but the content between start_tag and end_tag (as a list) 
    of all occurances on either side of an html/xml or other bracketing tag 
    that is somewhat uniquely identified within a page fragment or string.
    This is handy to remove script tags and < ! - - web comments - - > etc
    helps pan out the golden nuggets of data from the waste text when given some garbage with input for example
} {
    # start and end refer to the tags and their contents that are to be removed
ns_log Notice "qf_remove_tag_contents: start_tag $start_tag end_tag $end_tag page $page"
    set start_index 0
    set tag_contents_list [list]
    set start_tag_len [string length $start_tag]
    set end_tag_len [string length $end_tag]
    set start_col [string first $start_tag $page $start_index]
    set end_col [string first $end_tag $page $start_col]
    # set tag_contents [string range $page 0 [expr { $start_col - 1 } ] ]
    while { $start_col != -1 && $end_col != -1 } {
        set tag_contents [string range $page $start_index [expr { $start_col - 1 } ] ]
#        lappend tag_contents_list [string trim $tag_contents]
        lappend tag_contents_list $tag_contents
ns_log Notice "qf_remove_tag_contents(465): tag_contents '$tag_contents'"
        # start index is where we begin the next clip        
        set start_index [expr { $end_col + $end_tag_len } ]
        set start_col [string first $start_tag $page $start_index]
        set end_col [string first $end_tag $page $start_col]
        # and the new clip ends at the start of the next tag
    }
    # append any trailing portion
    lappend tag_contents_list [string range $page $start_index end]

    return $tag_contents_list
}


ad_proc -public qf_convert_html_list_to_tcl_list {
    html_list
} {
    converts a string containing an html list to a tcl list
    Assumes there are no embedded sublists, and strips remaining html
} {
    set draft_list $html_list

    #we standardize the start and end of the list, so we know where to clip

    if { [regsub -nocase -- {<[ou][l][^\>]*>} $draft_list "<ol>" draft_list ] ne 1 } {
        # no ol/ul tag, lets create the list container anyway
        set draft_list "<ol> ${draft_list}"

    } else {
        # ol/ul tag exists, trim garbage before list
        set draft_list [string range $draft_list [string first "<ol>" $draft_list ] end ]
    }

    if { [regsub -nocase -- {</li>[ ]*</[ou]l[^\>]*>} $draft_list "</li></ol>" draft_list ] ne 1 } {
        # end list tag may not exist or is not in standard form
        if { [regsub -nocase -- {</[ou]l[^\>]*>} $draft_list "</li></ol>" draft_list ] ne 1 } {
            # assume for now that there was no end li tag before the list (bad html)
        } else {
            # no ol/ul list tag, assume no end </li> either?
            append draft_list "</li></ol>"
        }
    }

    # end ol tag exists, trim garbage after list
    # choosing the last end list tag in case there is a list in one of the lists
    set draft_list [string range $draft_list 0 [expr { [string last "</ol>" $draft_list ] + 4} ] ]

    # simplify li tags, with a common delimiter
    regsub -nocase -all -- {<li[^\>]*>} $draft_list {|} draft_list
    # remove other html tags

    set draft_list [qf_webify $draft_list]

    # remove excess spaces
    regsub -all -- {[ ]+} $draft_list " " draft_list
    set draft_list [string trim $draft_list]

    # remove excess commas and format poorly placed ones
    regsub -all -- {[ ],} $draft_list "," draft_list

    regsub -all -- {[,]+} $draft_list "," draft_list

    # put colons in good form
    regsub -all -- {[ ]:} $draft_list ":" draft_list

    regsub -all -- {:,} $draft_list ":" draft_list
    # remove : in cases where first column is blank, ie li should not start with a colon

    regsub -all -- {\|:} $draft_list {|} draft_list

    set tcl_list [split $draft_list {|}]
    # first lindex will be blank, so remove it
    set tcl_list [lrange $tcl_list 1 end]
#ns_log Notice "qf_convert_html_list_to_tcl_list: tcl_list $tcl_list"
    return $tcl_list
}

ad_proc -public qf_convert_html_table_to_list {
    html_string
    {list_style ul}
} {
    converts a string containing an html table to an html list
    assumes first column is a heading (with no rows as headings), and remaining columns are values
    defaults to li list style, should return list in good html form even if table is not quite that way
} {

    if { [regsub -nocase -- {<table[^\>]*>} $html_string "<${list_style}>" draft_list ] ne 1 } {
        # no table tag, lets create the list container anyway
        set draft_list "<${list_style}> ${html_string}"
    } else {
        # table tag exists, trim garbage before list
        set draft_list [string range $draft_list [string first "<${list_style}>" $draft_list ] end ]
    }

    if { [regsub -nocase -- {</tr>[ ]*</table[^\>]*>} $draft_list "</li></${list_style}>" draft_list ] ne 1 } {
        # end table tag may not exist or is not in standard form
        if { [regsub -nocase -- {</table[^\>]*>} $draft_list "</li></${list_style}>" draft_list ] ne 1 } {
            # assume for now that there was no end tr tag before the table (bad html)
        } else {
            # no table tag, assume no end </tr> either?
            append draft_list "</li></${list_style}>"
        }
    }

    # end table tag exists, trim garbage after list
    # choosing the last end list tag in case there is a list in one of the table cells
    set draft_list [string range $draft_list 0 [expr { [string last "</${list_style}>" $draft_list ] + 4} ] ]

    # simplify tr and td tags, but do not replace yet, because we want to use them for markers when replacing td tags
    regsub -nocase -all -- {<tr[^\>]+>} $draft_list "<tr>" draft_list
    regsub -nocase -all -- {</tr[^\>]+>} $draft_list "</tr>" draft_list
    regsub -nocase -all -- {<td[^\>]+>} $draft_list "<td>" draft_list
    regsub -nocase -all -- {</td[^\>]+>} $draft_list "</td>" draft_list

    # clean out other content junk tags
    regsub -nocase -all -- {<[^luot\/\>][^\>]*>} $draft_list "" draft_list
    regsub -nocase -all -- {</[^luot\>][^\>]*>} $draft_list "" draft_list

    set counterA 0
    while { [string match -nocase "*<tr>*" $draft_list ] } {

       if { [incr counterA ] > 300 } {
           ns_log Error "convert_html_table_to_list, ref: counterA detected possible infinite loop."
           doc_adp_abort
        }
        # get row range
        set start_tr [string first "<tr>" $draft_list ]
        set end_tr [string first "</tr>" $draft_list ]

        # make sure that the tr end tag matches the current tr tag
        if { $end_tr == -1 } {
            set next_start_tr [string first "<tr>" $draft_list [expr { $start_tr + 4 } ] ]
        } else {
            set next_start_tr [string first "<tr>" $draft_list $end_tr ]
        }

        regsub -- {<tr>} $draft_list "<li>" draft_list

        if { $end_tr < $next_start_tr && $end_tr > -1 } {
            regsub -- {</tr>} $draft_list "     " draft_list
            # common sense says we replace </tr> with </li>, but then there may be cases missing a </tr>
            # and if so, we would have to insert a </li> which would mess up the position values for use
            # later on. Instead, at the end, we convert <li> to </li><li> and take care of the special 1st and last cases
        } 

        # we are assuming any td/tr tags occur within the table, since table has been trimmed above
        set start_td [string first "<td>" $draft_list ]
        set end_td [string first "</td>" $draft_list ]
        set next_start_td [string first "<td>" $draft_list [expr { $start_td + 3 } ] ]

        if { $next_start_td == -1 || ( $next_start_td > $next_start_tr && $next_start_tr > -1 )} {
            # no more td tags for this row.. only one column in this table

        } else {
            # setup first special case of first column
            # replacing with strings of same length to keep references current throughout loops
            set draft_list [string replace $draft_list $start_td [expr { $start_td + 3 } ] "    " ]

            if { $end_td < $next_start_tr && $end_td > -1 } {
                # there is an end td tag for this td cell, replace with :
                set draft_list [string replace $draft_list $end_td [expr { $end_td + 4 } ] ":    " ]

            } else {
                # insert special case, just prior to new td tag
                set draft_list "[string range ${draft_list} 0 [expr { ${next_start_td} - 1 } ] ]: [string range ${draft_list} ${next_start_td} end ]"
                if { $next_start_tr > 0 } {
                    incr next_start_tr 2
                }
            }
        }

        # process remaining td cells in row, separating cells by comma
        set column_separator "    "
        if { $next_start_tr == -1 } {
            set end_of_row [string length $draft_list ]
        } else {
            set end_of_row [expr { $next_start_tr + 3 } ]
        }

        set columns_to_convert [string last "<td>" [string range $draft_list 0 $end_of_row ] ]
        set counterB 0
        while { $columns_to_convert > -1 } {

            if { [incr counterB ] > 200 } {
                ns_log Error "convert_html_table_to_list, ref: counterB detected possible infinite loop."
                doc_adp_abort
            }

            set start_td [string first "<td>" $draft_list ]
            set end_td [string first "</td>" $draft_list ]
            set next_start_td [string first "<td>" $draft_list [expr { $start_td + 3 } ] ]

            if { $next_start_td == -1 } {
                # no more td tags for all rows.. still need to process this one.
                set columns_to_convert -1
                set draft_list [string replace $draft_list $start_td [expr { $start_td + 3 } ] $column_separator ]

            } elseif { ( $next_start_td > $next_start_tr && $next_start_tr > -1 ) } {
                # no more td tags for this row..
                set columns_to_convert -1

            } else {
                # add a comma before the value, if this is not the first value
                set draft_list [string replace $draft_list $start_td [expr { $start_td + 3 } ] $column_separator ]

            }

            if { $end_td > -1 && ( $end_td < $next_start_td || $next_start_td == -1 ) } {
                # there is an end td tag for this td cell, remove it
                regsub -- {</td>} $draft_list "" draft_list
            }

            set column_separator ",    "
            # next column
        }


        # next row
    }

    # clean up list, add </li>
    regsub -all -- "<li>" $draft_list "</li><li>" draft_list
    # change back first case
    regsub -- "</li><li>" $draft_list "<li>" draft_list
    # a /li tag is already included with the  list container end tag

    # remove excess spaces
    regsub -all -- {[ ]+} $draft_list " " draft_list

    # remove excess commas and format poorly placed ones
    regsub -all -- {[ ],} $draft_list "," draft_list
    regsub -all -- {[,]+} $draft_list "," draft_list

    # put colons in good form
    regsub -all -- {[ ]:} $draft_list ":" draft_list
    regsub -all -- {:,} $draft_list ":" draft_list
    # remove : in cases where first column is blank, ie li should not start with a colon
    regsub -all -- {<li>:} $draft_list "<li>" draft_list

   return $draft_list
}
ad_proc -public qf_remove_html {
    description
    {delimiter ":"}
} {

    remvoves html and converts common delimiters to something that works in html tag attributes, default delimiter is ':'

} {
    # remove tags
    regsub -all -- "<\[^\>\]*>" $description " " description

    # convert fancy delimiter to one that complies with meta tag values
    regsub -all -- "&\#187;" $description $delimiter description

    # convert bracketed items as separate (delimited) items
    regsub -all -- {\]} $description "" description
    regsub -all -- {\[} $description $delimiter description

    # convert any dangling lt/gt signs to delimiters
    regsub -all -- ">" $description $delimiter description
    regsub -all -- "<" $description $delimiter description

    # remove characters that
    # can munge some meta tag values or how they are interpreted
    regsub -all -- {\'} $description {} description
    regsub -all -- {\"} $description {} description

    # remove html entities, such as &trade; &copy; etc.
    regsub -all -nocase -- {&[a-z]+;} $description {} description

    # filter extra spaces
    regsub -all -- {\s+} $description { } description
    set description "[string trim $description]"

return $description
}

ad_proc -public qf_remove_attributes_from_html {
    description
} {

    remvoves attributes from html

} {
    # filter extra spaces
    regsub -all -- {\s+} $description { } description
    set description "[string trim $description]"

    # remove attributes from tags
    regsub -all -nocase -- {(<[/]?[a-z]*)[^\>]*(\>)} $description {\1\2} description
    
return $description
}

ad_proc -public qf_abbreviate {
    phrase
    {max_length {}}
    {suffix ".."}
    {space_substitute "&nbsp;"}
} {
    abbreviates a pretty title or phrase to first word, or to max_length characters if max_length is a number > 0
} {
    set suffix_len [string length $suffix]

    if { [qfad_is_number_p $max_length] && $max_length > 0 } {
        set phrase_len_limit [expr { $max_length - $suffix_len } ]
        regsub -all -- { / } $phrase {/} phrase
        if { [string length $phrase] > $max_length } {
            set cat_end [expr { [string last " " [string range $phrase 0 $max_length] ] - 1 } ]
            if { $cat_end < 0 } {
                set cat_end $phrase_len_limit
            }
            set phrase [string range $phrase 0 $cat_end ]
            append phrase $suffix
            regsub {[^a-zA-Z0-9]+\.\.} $phrase $suffix phrase
        }
        if { $space_substitute eq "&nbsp;" } {
            set space {\&nbsp;}
        } else {
            set space $space_substitute
        }
        regsub -all -- { } $phrase $space phrase
        set abbrev_phrase $phrase

    } else {
        regsub -all { .*$} $phrase $suffix abbrev1
        regsub -all {\-.*$} $abbrev1 $suffix abbrev
        regsub -all {\,.*$} $abbrev $suffix abbrev1
        set abbrev_phrase $abbrev1
    }
    return $abbrev_phrase
}

ad_proc -public qf_webify {
 description
} {
   standardizes and sanitizes some junky data for use in web content
} {
    # need to remove code between script tags and hidden comments
    set description_list [qf_remove_tag_contents {<script} {</script>} $description ]
    set description_new ""
    foreach desc_part $description_list {
        append description_new $desc_part
    }
    set description_list [qf_remove_tag_contents {<!--} {-->} $description_new ]
    set description_new ""
    foreach desc_part $description_list {
        append description_new $desc_part
    }
    regsub -all "<\[^\>\]*>" $description_new "" description1
    regsub -all "<" $description1 ":" description
    regsub -all ">" $description ":" description1
    regsub -all -nocase {\"} $description1 {} description
    regsub -all -nocase {\'} $description {} description1
    regsub -all -nocase {&[a-z]+;} $description1 {} description
    return $description
}

ad_proc -public qf_is_decimal {
 value
} {
   checks if value is a decimal number that can be used in tcl decimal math. Returns 1 if true, otherwise 0.
} {
    # For inspiration, see regexp from acs-tcl/tcl/json-procs.tcl 
    # which references json.org, ietf.org, Thomas Maeder, Glue Software Engineering AG and Don Baccus
    
    set positiveRE {[1-9][[:digit:]]+[.]?|[[:digit:]][.]?}
    set cardinalRE "-?(?:$positiveRE)?"
    set fractionRE {[.][[:digit:]]+}
    set exponentialRE {[eE][+-]?[[:digit:]]+}
    set numberRE "^${cardinalRE}(?:$fractionRE)?(?:$exponentialRE)?$"
    set type_decimal_p [regexp -- $numberRE $value]
    return $type_decimal_p
}

ad_proc -public qf_unquote {
 value
} {
   unquotes html similar to ad_unquotehtml except language keys, 
    so that they are not rendered. 
    Useful when creating forms with existing input values.
    Does not unqoute square brackets.
} {
    # following from ad_unquotehtml
    set value_unquoted [string map {&amp; & &gt; > &lt; < &quot; \" &#34; \" &#39; '} $value]
    regsub -all -- {\#} $value_unquoted {\&num;} value_unquoted
    return $value_unquoted
}

# tcl now has:
# string is true -strict $value
# string is false -strict $value
# in openacs api: template::util::is_true, but that looks like an wip since description does not fit actual.

ad_proc -public qf_is_true {
    value
    {default "0"}
} {
    Intreprets value as a boolean. If value is ambiguous, defaults to the value of default, usually 0.
} {
    set test1 [string is true -strict $value]
    set test2 [string is false -strict $value]
    if { $test1 == $test2 } {
        set interp_p $default
    } else {
        set interp_p $test1
    }
    return $interp_p
}

ad_proc -public qf_is_even {
    number
} {
    Returns 1 if number is even, otherwise returns 0. Works for base 1 to 16 (hexidecimal).
} {
    set even_p 0
    set last_digit [string range $number end end]
    set even_digits_list [list 0 2 4 6 8 a c e A C E]
    if { $last_digit in $even_digits_list } {
        set even_p 1
    }
    return $even_p
}


ad_proc -public hf_list_filter_by_alphanum {
    user_input_list
} {
    Returns a list of alphanumeric items from user_input_list. Allows period, comma, dash and underscore also.
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        # added dash and underscore, because these are often used in alpha/text references
        if { [regsub -all -nocase -- {[^a-z0-9,\.\-\_]+} $input_unfiltered {} input_filtered ] } {
            lappend filtered_list $input_filtered
        }
    }
    return $filtered_list
}

ad_proc -public hf_list_filter_by_decimal {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [qf_is_decimal $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
    }
    return $filtered_list
}

ad_proc -public hf_list_filter_by_natural_number {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [qf_is_natural_number $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
    }
    return $filtered_list
}

ad_proc -public hf_natural_number_list_validate {
    natural_number_list
} {
    Retuns 1 if list only contains natural numbers, otherwise returns 0
} {
    set nn_list [hf_list_filter_by_natural_number $natural_number_list]
    if { [llength $nn_list] != [llength $natural_number_list] } {
        set natnums_p 0
    } else {
        set natnums_p 1
    }
    return $natnums_p
}

ad_proc -public hf_are_visible_characters_q {
    user_input
} {
    Verifies that characters are printable, or spaces.
} {
    if { [regexp -- {^[[:graph:]\ ]+$} $user_input scratch ] } {
        set visible_p 1
    } else {
        set visible_p 0
    }
    return $visible_p
}


ad_proc -public hf_are_safe_textarea_characters_q {
    user_input
} {
    Verifies that characters are printable, or common whitespace characters.
} {
    if { [regexp -- {[[:print:][:space:]]+$} $user_input scratch ] } {
        set quasivisible_p 1
    } else {
        set quasivisible_p 0
    }
    return $quasivisible_p
}

ad_proc -public hf_are_safe_and_visible_characters_q {
    user_input
} {
    Verifies that characters are printable (or space) and safe for use in dynamic arguments, such as eval.
} {
    set visible_p [hf_are_visible_characters_q $user_input]
    if { $visible_p && [string match {*[\[;]*} $user_input] } {
        # unsafe for safe_eval etc.
        # Test here for Ui handling 
        # instead of forcing error per safe_eval
        set visible_p 0
    }
    return $visible_p
}

ad_proc -public hf_are_printable_characters_q {
    user_input
} {
    Verifies that characters are printable.
} {
    if { [regexp -- {^[[:graph:]]+$} $user_input scratch ] } {
        set printable_p 1
    } else {
        set printable_p 0
    }
    return $printable_p
}

ad_proc -public hf_are_safe_and_printable_characters_q {
    user_input
} {
    Verifies that characters are printable and safe for use in dynamic arguments, such as eval.
} {
    set printable_p [hf_are_printable_characters_q $user_input]
    if { $printable_p && [string match {*[\[;]*} $user_input] } {
        # unsafe for safe_eval etc.
        # Test here for Ui handling 
        # instead of forcing error per safe_eval
        set printable_p 0
    }
    return $printable_p
}

ad_proc -public hf_list_filter_by_printable {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [hf_are_printable_characters_q $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
    }
    return $filtered_list
}

ad_proc -public qf_listify {
    scalar_or_list
} {
    Returns a list for all cases ie if a scalar is passed, converts it to list format.
} {
    # This is mainly used for cases where an empty string is passed to a procedure,
    # Checking this special case first.
    if { $scalar_or_list eq "" } {
        set return_list [list ]
    } elseif { [llength $scalar_or_list] > 0 } {
        set return_list $scalar_or_list
    } else {
        set return_list [list $scalar_or_list]
    }
    return $return_list
}

ad_proc -public qf_uniques_of {
    a_list
} {
    Returns unique elements of a list
} {
    foreach e $a_list {
        set a(${e}) 0
    }
    set e_list [array names a]
    return $e_list
}

ad_proc -public qf_clock_scan {
    timestamp
    {scan_format ""}
} {
    Returns time_since_epoch in seconds, or empty string if there is an error. 
    Useful for converting a useful timestamp from user input.
    <br/>
    If format string is provided, scans according to format string's specifications:
    @url https://www.tcl.tk/man/tcl/TclCmd/clock.htm#M26
    <br/>
    If attempt fails, it will trying using same formatting as qf_clock_format:
    "%Y-%m-%d %H:%M:%S%z"   <br/>
    If no timezone or timezone-offset is provided, assumes utc instead of clock scan's localized preference.
    An empty timestamp returns an empty string.
    

    @see qf_clock_format
} {
    if { $timestamp eq "" } {

        # pass an empty timestamp unchanged
        set ts ""

    } else {

        if { $scan_format ne "" } {
            if {[catch { set ts [clock scan $timestamp -format $scan_format]  }]} {
                set ts ""
            } 
        } else {

            if {[catch { set ts [clock scan $timestamp ] }]} {
                set ts ""                
            } 
        }
        if { $ts ne "" } {
            if { ![string match -nocase "*z*" $scan_format] && $timestamp ne "" } { 
                # timezone offset ignored? Maybe accounted for in timestamp

                # get local tcl default offset at timestamp
                # z% Produces the current time zone, 
                # expressed in hours and minutes east (+hhmm) or west (-hhmm) of Greenwich
                # from http://www.tcl.tk/man/tcl/TclCmd/clock.htm#M78

                set timestamp_test $timestamp
                append timestamp_test "  "
                if { [regexp {[\-\+][0-9][0-9][0-9\ ][0-9\ ]$} $timestamp_test tz_offset] } {
                    if { $scan_format eq "" } {
                        # chances are, tcl interprets an appended timeoffset as decimal minutes
                        # and adjusts timestamp accordingly.
                        set tzo1 [qf_trimleft_zeros [string trim $tz_offset]]
                        ns_log Notice "qf_clock_scan.1344: Assuming timezone offset '${tz_offset}' was interpreted as '${tzo1}' minutes difference from timestamp."
                        set ts [expr { $ts + ( $tzo1 * 60 ) } ]
                    }
                } else {
                    set tz_offset_x [clock format $ts -format "%z"]
                    if { [string range $tz_offset_x 0 0] eq "-" } {
                        set tz_offset "+"
                    } else {
                        set tz_offset "-"
                    }
                    append tz_offset [string range $tz_offset_x 1 4]
                    ns_log Notice "qf_clock_scan.1346: Using localized offset. "
                } 
                ns_log Notice "qf_clock_scan.1348: tz_offset '${tz_offset}'"

                #adjust for localization adjustments
                if { ![string match "?0000" $tz_offset ] } {
                    # adjust seconds by negative of offset to get utc
                    set hh [qf_first_number_in [string range $tz_offset 1 2]]
                    # mm might be blank
                    set mm [qf_first_number_in [string range $tz_offset 3 4]]
                    set sign [string range $tz_offset 0 0]
                    append sign 1
                    if { $mm != 0 || $hh != 0 } {
                        set k [expr { -1 * $sign * ( ( $hh * 3600 ) + ( $mm * 60 ) ) } ]
                        # adjust by offset
                        set ts [expr { $ts + $k } ]
                        ns_log Notice "qf_clock_scan.1364 tz_offset '${tz_offset}' +k '${k}' ts '${ts}'"
                    }
                }
            }
        } else {
            # ts eq ""
            ns_log Notice "qf_clock_scan.1369: '${timestamp}' -format '${scan_format}' caught. Trying qf_clock_scan_from_db way."
            set ts [qf_clock_scan_from_db $timestamp]
            
            # Try again in case timestamp is from db and supplied and default scan_format are not standard.
            # Timestamp from db might look like this: 2017-04-09 14:39:20.994444-04
            # Get rid of decimal seconds
            set timestamp_alt $timestamp
            regsub -- {[\.][0-9]+} $timestamp_alt {} timestamp_alt
            set ts_len [string length $timestamp_alt]
            if { $ts_len < 20 } {
                # no %z value. 
                append timestamp_alt "-00"
            }
            set scan_format_alt "%Y-%m-%d %H:%M:%S%z"
            if {[catch { set ts [clock scan $timestamp -format $scan_format_alt] }]} {
                set ts ""
                
            } 
        }
    }
    return $ts
}

ad_proc -public qf_clock_scan_from_db {
    timestamp
    {scan_format "%Y-%m-%d %H:%M:%S%z"}
    {tz_adjust_p "1"}
} {
    Returns time_since_epoch in seconds, or empty string if there is an error. 
    Useful for converting a useful timestamp from database.
    Since database sourced timestamps are more consistent than user input, 
    a faster solution can be used than used in qf_clock_scan.
    It is assumed that the value stored in the database is in UTC.
    If format string is provided, scans according to format string's specifications:
    @url https://www.tcl.tk/man/tcl/TclCmd/clock.htm#M26
    @see qf_clock_scan

    To pass localized adjustments to timestamps from database that do not have a timezone,
    @see qf_clock_scan_from_db_wo_tz

} {
    # timestampz from db might contain a timezone.
    # As a matter of experience, these are sometimes phantom timezones
    # that distort the timestamp.
    # In these cases, set tz_adjust_p 0
    # to ignore the timezone part and assume it is UTC.
    
    # Truncate any decimal seconds
    regsub -- {[\.][0-9]+} $timestamp {} timestamp
    if { !$tz_adjust_p } {
        # remove phantom timezone
        set timestamp [string range $timestamp 0 18]
        ns_log Notice "qf_clock_scan_from_db changed timestamp '${timestamp}'"
    }
    if { $scan_format eq "" } {
        set t_s [clock scan $timestamp -gmt true]
    } else {
        set ts_len [string length $timestamp]
        if { $ts_len < 20 && [string match -nocase "*z*" $scan_format] } {
            # no %z value. 
            # Assume timestamp was written in UTC.
            append timestamp  "-00"
            # The other choice would be to assume timestamp was written assuming localized timezone,
            # See qf_clock_scan_from_db_wo_tz
        }
        if {[catch { set t_s [clock scan $timestamp -format $scan_format] }]} {
            set t_s ""
            ns_log Warning "qf_clock_scan_from_db.1435: timestamp: '${timestamp}' scan_format '${scan_format}' could not scan. t_s ''."
        } 
    }
    return $t_s
}


ad_proc -public qf_clock_scan_from_db_wo_tz {
    timestamp
    {scan_format "%Y-%m-%d %H:%M:%S%z"}
} {
    Returns time_since_epoch in seconds, or empty string if there is an error. 
    Useful for converting a useful timestamp from database.
    Since database sourced timestamps are more consistent than user input, 
    a faster solution can be used than used in qf_clock_scan.
    If format string is provided, scans according to format string's specifications:
    @url https://www.tcl.tk/man/tcl/TclCmd/clock.htm#M26

    If tz_adjust_p is "1", then localized adjustments will be made to timestamps that
    are passed (from database) without a timezone. See qf_db_api_test unit testcases for example.

    @see qf_clock_scan
} {
    # Truncate any decimal seconds
    regsub -- {[\.][0-9]+} $timestamp {} timestamp
    set ts_len [string length $timestamp]
    set adjust_p 0
    if { $ts_len < 20 } {
        set adjust_p 1
        # no %z value. 
        # Assume timestamp was written in UTC.
        append timestamp  "-00"
        # The other choice would be to assume timestamp was written assuming localized timezone,
        # and so make adjustments out as well (similar to tz_offset calcs in qf_clock_scan.
        # And yet, that has its own can of worms, since tcl clock scan assumes 00 offsets.
    }
    if { $scan_format ne "" } {
        set t_s [clock scan $timestamp -format $scan_format] 
    } else {
        set t_s [clock scan $timestamp -gmt true]
    }
    if { $adjust_p } {
        set tz_offset [clock format $t_s -format "%z"]
        #adjust for localization adjustments
        if { ![string match "?0000" $tz_offset ] } {
            # adjust seconds by negative of offset to get utc
            set hh [qf_first_number_in [string range $tz_offset 1 2]]
            # mm might be blank
            set mm [qf_first_number_in [string range $tz_offset 3 4]]
            set sign [string range $tz_offset 0 0]
            append sign 1
            if { $mm != 0 || $hh != 0 } {
                set k [expr { -1 * $sign * ( ( $hh * 3600 ) + ( $mm * 60 ) ) } ]
                # adjust by offset
                set t_s [expr { $t_s + $k } ]
                ns_log Notice "qf_clock_scan_from_db_wo_tz.3 tz_offset '${tz_offset}' +k '${k}' t_s '${t_s}'"
            }
        }
    }
    return $t_s
}


ad_proc -public qf_clock_format {
    {clock_s ""}
    {format_str "%Y-%m-%d %H:%M:%S%z"}
} {
    Returns a standard timestamp format (and UTC) for use in database. 
    PG timestamp w/o timezone prefers ISO 8601 "yyyy-mm-dd hh:mm:ss" ie "%Y-%m-%d %H:%M:%S".
    PG timestamp with timezone prefers ISO 8601 "yyyy-mm-dd hh:mm:ss-tz" ie "%Y-%m-%d %H:%M:%S%z"
   
    If clock_s is "", emtpy string is passed.
    If format is "", timestamp uses scan's default format "%a %b %d %H:%M:%S %Z %Y" for example: "Thu Apr 06 20:23:00 GMT 2017"
    
} {
    # %z consists of a + or - and upto 6 digits to offset by hhmmss
    # See pg table qf_test_types for additional notes.

    # '-gmt true' should eventually be replaced with '-timezone :UTC' http://www.tcl.tk/man/tcl/TclCmd/clock.htm#M24
    if { $clock_s ne "" } {
        if { $format_str ne "" } {
            set timestamp [clock format $clock_s -gmt true -format $format_str]
        } else {
            set timestamp [clock format $clock_s -gmt true]
        }
    } else {
        set timestamp ""
    }
    return $timestamp
}

ad_proc -public qf_sign {
    number
} {
    Returns the sign of the number value represented as -1, 0, or 1.
    If not a number, returns 0
} {
    if {[catch { set sign [expr { round( $number / double( abs ( $number ) ) ) } ] } ] } {
        set sign 0
    }
    return $sign
}

ad_proc -public qf_trimleft_zeros {
    decimal_number
} {
    Returns a tcl friendly representation of a loosely defined decimal number. 
    For example, '-0001.1' becomes '-1.1'.
    <br><br>
    Similar to <code>template::util::leadingTrim value</code>, except
    this one checks for negative numbers.

    @template::util::leadingTrim
} {
    if { [string range $decimal_number 0 0] eq "-" } {
        set tcl_num "-"
        set decimal_number [string range $decimal_number 1 end]
    }
    set decimal_number [string trimleft $decimal_number "0"]
    if { $decimal_number ne "" } {
        append tcl_num $decimal_number
    } else {
        set tcl_num 0
    }
    return $tcl_num
}

ad_proc -public qf_first_number_in {
    a_number_in_string
} {
    Returns first valid decimal number in a string. Ignores scientific notation. If no decimal found, returns 0.
} {
    set number 0
    if { [regexp -- {[\.\-0-9]+} $a_number_in_string number_maybe] } {

        # remove any inappropriate dash and anything following
        set end_idx_1 [string first "-" $number_maybe 1]
        if { $end_idx_1 > -1 } {
            set number_maybe [string range $number_maybe 0 ${end_idx_1}-1]
        }
        # remove any inappropriate period and anything following
        set dot_idx [string first "." $number_maybe ]
        if { $dot_idx > -1 } {
            set end_idx_2 [string first "." $number_maybe ${dot_idx}+1]
            if { $end_idx_2 > -1 } {
                set number_maybe [string range $number_maybe 0 ${end_idx_2}-1]
            }
        }

        set number [qf_trimleft_zeros $number_maybe]
    }            
    return $number
}

ad_proc -public qf_timestamp_w_tz_to_tz {
    timestamp_any_tz
    {tz ""}
    {timestamp_format "%Y-%m-%d %H:%M:%S%z"}
} {
    Converts a timestamp to specified timezone. 
    If timezone (tz) is empty string, converts to tcl interpreter's default timezone.
    If timestamp_format is empty string, uses clock scan's default interpretation.
    If unable to parse, returns an empty string.
} {
    set ts_new_tz ""
    # proc expects a '%z' in timestamp_format
    set ts_s [qf_clock_scan $timestamp_any_tz $timestamp_format]
    if { $ts_s ne "" } {
        if { $tz eq "" } {
            set tz_offset [clock format $ts_s -format "%z"]
        }
        set ts_new_tz [clock format $ts_s -format $timestamp_format -timezone $tz]
    }
    return $ts_new_tz
}

ad_proc -public qf_vars_to_array {
    vars_list
    array_name
} {
    Converts a list of variable names into an array name_arr where array indexes are identical to variable names in list.
    If variable doesn't exist, variable is set to empty string.
} {
    upvar 1 $array_name n_arr
    if { [llength $array_name ] == 1 } {
        foreach var $vars_list {
            upvar 1 $var $var
            if { [info exists $var ] } {
                set n_arr(${var}) [set $var]
            } else {
                set n_arr(${var}) ""
            }
        }
        set success_p 1
    } else {
        ns_log Warning "qf_vars_to_array.1628: Unexpected array_name '${array_name}'"
        set success_p 0
    }
    return $success_p
}

ad_proc -public qf_email_valid_q { query_email } {
    Returns 1 if an email address has more or less the correct form.
    Works like util_email_valid_p only more tolerant of valid addresses etc.

    @see util_email_valid_p
} {
    # Forget using common regexp with this. See https://davidcel.is/posts/stop-validating-email-addresses-with-regex/
    set parts_list [split $query_email "@"]
    set is_email_p 0
    if { [llength $parts_list] eq 2 } {
        set account [lindex $parts_list 0]
        set domain [lindex $parts_list 1]
        if { [hf_are_safe_and_visible_characters_q $account] } {
            if { [qf_domain_name_valid_q $domain ] } {
                set is_email_p 1
            } else {
                ns_log Notice "qf_email_valid_q.1652: domain '${domain}'"
            }
        } else {
                ns_log Notice "qf_email_valid_q.1655: account '${account}'"
        }
    } else {
        ns_log Notice "qf_email_valid_q.1658: different than two parts. parts_list '${parts_list}'"
    }
    return $is_email_p
}

ad_proc -public qf_domain_name_valid_q {
    domain_name
    {ends_with_dot_p "0"}
} {
    Returns 1 if is a domain name, otherwise returns 0.
    Default does not test if last character is a dot "." Change ends_with_dot_p to 1 to require dot at end.
} {

    # "..any binary string whatever can be used as the label of any
    #   resource record.. In particular, DNS servers must not
    #   refuse to serve a zone because it contains labels that might not be
    #   acceptable to some DNS client programs."
    #  RFC-2181, section 11 https://tools.ietf.org/html/rfc2181#section-11

    # At the same time, the domain *could* be required to qualify under traditional
    # practices by using PUNYCODE
    # See also https://tools.ietf.org/html/rfc3490#ref-PUNYCODE 

    #  "Host software MUST handle host names of up to 63 characters and
    #  SHOULD handle host names of up to 255 characters.
    #  Whenever a user inputs the identity of an Internet host, it SHOULD
    #  be possible to enter either (1) a host domain name or (2) an IP
    #  address in dotted-decimal ("#.#.#.#") form.  The host SHOULD check
    #  the string syntactically for a dotted-decimal number before
    #  looking it up in the Domain Name System."
    # from RFC-1123 section 2.1
    set is_name_valid_p 0
    
    # must not be all numbers, unless is an ipv4 address.
    
    if { ( $ends_with_dot_p && [string range $domain_name end end] eq "." ) || ( !$ends_with_dot_p ) } {
        if { [string length $domain_name] < 64 } {
            set parts_list [split $domain_name {.}]
            set parts_list_len [llength $parts_list]
            set all_valid_p 1
            set all_is_num_p 1
            foreach part $parts_list {
                # can begin with number or letter
                # can have any number of dashes
                set this_is_num_p [qf_is_natural_number $part]
                set part_len [string length $part]
                ns_log Notice "qf_domian_name_valid_q part_len ${part_len}"
                if { $part_len > 0 } {
                    set this_valid_p [regexp -nocase -- {^[a-z0-9\-]+$} $part scratch ]
                    if { $this_valid_p && ( [string match "-*" $part] || [string match "*-" $part] ) } {
                        set this_valid_p 0
                    }
                } else {
                    set this_valid_p 0
                }
                set all_valid_p [expr { $all_valid_p && $this_valid_p } ]
                set all_is_num_p [expr { $all_is_num_p && $this_is_num_p } ]
                ns_log Notice "qf_domain_name_valid_q domain_name '${domain_name}' part '${part}' this_valid_p $this_valid_p all_valid_p $all_valid_p all_is_num_p $all_is_num_p"
            }

            if { ( ( $parts_list_len == 3 && $all_is_num_p ) || !$all_is_num_p ) && $all_valid_p && $parts_list_len > 0 } {
                set is_name_valid_p 1
            }
        }
    }
    return $is_name_valid_p
}

##code per https://tools.ietf.org/html/rfc3490#page-10 Make procs ToASCII,ToUnicode
# to handle translation of internationalized domains

ad_proc -public qf_is_boolean {
    value
} {
    Validates boolean. Returns 1 if validates. Checks for localized case if available.
    Based on:
    <code>template::data::validate::boolean</code>

    @see template::data::validate::boolean
} {
    set value [string tolower $value]

    set valid_p 0
    switch $value {
        0 -
        1 -
        f -
        t -
        n -
        y -
        no -
        yes -
        false -
        true {
            set valid_p 1
        }
        default {
            # check for internationalized cases
            if { [qfad_is_word_p ] } {
                set yes_local [_ acs-kernel.common_yes]
                set no_local [_ acs-kernel.common_no]
                if { $value eq $yes_local || $value eq $no_local } {
                    set valid_p 1
                }
            }
        }
    }
    return $valid_p
}


ad_proc -public qf_is_currency_like {
    value 
} {
    Returns 1 if value looks like some kind of currency as decribed by 
    https://en.wikipedia.org/wiki/Currency_symbol#Usage
    <br><br>
    This is extra permissive to allow for localization variants,
    such as comma as decimal fraction separator.
    Or commas used to separate hundreds and Lakhs for example,
    the following forms: "$2.03" "Rs 50.42" "12.52L" "Y5,13" "12.345,00DKr"
    <br><br>
    Because of the variety of expressions of currency internationally,
    this just checks for availability of info for use to express currency
    without strict parsing.
    Assumes a default currency is expressed elsewhere.
    And that maybe final parsing is by human to process informal, slang forms.
} {

    # A currency may be placed instead of decimal in some cases.
    # 
    set valid_p 1
    set type_prev ""
    set a_ctr 0
    set a_len 0
    set n_ctr 0
    set c_ctr 0
    set d_ctr 0
    set m_ctr 0
    set i 0
    set value_len [string length $value ]
    while { $i < $value_len && $valid_p } {
        set v [lindex $i]
        switch -nocase -glob -- $v {
            [0-9] {
                set type "n"
                if { $type_prev ne $type } {
                    incr n_ctr
                }
            }
            "," {
                set type "c"
                if { $type_prev ne $prev } {
                     incr c_ctr
                 } else {
                     set valid_p 0
                 }
            }
            "." {
                set type "d"
                if { $type_prev ne $prev } {
                     incr d_ctr
                 } else {
                     set valid_p 0
                 }
            }
            "-" {
                set type "m"
                incr m_ctr
            }
            default {
                # alphanum that represents a currency, like USD
                set type "a"
                if { $type_prev ne $type } {
                    incr a_ctr
                } else {
                    incr a_len
                }
            }
        }
        set type_prev $type
        incr i
    }
    if { $a_len > 3 \
             || $a_ctr > 1 \
             || $n_ctr > 2 \
             || ( $c_ctr > 1 && $d_ctr > 1 ) \
             || $m_ctr > 1 } {
        set valid_p 0
    }

    return $valid_p
}


ad_proc -public qf_is_currency {
    value
    {parameters "bcefjkwhtul +s - 2 . ,s $ USD"}
} {
    Returns 1 if valid currency type as specified by parameters
    <br><br>
    Currency type is determined according to <code>parameters</code>, 
    where <code>parameters</code> consists of a space separated list of:
    <strong>flags</strong>, 
    <strong>positive signs</strong>,
    <strong>negative signs</strong>
    <strong>decimals</strong>,
    <strong>decimal character (separatrix)</strong>,
    <strong>integral separators</strong>, and
    <strong>currency signs and/or codes</strong>..
    Default is to not allow a decimal separator, positive or negative sign, or symbol or code, or a number with fewer fractional decimals than defined by second position in <code>parameters</code>. 
    Treat fractional units as separate signs/codes with their own ISO code, if necessary. For example 'USD,$ XUSD,¢'. 
    This way, any number is validated against one unit of measure of currency.
    Combinations are not validated against a standard, so validation is fully customizable.
    <br><br>
    <strong>flags</strong> If there are no flags passed, still include the
    space separator to the left of <strong>separatrix</strong>.
    An uppercase flag indicates that the flag's attribute is required.
    Lowercase indicates the flag's attribute is optional.
    <br>Available flags:
    <ul><li>
    a - allow negative sign as prefix to number
    </li><li>
    b - allow negative sign as suffix to number
    </li><li>
    c - allow negative sign anywhere before number
    </li><li>
    d - allow positive sign as prefix to number
    </li><li>
    e - allow positive sign as suffix to number
    </li><li>
    f - allow positive sign anywhere before number
    </li><li>
    j - allow one currency code or sign before the number
    </li><li>
    k - allow one currency code or sign after the number
    </li><li>
    w - allow strict interpretation of non-decimal separators in threes:
    For example: 1,000,000,000,000 but not 1,00,000 (as with Indian Rs.)
    </li><li>
    h - allow strict interpretation of Indian Lakh non-decimal separators:
    For example: 167,89,000,00,00,000  
    See: https://en.wikipedia.org/wiki/Indian_numbering_system#Use_of_separators
    </li><li>
    t - allow fewer decimals to the right of the 'decimals' separator.
    </li><li>
    u - ignore upper/lowercase designation in codes and symbols.
    </li></ul>
    <p>Two additional parameters are for admin level use when debugging or testing apps. Lowercase L 'l' logs reason validation fails to server log. 'L' passes the log message to an <code>upvar</code>'d variable where it can be used with building a more responsive UI and the like.
    <br><br>
    <strong>positive signs</strong> Usually "+" and/or space " ", where space is indicated by "s":  +s
    <br><br>
    <strong>negative signs</strong> Usually "-". May be changed to include em-dsh or some other variants.
    <br><br>
    <strong>decimals</strong>  The number of decimals that represent
    the fractional part of the value.
    <br><br>
    <strong>separatrix</strong> is the character to use to separate 
    integral (whole) currency units from fractional currency units. Multiple choices are allowed.
    <br>
    Set this to 
    <ul><li>
    m - if currency sign is allowed here.
    </li><li>
    n - if no separatrix is allowed (because it is implied)
    </li></ul>
    Uppercase means the 'M' or 'N' are required, 
    consistent usage with above uppercase usage.
    <br><br>
    <strong>integral separators</strong> 
    This is the separator used to separate
    multiple inetgral (whole) units, such as thousands from hundreds of units.
    For background, see: https://en.wikipedia.org/wiki/Decimal_separator#Other_numeral_systems
    If multiple characters are appended together, any is considered valid as
    long as it is consistently applied. 
    's' means space character. A number such as '12,345 678.'
    would not be a consistent use of ',s', whereas '12,345,678.' and
    '12 345 678.' are valid for the default case 
    provided when <code>parameters</code> is an empty string.
    <br><br>
    <strong>currency signs and/or codes</strong>
    This is space separated list of symbols and codes.
    <code>code</code> refers to ISO-4217 codes, or similar.
    See https://en.wikipedia.org/wiki/ISO_4217 and
    https://en.wikipedia.org/wiki/List_of_circulating_currencies
    <br><br>
    Provide each code and symbol pair with a space delimiter between them.
    If more than one currency is represented, 
    separate each currency with a space.
    If only a symbol or code is expected for a particular currency, 
    then supply symbol or code options separated by comma.
    If more than one currency is represented, 
    Here is an example, supply like so without quotes:
    'USD,$ GBP,£ JPY,¥ EUR,€ XBT Ξ XRP BOB,Bs. XOF,Fr BAM,KM,КМ'
    To handle limitations of keyboards and the like, 
    multiple symbols may be supplied that match a single alphanumeric code,
    or example, 'ITL,₤,£ CNY,¥,元 LKR,Rs,රු ,ரூ' 
    <br><br>
    Symbols are partly derived from variants expressed at:
    https://en.wikipedia.org/wiki/Currency_symbol
    <br><br><br>
    This is an attempt at simplifying ad_form currency validation via 
    <code>template::data::validate::currency</code>
    Positive signs are plus "+" or space " ". Negative signs are parenthesis or "-".

    @see template::data::validate::currency
    
} {
    # For flags 'l' and "L"
    set upvar_varname_to_use "__qf_verror_list"
    set upvar_varname ""
    upvar 1 __qf_verror_list $upvar_varname_to_use

    set params_list [split $parameters " "]
    set flags_list [split [lindex $params_list 0] ""]

    set positives [lindex $params_list 1]
    set negatives [lindex $params_list 2]
    set decimals_max [lindex $params_list 3]

    # Answers question: What characters are allowed/required in 
    # position that separates integral units from fractional ones?

    set separatrixes_or_mn [lindex $params_list 4]

    # Answers question: What characters separate integral units
    # to make them easier to read by convention?
    set integral_separators [lindex $params_list 5]

    # What currency codes and signs are allowed?
    set signs_codes_list [lrange $params_list 6 end]

    # setup flags
    set valid_p 1

    # alllowed flags

    set log_messages_p 0
    set negative_prefix_allowed_p 0
    set negative_suffix_allowed_p 0
    set negative_before_allowed_p 0
    set positive_prefix_allowed_p 0
    set positive_suffix_allowed_p 0
    set positive_before_allowed_p 0
    set currency_code_before_allowed_p 0
    set currency_code_after_allowed_p 0
    set integral_separator_in_threes_allowed_p 0
    set integral_separator_in_lakhs_allowed_p 0
    set currency_as_separatrix_allowed_p 0
    set no_separatrix_allowed_p 0
    set parens_allowed_p 0
    set parens_wrap_currency_allowed_p 0
    set parens_and_negative_redundancy_allowed_p 0

    # required flags
    set negative_prefix_required_p 0
    set negative_suffix_required_p 0
    set negative_before_required_p 0
    set positive_prefix_required_p 0
    set positive_suffix_required_p 0
    set positive_before_required_p 0
    set currency_code_before_required_p 0
    set currency_code_after_required_p 0
    set integral_separator_in_threes_required_p 0
    set integral_separator_in_lakhs_required_p 0
    set currency_as_separatrix_required_p 0
    set no_separatrix_required_p 0
    set parens_required_p 0
    set parens_wrap_currency_required_p 0


    # other flags
    set ignore_case_in_codes_symbols_p 0
    set truncated_decimals_allowed_p 0
    set redundant_parens_negative_allowed_p 0
    
    
    foreach f $flags_list {
        switch -exact -- $f {
            a {
                set negative_prefix_allowed_p 1
            }
            A {
                set negative_prefix_required_p 1
            }
            b {
                set negative_suffix_allowed_p 1

            }
            B {
                set negative_suffix_required_p 1

            }
            c {
                set negative_before_allowed_p 1
            }
            C {
                set negative_before_required_p 1
            }
            d {
                set positive_prefix_allowed_p 1
            }
            D {
                set positive_prefix_required_p 1
            }
            e {
                set positive_suffix_allowed_p 1
            }
            E {
                set positive_suffix_required_p 1
            }
            f {
                set positive_before_allowed_p 1
            }
            F {
                set positive_before_required_p 1
            }
            j {
                set currency_code_before_allowed_p 1
            }
            J {
                set currency_code_before_required_p 1
            }
            k {
                set currency_code_after_allowed_p 1
            }
            K {
                set currency_code_after_required_p 1
            }
            w {
                set integral_separator_in_threes_allowed_p 1
            }
            W {
                set integral_separator_in_threes_required_p 1
            }
            h {
                set integral_separator_in_lakhs_allowed_p 1
            }
            H {
                set integral_separator_in_lakhs_required_p 1
            }
            p {
                set parens_allowed_p 1
            }
            P {
                set parens_required_p 1
            }
            q {
                set parens_wrap_currency_allowed_p 1
            }
            Q {
                set parens_wrap_currency_required_p 1
            }
            T -
            t {
                # 'T' required? Where's the Ministry of Pragmatism?
                set truncated_decimals_allowed_p 1
            }
            U -
            u {
                # 'U' is not significant here
                set ignore_case_in_codes_symbols_p 1
            }
            R -
            r {
                # Still treat as a negative number. 
                # Surely user wants to be certain value is negative.
                set redundant_parens_negative_allowed_p 1
            }
            l {
                set log_messages_p 1
            }
            L {
                set upvar_varname $upvar_varname_to_use
            }
            default {
                ns_log Warning "qf_is_currency.1976: flag '${f}' unknown. Ignored."
            }
        }
    }

    # integral separator flags
    set s_i 0
    set separatrixes ""
    set separatrixes_or_mn_len [string length $separatrixes_or_mn]
    while { $s_i < $separatrixes_or_mn_len } {
        set s [string range $separatrixes_or_mn $s_i $s_i]
        switch -exact -- $s {
            m {
                set currency_as_separatrix_allowed_p 1
            }
            M {
                set currency_as_separatrix_required_p 1
            }
            n {
                set no_separatrix_allowed_p 1
            }
            N {
                set no_separatrix_required_p 1
            }
            default { 
                append separatrixes $s
            }
        }
        incr s_i
    }

    # map currencies allowed

    set signs_and_codes ""
    foreach currency_set $signs_codes_list {
        set symbol_or_code_list [split $currency_set ","]
        foreach c $symbol_or_code_list {
            # Would be nice to use concat, but index may not be defined
            # and adding an IF seems expensive for a potentially long list
            foreach d $symbol_or_code_list {
                lappend c_arr(${c}) $d
            }
            append signs_and_codes $c
            set c_len [string length $c]
            for {set i 0} {$i < $c_len} {incr i} {
                # signs_codes_pos_arr
                # will check validity of character as it is parsed
                # by checking character in context of local position
                append signs_codes_idx_arr(${i}) [string range $c $i $i]
            }
        }
    }

    # parse, setup
    # Strictest requirements prevail over more flexible ones


    # types in a tree of paths of acceptable possibilities
    #       Each index lists acceptable next step(s).
    array set types_larr [list \
                              start [list ] \
                              symbol [list ] \
                              integral_num [list ] \
                              separatrix [list ] \
                              fractional_num [list ] \
                              paren_left [list ] \
                              paren_right [list ] \
                              positive_sign [list ] \
                              negative_sign [list ] \
                              end [list ] ]

    # set base case
    lappend types_larr(start) integral_num
    lappend types_larr(integral_num) separatrix
    lappend types_larr(separatrix) fractional_num
    lappend types_larr(fractional_nu) end

    if { $negative_prefix_allowed_p || $negative_prefix_required_p } {
        lappend types_larr(start) negative_sign
        lappend types_larr(negative_sign) integral_num
        if { $negative_prefix_required_p } {
            # break non_negative paths
            set types_larr(start) [list negative_sign]
        }
    }
    if { $negative_suffix_allowed_p || $negative_suffix_required_p } {
        lappend types_larr(fractional_num) negative_sign
        lappend types_larr(negative_sign) end
        if { $negative_suffix_required_p } {
            # break non_negative_paths
            set types_larr(fractional_num) negative_sign
        }
    }
    if { $negative_before_allowed_p || $negative_before_required_p } {
        # anytime before integral_num, means
        set paths_lists [list [list start integral_num] \
                            [list start symbol] \
                            [list symbol integral_num] \
                            [list paren_left symbol] \
                            [list symbol paren_left] ]
        foreach path_list $paths_lists {
            lassign $path_list a b
            lappend types_larr(${a}) negative_sign
            lappend types_larr(negative_sign) ${b}
        }

    }
    if { $positive_prefix_allowed_p || $positive_prefix_required_p } {
        lappend types_larr(start) positive_sign
        lappend types_larr(positive_sign) integral_num
        if { $positive_prefix_required_p } {
            # break non_positive paths
            set types_larr(start) [list positive_sign]
        }
    }
    if { $positive_suffix_allowed_p || $positive_suffix_required_p } {
        lappend types_larr(fractional_num) positive_sign
        lappend types_larr(positive_sign) end
        if { $positive_suffix_required_p } {
            # break non_positive_paths
            set types_larr(fractional_num) positive_sign
        }
    }
    if { $positive_before_allowed_p || $positive_before_required_p } {
        # anytime before integral_num, means
        set paths_lists [list [list start integral_num] \
                            [list start symbol] \
                            [list symbol integral_num] \
                            [list paren_left symbol] \
                            [list symbol paren_left] ]
        foreach path_list $paths_lists {
            lassign $path_list a b
            lappend types_larr(${a}) positive_sign
            lappend types_larr(positive_sign) ${b}
        }

    }
    if { $currency_code_before_allowed_p || $currency_code_before_required_p } {
        # anytime before integral_num, means
        set paths_lists [list [list start integral_num] \
                             [list start positive_sign] \
                             [list start negative_sign] \
                             [list positive_sign integral_num] \
                             [list negative_sign integral_num] \
                             [list paren_left positive_sign] \
                             [list paren_left negative_sign] \
                             [list positive_sign paren_left] \
                             [list negative_sign paren_left] ]
        foreach path_list $paths_lists {
            lassign $path_list a b
            lappend types_larr(${a}) symbol
            lappend types_larr(symbol) ${b}
        }

    }


    if { $currency_code_after_allowed_p || $currency_code_after_required_p } {
        # anytime after fractional_num
        lappend types_larr(fractional_num) symbol
        lappend types_larr(symbol) end
        if { $positive_suffix_allowed_p || $postive_suffix_required_p } {
            lappend types_larr(positive_sign) symbol
        }
        if { $negative_suffix_allowed_p || $negative_suffix_required_p } {
            lappend types_larr(negative_sign) symbol
        }
    }





    if { $parens_allowed_p || $parens_required_p } {
        # anytime before integral_num, means
        set paths_lists [list [list start integral_num] \
                             [list start positive_sign] \
                             [list start negative_sign] \
                             [list positive_sign integral_num] \
                             [list negative_sign integral_num] \
                             [list symbol positive_sign] \
                             [list symbol negative_sign] \
                             [list symbol integral_num] ]

        foreach path_list $paths_lists {
            lassign $path_list a b
            lappend types_larr(${a}) paren_left
            lappend types_larr(paren_left) ${b}
        }


    }
    if { $parens_allowed_p || $parens_required_p } {
        # anytime after fractional_num means
        set paths_lists [list [list fractional_num end] \
                             [list separatrix end] \
                             [list positive_sign end] \
                             [list negative_sign end] ]
        foreach path_list $paths_lists {
            lassign $path_list a b
            lappend types_larr(${a}) paren_right
            lappend types_larr(paren_right) ${b}
        }
        
        if { $parens_wrap_currency_allowed_p \
                 || $parens_wrap_currency_required_p } {
            
            # before symbol
            #redundant types_larr(start) paren_left
            lappend types_larr(paren_left) symbol
            
            # after symbol
            lappend types_larr(symbol) paren_right
            #redundant types_larr(paren_right) end
        }
    }

    if { $currency_as_separatrix_allowed_p } {
        lappend types_larr(integral_num) "symbol"
        lappend types_larr(symbol) "fractional_num"
        # Since symbol is also possible in other places,
        # check currency_as_separatrix_required_p at end

    }
    if { $no_separatrix_allowed_p } {
        # fractional_num will be missing from the type path
        # when no_separatrix exists.
        # To adapt, add the branches of fractional_num to integral_num
        set types_larr(fractional_num) [concat $types_larr(fractional_num) \
                                            $types_larr(integral_num) ]
        # It's okay if there are duplicates in the list.
    }

    # Parse value

    # initializations and setup
    set value_len [string length $value]
    set num_prev ""
    set i_num 0
    set i_separatrix 0
    set i_paren_left 0
    set i_paren_right 0
    set i_negative_sign 0
    set i_positive_sign 0
    set i_symbol 0
    set symbol_char_idx 0
    set numerals "0123456789"
    set numerals_w_integral_seps $numerals
    append numerals_w_separators $integral_separators
    set paren_right ")"
    set paren_left "("
    set num_arr(0) ""
    set num_arr(1) ""
    # Convert positive sign,negative sign and separatrix parameters to
    # any representative characters, such as 's' becomes ' '
    regsub -- {s} $positives { } positives
    regsub -- {s} $negatives { } negatives
    regsub -- {s} $separatrixes { } separatrixes
    regsub -- {s} $integral_separators { } integral_separators


    set types_ol [list "start"]
    set e_prev ""
    # e_type is type of e
    # e_type_prev is previous e_type
    set e_type_prev ""
    set e_next [string range $value 0 0]
    # type_prev is previous, different type
    set type_prev ""

    while { $valid_p && $i < $value_len && $e_next ne "" } {
        set e $e_next
        set e_next [string range $value $i+1 $i+1]
        # determine e_type
        # Using nested 'if's to reduce cpu time 
        #      and avoid cpu intense regular expressions.
        set n_idx [string first $e $numerals_w_integral_seps]

        if { $n_idx > -1 } {
            # type: integral_num or fractional_num
            if { ![string match "*_num" $e_type_prev ] } {
                incr i_num
                if { $i_num > 2 } {
                    set valid_p 0
                }
            }
            append num_arr(${i_num}) $e
            if { $n_idx < 10 && $i_num eq 2 } {
                set e_type "fractional_num"
            } else {
                set e_type "integral_num"
            }

        } else { 

            # check ignore_case_in_codes_symbols_p, before checking for symbol

            if { $ignore_case_in_codes_symbols_p } {
                set symbol_p [string match -nocase "*${e}*" $signs_and_codes ]
            } else {
                set s_idx [string first $e $signs_and_codes]
                if { $s_idx > -1 } {
                    set symbol_p 1
                } else {
                    set symbol_p 0
                }
            }

            if { $symbol_p } {

                set e_type "symbol"
                if { $e_type_prev eq $e_type } {
                    # check if character is valid in position of currency code
                    incr symbol_char_idx
                } else {
                    set symbol_char_idx 0
                }
                # Is character expected within symbol?
                if { $ignore_case_in_codes_symbols_p } {
                    set expected_p [string match -nocase "*${e}*" $signs_codes_idx_arr(${symbol_char_idx}) ]
                } else {
                    if { [string first $signs_codes_idx_arr(${symbol_char_idx}) ] < 0 } {
                        set expected_p 0
                    }
                }
                if { !$expected_p } {
                    set valid_p 0
                    qf_log -message "qf_is_currency.2379: '${e}' \
 not found in list of supplied currency codes and signs: '${signs_and_codes}' \
 specifically, \
 after '{$e_prev}' must be one of '$signs_codes_idx_arr(${symbol_char_idx})'" \
                        -by_notice $log_messages_p \
                        -by_upvar $upvar_varname
                }

            } elseif { [string first $e $separatrixes] > -1 } {
                set e_type "separatrix"
                incr i_separatrix
                if { $i_separatrix > 1 } {
                    set valid_p 0
                }
            } elseif { $e eq $paren_left } {
                set e_type "paren_left"
                incr i_paren_left
                if { $i_paren_left > 1 } {
                    set valid_p 0
                }
            } elseif { $e eq $paren_right } {
                set e_type "paren_right"
                incr i_paren_right
                if { $i_paren_right > 1 } {
                    set valid_p 0
                }
            } elseif { [string first $e $negatives] > -1 } {
                set e_type "negative_sign"
                incr i_negative_sign
                if { $i_negative_sign > 1 } {
                    set valid_p 0
                }
            } elseif { [string first $e $positives] > -1 } {
                set e_type "positive_sign"
                incr i_positive_sign
                if { $i_positive_sign > 1 } {
                    set valid_p 0
                }
            } else {
                set e_type ""
                set valid_p 0
                qf_log -message "qf_is_currency.2400: '${e}' \
 not part of a currency pattern according to params_list '${params_list}'" \
                    -by_notice $log_messages_p \
                    -by_upvar $upvar_varname

            }
        }
        
        if { !$valid_p } {
            qf_log -message "qf_is_currency.2454: invalid, maybe too many of \
 e '${e}' e_type '${e_type}'" \
                        -by_notice $log_messages_p \
                        -by_upvar $upvar_varname
        }

        if { $e_type ne $e_type_prev } {
            set type_prev $e_type_prev
            lappend types_ol $e_type
        }
        set e_prev $e
        set e_type_prev $e_type
        
        incr i
    }

    # Are types in an expected path? 
    # We ask after path is made, because some patterns cannot be 
    # validated until entire pattern is parsed.
    lappend types_ol "end"
    set types_ol_len [llength $types_ol]
    set type_idx 1
    # First entry of types_ol is always 'start'
    set type_prev "start"
    while { $valid_p && $type_idx < $types_ol_len } {
        set type [lindex $types_ol $type_idx]
        if { [lsearch -exact $types_larr(${type_prev}) $type] < 0 } {
            qf_log -message "qf_is_currency.2421. type '${type}' not found in \
 types_larr(${type_prev}) '$types_larr(${type_prev})' types_ol '${types_ol}'" \
                -by_notice $log_messages_p \
                -by_upvar $upvar_varname
            
            set valid_p 0
        }
        incr type_idx
        set type_prev $type
        ns_log Notice "qf_is_currency.2532 type_idx $type_idx"
    }
   

    if { $valid_p } {
        # What other checks need to be made?
        # Check for required cases 
        # that cannot be ruled out by branch-based map.

        # check negative_before_required_p manually to reduce complexity
        if { $negative_before_required_p && $valid_p } {
            if { $i_negative_sign ne 1 \
                     || ( $i_paren_left ne 1 \
                              && $i_paren_right ne 1 ) } {
                # There must be a negative
                set valid_p 0
                qf_log -message "qf_is_currency.2498. negative_sign required, \
 not found." \
                    -by_notice $log_messages_p \
                    -by_upvar $upvar_varname
            }
        }


        # check positive_before_required_p manually to reduce complexity
        if { $positive_before_required_p && $valid_p } {
            if { $i_positive_sign ne 1 } {
                set valid_p 0
                qf_log -message "qf_is_currency.2508. positive_sign required, \
 not found." \
                    -by_notice $log_messages_p \
                    -by_upvar $upvar_varname
            }
        }

        # check parens_required_p manually to reduce complexity
        if { $parens_required_p && $valid_p } {
            if { $i_paren_left ne 1 \
                     && $i_paren_right ne 1 } {
                set valid_p 0
                qf_log -message "qf_is_currency.2518. parenthesis required, \
 not found." \
                    -by_notice $log_messages_p \
                    -by_upvar $upvar_varname
            }
        }
        
        
        # Following must be checked manually, because
        # symbol may be after paren_left or before paren_right
        if { $currency_code_before_required_p \
                 || $currency_code_after_required_p } {

            set symbol_idx_list [lsearch -exact -all $types_ol "symbol"]
            if { $currency_code_before_required_p } {
                set integral_num_idx [lsearch -exact $types_ol "integral_num"]
                if { [lindex $symbol_idx_list 0] > $integral_num_idx } {
                    set valid_p 0
                    qf_log -message "qf_is_currency.2602. symbol not before integral_num." \
                        -by_notice $log_messages_p \
                        -by_upvar $upvar_varname
                }
            }
            if { $currency_code_after_required_p } {
                # Careful here. separatrix may be a symbol,
                # and there may not be a fractional_num if separatrix
                # is allowed to be omitted. So, search a cascade of
                # possibilities to catch all cases, based on flags.
                if { $no_separatrix_allowed_p \
                         || $currency_as_separatrix_allowed_p } {
                    # If currency_as_separatrix_allowed, then another symbol
                    # will exist right after integral_num
                    # If no separatrix_allowed, then there may not be
                    # a fractional_num type.
                    # Use integral_num_idx +1 as the boundary to check for 
                    # cases "after"
                    if { ![info exists integral_num_idx] } {
                        set integral_num_idx [lsearch -exact $types_ol "integral_num"]
                    }
                    incr integral_num_idx 2
                    if { [lindex $symbol_idx_list end] < $integral_num_idx } {
                        set valid_p 0
                        qf_log -message "qf_is_currency.2599. symbol required after separatrix." \
                            -by_notice $log_messages_p \
                            -by_upvar $upvar_varname
                    }

                } else {
                    # common case
                    set fractional_num_idx [lsearch -exact $types_ol "fractional_num"]
                    if { [lindex $symbol_idx_list end] < $fractional_num_idx } {
                        set valid_p 0
                        qf_log -message "qf_is_currency.2602. symbol required after fractional_num." \
                            -by_notice $log_messages_p \
                            -by_upvar $upvar_varname
                    }
                }
            }
            if { $parens_wrap_currency_required_p && $valid_p } {
                set paren_left_idx [lsearch -exact $types_ol "paren_left"]
                set paren_right_idx [lsearch -exact $types_ol "paren_right"]
                
                if { $currency_code_after_required_p } {
                    if { [lindex $symbol_idx_list end] > $paren_right_idx } {
                        set valid_p 0
                        qf_log -message "qf_is_currency.2611. symbol after parenthises found." \
                            -by_notice $log_messages_p \
                            -by_upvar $upvar_varname
                    }
                }
                if { $currency_code_before_required_p } {
                    if { [lindex $symbol_idx_list 0] < $paren_left_idx } {
                        set valid_p 0
                        qf_log -message "qf_is_currency.2620. symbol before parenthises found." \
                            -by_notice $log_messages_p \
                            -by_upvar $upvar_varname
                    }
                }
            }
        }

        # check truncated_decimals_allowed_p
        # ie truncated decimals *not* allowed
        if { !$truncated_decimals_allowed_p && $valid_p } {
            
            # Consider also that fractional_num has length of 0
            # when there is no separatrix. 
            # In that case, verify length against integral_num,
            # and allow all cases where decimals are longer than
            # minimum regardless of $truncated_decimals_allowed_p,
            # because the check becomes insignificant.
            # num_arr(1) is integral_num
            # num_arr(2) is fractional_num
            if { $i_separatrix eq 0 } {
                if { [string length $num_arr(1) ] < $decimals_max } {
                    set valid_p 0
                    qf_log -message "qf_is_currency.2541: integral_num \
 substituted for fractional_num, number has too few digits." \
                        -by_notice $log_messages_p \
                        -by_upvar $upvar_varname
                }
            } else {
                if { [string length $num_arr(2) ] ne $decimals_max } {
                    set valid_p 0
                    qf_log -message "qf_is_currency.2547: '${decimals_max}' \
 decimals required in the fractional part." \
                        -by_notice $log_messages_p \
                        -by_upvar $upvar_varname
                }
            }
        }

        # check redundant_parens_negative_allowed_p
        if { !$redundant_parens_negative_allowed_p && $valid_p } {
            if { $i_negative_sign eq 1 \
                     && $i_paren_left eq 1 \
                     && $i_paren_right eq 1 } {
                set valid_p 0
                qf_log -message "qf_is_currency.2514. negative_sign and \
 parenthesis found. Using both is not permitted by flags." \
                    -by_notice $log_messages_p \
                    -by_upvar $upvar_varname
            }
        }

        # check currency_as_separatrix_required_p 
        if { $currency_as_separatrix_required_p && $valid_p } {
            # check in the path of types
            set integral_idx [lsearch -exact $types_ol "integral_num"]
            if { [lindex $types_ol ${integral_idx}+1 ] ne "symbol" } {
                set valid_p 0
                qf_log -message "qf_is_currency.2593. Expected \
 a currency symbol instead of a separatrix (comma, period as set by flags)" \
                    -by_notice $log_messages_p \
                    -by_upvar $upvar_varname
            }
        }
    }        

    return $valid_p
}

ad_proc -private qf_log {
    -message
    {-by_notice "0"}
    {-by_warning "0"}
    {-by_upvar ""}
} {
 OA   Passes message to server log and/or to calling proc via upvar.
    <br><br>
    This proc helps with converting code between app-level debugging,
    and UI entry issues, by directing message in context of expectations,
    which may be selectable at runtime by calling proc.
    <br><br>
    If <code>by_upvar</code> is not empty string, <code>lappend</code>s message to 
    variable of that name for perhaps passing to UI via <code>util_user_message</code>. If value of by_upvar is a number or nonstandard variable name, and user is an admin, message is passed directly to util_user_message otherwise ignored.
    <br><br>
    If <code>by_notice</code> is true, logs message in server log as 'Notice'.
    <br><br>
    If <code>by_warning</code> is true, logs message in server log as 'Warning'.
    @see util_user_message
} {
    set m "qf_log:"
    append m $message
    if { $by_upvar ne "" } {
        if { [string match {[\_a-z]*} $by_upvar] } {
            upvar 1 $by_upvar upvar_message_list
            lappend upvar_message_list ${message}
        } else {
            if { [ad_conn isconnected] } {
                set user_id [ad_conn user_id]
                set package_id [ad_conn package_id]
                set admin_p [permission::permission_p -party_id $user_id \
                                 -object_id $package_id \
                                 -privilege admin]
                if { $admin_p } {
                    util_user_message -message $m
                }
            } 
        }
    }
    if { [qf_is_true $by_notice] } {
        ns_log Notice $m
    }
    if { [qf_is_true $by_warning] } {
        ns_log Warning $m
    }
    return 1
}

### editing
# Following procs are generated from
# deprecated ad_var_type_check_* in acs-tcl/tcl/utilities-procs.tcl
# They are added here, because form validation should avoid separate namespaces
# for security reasons

ad_proc -public qfad_is_integer_p {value} {
    @return 1 if $value is an (positive) integer or zero, 0 otherwise.
    
    In general, use either template::data::validate::integer
    or "string is integer -strict" instead.

    @see ::template::data::validate::integer
} {
    # was ad_var_type_check_integer_p
    if { [regexp {[^0-9]} $value] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public qfad_is_safefilename_p {value} {
    @return 0 if the file contains ".."
} {
    # was ad_var_type_check_is_safefilename_p
    if { [string match "*..*" $value] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public qfad_is_dirname_p {value} {
    @return 0 if $value contains a / or \, 1 otherwise.
} {
    # ad_var_type_check_dirname_p
    if { [regexp {[/\\]} $value] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public qfad_is_number_p {value} {
    @return 1 if $value is a valid number
} {
    # was ad_var_type_check_number_p
    if { [catch {expr {1.0 * $value}}] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public qfad_is_word_p {value} {
    @return 1 if $value contains only letters, numbers, dashes,
            and underscores, otherwise returns 0.
} {
    # was ad_var_type_check_is_word_p
    if { [regexp {[^-A-Za-z0-9_]} $value] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public qfad_is_noquote_p {value} {
    @return 1 if $value contains any single-quotes
} {
    # was ad_var_type_check_is_noquote_p
    if { [string match "*'*" $value] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -public qf_append_lol {
    lol1_name
    lol2
} {
    Appends list of lists lol1_name with lol2 list items appended.
    lol1_name is the name of the list of lists.
    lol2 is a list of lists (not the name).
    @return 1
} {
    upvar 1 $lol1_name first_lol
    
    foreach f_list $lol2 {
        lappend first_lol $f_list
    }
    return 1
} 

ad_proc -public qf_esc_doublequotes {
    value
} {
    Escape all double quotes used in a string.
} {
    regsub -all -- {\"} $value {\"} value
    return $value
}

ad_proc -public qf_esc_nvl_doublequotes {
    nv_list
} {
    set nv2_list [list ]
    foreach {n v} $nv_list {
        lappend nv2_list $n [qf_esc_doublequotes $v]
    }
    return $nv2_list
}

ad_proc -public qss_list_of_lists_to_responsive_table { 
    {-table_list_of_lists_name ""}
    {-table_div_attribute_list_name ""}
    {-td_div_inner_attribute_lists_name ""}
    {-td_div_outer_attribute_lists_name ""}
    {-th_rows "1"}
    {-tr_div_even_attribute_list_name ""}
    {-tr_div_odd_attribute_list_name ""}
    {-th_div_attribute_list_name ""}
} {
    Converts a tcl list_of_lists to an html table made of div tags and css,
    returns table as text/html.  This presents a table in a way that fits
    the screen regardless of width
    (within practical reasons, from phone screen to desktop screen)
    without shrinking the fonts.
    
    *_attribute_list may be a list of attribute name/value pairs to pass to the
    particular tag. Here are the prefixes and their meanings:
    <br><br><pre>
    table_div_       The DIV tag used in place of the TABLE tag.
    td_div_inner_    The DIV tag used for formatting cell contents
    td_div_outer_    The DIV tag used for sizing the column width.
    .                  Each item represents attribute/value pairs for one cell.
    th_rows          The number of title/header rows. Best to keep at 1.
    .                  because td_div_outer_ DIVs are titled with the
    .                  cooresponding cell values of the first title row.
    tr_div_even_     The DIV used to wrap cells on even numbered rows.
    tr_div_odd_      The DIV used to wrap cells on odd numbered rows.
    th_div_          The DIV used to wrap title/header rows.
    attribute_list   expects: list attribute1 value1 attribute2 value2..
    attribute_lists  (note the suffix 's') expects:
    .  list attribute_lists_for_cell1 attribute_lists_for_cell2... 
    td_attribute_lists adds attributes to the td_DIV tags at the same
    . position as table_list_of_lists cells in a one-to-one coorespondence.
    . If only one row is provided, the same row is repeated for all rows.
    . If multiple rows are provided, the last row is repeated for all
    .   remaining rows. To use the default, set the last row
    .   in td_attribute_lists to empty lists.
    Number of th_rows sets the number of rows that are designated as
      headers/titles. Default is 1.
    table_list_of_lists and td_div_inner_attribute_lists are represented
      {row1 {cell1} {cell2} {cell3} .. {cell x} } {row2 {cell1}...}
    td_div_outer_attribute_lists repeat the first row's values for every row
      in order to make cells consistent within a column.
    Note that attribute - value pairs in td_attribute_lists can be added
      uniquely to each TD tag.
    </pre>
    <br><br>
    This proc is based on and derived from
    @see qss_list_of_lists_to_html_table
} {
    upvar 1 $table_list_of_lists_name table_list_of_lists
    upvar 1 $table_div_attribute_list_name table_atts_list
    upvar 1 $td_div_inner_attribute_lists_name td_div_inner_atts_lists
    upvar 1 $td_div_outer_attribute_lists_name td_div_outer_atts_lists
    upvar 1 $tr_div_even_attribute_list_name tr_div_even_atts_list
    upvar 1 $tr_div_odd_attribute_list_name tr_div_odd_atts_list
    upvar 1 $th_div_attribute_list_name th_div_atts_list
    # th = thead or table header row(s)

    array set table_atts_arr [list title "\#acs-templating.Table\#"]
    if { [info exists table_atts_list] } {
        array set table_atts_arr $table_atts_list
    }
    set table_atts_list [array get table_atts_arr]
    

    array set tr_div_even_atts_arr [list class even]
    if { [info exists tr_div_even_atts_list] } {
        array set tr_div_even_atts_arr $tr_div_even_atts_list
    }
    set tr_div_even_atts_list [array get tr_div_even_atts_arr]

    array set tr_div_odd_atts2_arr [list class odd]
    if { [info exists tr_div_odd_atts_list] } {
        array set tr_div_odd_atts_arr $tr_div_odd_atts_list
    }
    set tr_div_odd_atts_list [array get tr_div_odd_atts_arr]

    array set th_div_atts_arr [list title "\#q-forms.Headings\#"]
    if { [info exists th_div_atts_list] } {
        array set th_div_atts_arr $th_div_atts_list
    }
    set th_div_atts_list [array get th_div_atts_arr]

    if { ![info exists td_div_outer_atts_lists ] } {
        ns_log Error "qss_list_of_lists_to_responsive_table.2979: Must supply td_div_outer_attribute_lists_name. "
        ad_script_abort
    }
    
    set fs "/"
    set th "div"
    set gt ">"
    set lt "<"
    set quote "\""
    set eq_quote "=\""
    set td_inner "div"
    set td_outer "div"
    set sp " "
    set nl "\n"
    set tr "div"
    set lttr "<div"
    set div_c "</div>"

    set column_i 0
    foreach tdoa_list $td_div_outer_atts_lists {
        set td_outer_html $lt
        append td_outer_html $td_outer [qf_insert_attributes $tdoa_list]
        append $td_outer_html $gt
        set td_div_outer_tag_html_arr(${column_i}) $td_outer_html
        incr column_i
    }

    set table_html "<div"
    append table_html [qf_insert_attributes $table_atts_list]
    append table_html ${gt} ${nl}
    set row_i 0
    set column_i 0
    # Setup repeat pattern for formatting rows, 
    # if last formatting row is not blank.
    set repeat_last_row_p 0
    if { [llength [lindex $td_div_inner_atts_lists end] ] > 0 } {
        # This feature only comes into play
        # if td_div_inner_atts_lists is not as long as table_list_of_lists
        set repeat_last_row_p 1
        set repeat_row [llength $td_div_inner_atts_lists]
        incr repeat_row -1
    }

    set td_div_inner_tag ${th}
    set td_div_inner_tag_html ${lt}
    append td_div_inner_tag_html $td_div_inner_tag

    set th_tag_html ${lttr}
    append th_tag_html [qf_insert_attributes $th_div_atts_list]
    append th_tag_html ${gt} ${nl}

    set tr_even_tag_html ${lttr}
    append tr_even_tag_html [qf_insert_attributes $tr_div_even_atts_list]
    append tr_even_tag_html ${gt} ${nl}

    set tr_odd_tag_html ${lttr}
    append tr_odd_tag_html [qf_insert_attributes $tr_div_odd_atts_list]
    append tr_odd_tag_html ${gt} ${nl}

    append table_html "<div" [qf_insert_attributes $th_div_atts_list] ${gt}
    foreach row_list $table_list_of_lists {

        if { $row_i == $th_rows } {
            set td_div_inner_tag ${td_inner}
            set td_div_inner_tag_html ${lt}
            append td_div_inner_tag_html ${td_div_inner_tag}
            append table_html $div_c "<div title=\"\#acs-templating.Data\#\">"
        }

        set data_row_nbr [expr { ${row_i} - ${th_rows} + 1 } ]
        if { $data_row_nbr < 1 } {
            append table_html ${th_tag_html}
        } elseif { [qf_is_even $data_row_nbr ] } {
            append table_html ${tr_even_tag_html}
        } else {
            append table_html ${tr_odd_tag_html}
        }

        foreach cell_v $row_list {

            append table_html $td_div_outer_tag_html_arr(${column_i})   
            append table_html $td_div_inner_tag_html

            if { $repeat_last_row_p && $row_i > $repeat_row } {
                set attribute_value_list [lindex [lindex $td_div_inner_atts_lists $repeat_row] $column_i]

            } else {
                set attribute_value_list [lindex [lindex $td_div_inner_atts_lists $row_i] $column_i]
            }
            append table_html [qf_insert_attributes $attribute_value_list]
            append table_html ${gt} ${cell_v} ${lt} ${fs} ${td_div_inner_tag} ${gt}
            # close td_div_outer
            append table_html $div_c
            incr column_i
        }
        append table_html ${lt} ${fs} ${tr} ${gt} ${nl}
        incr row_i
        set column_i 0
    }
    append table_html $div_c $div_c $nl
    return $table_html
}
