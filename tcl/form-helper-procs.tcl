ad_library {
    
    procedures for helping render form data or presentation for form data
    @creation-date 15 May 2012
    @cs-id $Id:

    to vertically align textarea label, add to css: 

    textarea { vertical-align: top; }
    # replace top with middle or other options to adjust alignment.
    # textarea's border is used for alignment, so alignment is affected by font-size and line-height ratio 
    # in addition to borders and margins.

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
    set bguessD $table_arr(0-bguessD)
    set bguess $table_arr(0-bguess)
    set rows_count $table_arr(0-rows)
    set delimiter $table_arr(0-delim)
    # bguessD is absolute value of bguess from variance
    for { set i 0 } { $i < $delimC } { incr i } {
        if { ( $table_arr(${i}-bguessD) <= $bguessD || $bguess < 2 ) && $table_arr(${i}-bguess) > 1 } {
            if { ( $bguess > 1 && $table_arr(${i}-bguess) < $bguess ) || $bguess < 2 } {
                set bguess $table_arr(${i}-bguess)
                set bguessD $table_arr(${i}-bguessD)
                set rows_count $table_arr(${i}-rows)
                set delimiter $table_arr(${i}-delim)
            }
        }
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

ad_proc -public qf_is_natural_number {
    value
} {
    answers question: is value a natural counting number (non-negative integer)?
    returns 0 or 1
} {
    set is_natural [regexp {^(0*)(([1-9][0-9]*|0))$} $value match zeros value]
    return $is_natural
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
#    set remaining_contents \[join $tag_contents_list " "\]
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
} {
    abbreviates a pretty title or phrase to first word, or to max_length characters if max_length is a number > 0
} {
    set suffix ".."
    set suffix_len [string length $suffix]

    if { [ad_var_type_check_number_p $max_length] && $max_length > 0 } {
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
        regsub -all -- { } $phrase {\&nbsp;} phrase
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
    # following regexp from acs-tcl/tcl/json-procs.tcl which references json.org, ietf.org, Thomas Maeder, Glue Software Engineering AG and Don Baccus
    
    # tokens consisting of a single character
    #variable singleCharTokens { "{" "}" ":" "\\[" "\\]" "," }
    #variable singleCharTokenRE "\[[join $singleCharTokens {}]\]"
    
    # quoted string tokens
    #variable escapableREs { "[\\\"\\\\/bfnrt]" "u[[:xdigit:]]{4}" }
    #variable escapedCharRE "\\\\(?:[join $escapableREs |])"
    #variable unescapedCharRE {[^\\\"]}
    #variable stringRE "\"(?:$escapedCharRE|$unescapedCharRE)*\""
    
    # (unquoted) words
    #variable wordTokens { "true" "false" "null" }
    #variable wordTokenRE [join $wordTokens "|"]
    
    # number tokens
    # negative lookahead (?!0)[[:digit:]]+ might be more elegant, but
    # would slow down tokenizing by a factor of up to 3!
    set positiveRE {[1-9][[:digit:]]+[.]?|[[:digit:]][.]?}
    set cardinalRE "-?(?:$positiveRE)?"
    set fractionRE {[.][[:digit:]]+}
    set exponentialRE {[eE][+-]?[[:digit:]]+}
    set numberRE "^${cardinalRE}(?:$fractionRE)?(?:$exponentialRE)?$"
    set type_decimal_p [regexp -- $numberRE $value]
    return $type_decimal_p
}

