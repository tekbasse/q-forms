ad_library {

    routines for presenting tcl list of lists as a paginated html table
    @creation-date 14 May 2018
    @Copyright (c) 2018 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl.html
    @project home: http://github.com/tekbasse/q-forms
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com
}


ad_proc -public qfo_sp_table_g2 {
    -items_per_page
    -table_list_of_lists_varname
    -table_titles_list_varname
    {-base_url ""}
    {-item_count ""}
    {-list_length_limit ""}
    {-list_offset ""}
    {-nav_current_pos_html_varname "__qfsp_nav_current_pos_html"}
    {-nav_next_links_html_varname "__qfsp_nav_next_links_html"}
    {-nav_prev_links_html_varname "__qfsp_nav_prev_links_html"}
    {-p_varname "__qfsp_p"}
    {-page_num_p "0"}
    {-s_varname "__qfsp_s"}
    {-separator "&nbsp;"}
    {-sort_type_list ""}
    {-table_html_varname "__qfsp_table_html"}
    {-table_tag_attributes_list "style {background-color: #cec;}"}
    {-table_titles_w_links_list_varname "__qfsp_table_titles_w_links_list"}
    {-this_start_row "1"}
    {-title_sorted_div_html "<div style=\"width: .7em; text-align: center; border: 1px solid #999; background-color: #eef;\">"}
    {-title_unsorted_div_html "<div style=\"width: 1.6em; text-align: center; border: 1px solid #999; background-color: #eef; line-height: 90%;\">"}

} {
    Creates a user customizable sorted list from a list of lists by
    creating a one row header with html. <br>
    Outputs are:
    <br><br><pre>
    nav_prev_links_html_varname        These three variables hold components
    nav_current_pos_html_varname       of a nav bar.
    nav_next_links_html_varname

    table_list_of_lists_varname        This table gets sorted and re-ordered.
    table_titles_w_links_list_varname  This heading row includes html 
                                       for form-based UI for p and s parameters

    table_titles_list_varname          This heading row has columns
                                       re-organized same as table_list_of_lists
    </pre>
    <br><br>

    <br><br>

    To sort by timestamp, 
    use '-dictionary' sort type,
    and a consistent length format for the column values, 
    such as ISO-8601 format: "YYYY-MM-DD HH:MM:SS". See: http://wiki.tcl.tk/1277
    <br><br>
    Required parameters:
    <br><br>
    <code>items_per_page</code> - number of rows (items) per page
    <code>table_list_of_lists_varname</code> 
    - Variable holding a table defined as a list of lists, 
    where each list is a row containing values of columns from first to last.
    <code>table_titles_list_varname</code> 
    - Variable name containing a list of titles of the columns in 
    <code>table_list_of_lists</code>, in cooresponding order. 
    That is first in list is title of first column in table.
    <br><br>
    Optional parameters:
    <code>item_count</code> - number of rows (items) in the table.
    <code>this_start_row</code> 
    - start row (item sequence number) for this page. First row is 1 even though tcl usually uses 0.
    <code>base_url</code> - url for building page links
    <code>separator</code> 
    - html used between page numbers in pagination bar, defaults to '&nbsp;'
    <code>list_limit</code> - limits the list to this many items.
    <code>list_offset</code> 
    - offset the list to start at some point other than the first item.
    <code>page_num_p</code> 
    - Answers question: Use the page number in pagniation bar's display? 
    If not, the first value of the left-most (primary sort) column is used.
    <code>s_varname</code> 
    - 's' is a sort_order_list as defined by the code and passed via a form. 
    It's an 'a' delimited list of column indexes of table 
    to be sorted in reverse order, 
    so that primary sort is the first in the list. 
    Secondary sort is the second in the list and on.
    <code>p_varname</code>
    - 'p' is a change of the sort_order_list 
    to now make this index the primary sort index. See code for details.
    <code>sort_type_list</code> 
    - A list of types of sort to use for each column when using 
    <code>lsort -index &lt;column&gt; -ascii &lt;list_of_lists&gt;</code> 
    to sort a table by a specific column. 
    The default value for each column is "-ascii", per tcl's default. 
    When specifying sort_type_list, define a type to use for each column. 
    For example:
    \[list "-ascii" "-dictionary" "-ascii" "-ascii" "-real" \] for a table withfive columns.

} {
    upvar 1 $table_lists_of_lists_varname table_lists
    upvar 1 $table_titles_list_varname table_titles_list
    upvar 1 $nav_prev_links_html_varname nav_prev_links_html
    upvar 1 $nav_current_pos_html_varname nav_current_pos_html
    upvar 1 $nav_next_links_html_varname nav_next_links_html
    upvar 1 $table_html_varname table_html
    upvar 1 $s_varname s
    upvar 1 $p_varname p

    # adapting from:
    # hosting-farm/lib/resource-status-summary-1.tcl
    # This version requires the entire table to be loaded for processing.
    # TODO: make another version that uses pg's select limit and offset.. 
    # to scale well. Probably won't be able to use page_num_p ==0.

    # normalize page_num_p's value
    set page_num_p [qf_is_true $page_num_p]
    
    if { base_url eq "" } {
        set base_url [ad_conn url]
    }
    
    set page_html ""
    
    # General process flow:
    # 1. Get table as list_of_lists
    # 2. Sort unformatted columns by row values
    # 3. Pagination_bar -- calcs including list_limit and list_offset, build UI
    # 4. Sort UI -- build
    
    # ================================================
    # 1. Get table as list_of_lists
    # ================================================
    # don't process list_offset or list_limit here.
    
    if { ![qf_is_natural_number $this_start_row ] } {
        set this_start_row 1
    }
    if  { $item_count eq "" } {
        set item_count [llength $table_lists]
    }
    if { ![info exists s ] } {
        set s ""
    }
    if { ![info exists p ] } {
        set p ""
    }



    # ================================================
    # 2. Sort unformatted columns by row values
    # ================================================
    # Sort Table Columns
    # arguments
    #     s            sort_order_list (via form post)
    #     p            primary_sort_col_new (via form post)
    #     table_lists  table represented as a list of lists
    # ================================================

    set table_cols_count [llength [lindex $table_lists 0]]
    set table_index_last [expr { $table_cols_count - 1 } ]

    # defaults and inputs
    if { $sort_type_list eq "" } {
        set sort_type_list [lrepeat $table_cols_count "-ascii"]
    }

    set sort_stack_list [list ]
    for {set i 0} { $i < $table_cols_count } { incr i } {
        lappend sort_stack_list $i
    }

    set sort_order_list [list ]
    set sort_rev_order_list [list ]
    set table_sorted_lists $table_lists

    # Sort table?
    if { $s ne "" } {
        # Sort table
        # A sort order has been requested
        # $s is in the form of a string of integers delimited by the letter a. 
        # Each integer is a column number ie list index, 
        # where 0 is first column.
        # A positive integer sorts column increasing.
        # A negative integer sorts column decreasing.
        # Primary sort column is listed first, followed by secondary sort etc.

        # Validate sort order, because it is user input via web
        # $s' first check and change to sort_order_scalar
        regsub -all -- {[^\-0-9a]} $s {} sort_order_scalar
        # ns_log Notice "qfsp_listcl(73): sort_order_scalar $sort_order_scalar"
        # Converting sort_order_scalar to a list
        set sort_order_list [split $sort_order_scalar a]
        set sort_order_list [lrange $sort_order_list 0 $table_index_last]
    }

    # Has a sort order change been requested?
    if { $p ne "" } {
        # A new primary sort requested
        # This is a similar reference to s, but only one integer.
        # Since this is the first time used as a primary, 
        # additional validation and processing is required.
        # Validate user input, fail silently

        regsub -all -- {[^\-0-9]+} $p {} primary_sort_col_new
        # primary_sort_col_pos = primary sort column's position
        # primary_sort_col_new = a negative or positive column position. 
        set primary_sort_col_pos [expr { abs( $primary_sort_col_new ) } ]
        if { $primary_sort_col_new ne "" && $primary_sort_col_pos < $table_cols_count } {
            # modify sort_order_list
            set sort_order_new_list [list $primary_sort_col_new]
            foreach ii $sort_order_list {
                if { [expr { abs( ${ii} ) } ] ne $primary_sort_col_pos } {
                    lappend sort_order_new_list $ii
                }
            }
            set sort_order_list $sort_order_new_list
        }
    }

    if { ( $s ne "" ) || ( $p ne "" ) } {
        # Create a reverse index list for index countdown, 
        # because primary sort is last, secondary sort is second to last..
        # sort_stack_list 0 1 2 3..
        set sort_rev_order_list [lsort -integer -decreasing [lrange $sort_stack_list 0 [expr { [llength $sort_order_list] - 1 } ] ] ]
        # sort_rev_order_list ..3 2 1 0
        foreach ii $sort_rev_order_list {
            set col2sort [lindex $sort_order_list $ii]
            if { [string range $col2sort 0 0] eq "-" } {
                set col2sort_wo_sign [string range $col2sort 1 end]
                set sort_order "-decreasing"
            } else { 
                set col2sort_wo_sign $col2sort
                set sort_order "-increasing"
            }
            set sort_type [lindex $sort_type_list $col2sort_wo_sign]

            if {[catch { set table_sorted_lists [lsort $sort_type -dictionary $sort_order -index $col2sort_wo_sign $table_sorted_lists] } result] } {
                # lsort errored, probably due to bad sort_type. 
                # Fall back to -ascii sort_type, or fail..
                set table_sorted_lists [lsort -dictionary $sort_order -index $col2sort_wo_sign $table_sorted_lists]
                ns_log Notice "qfsp_listcl(121): lsort resorted to sort_type \
 -ascii for index '${col2sort_wo_sign}' due to error: '${result}'"
            }
        }
    }

    # ================================================
    # 3. Pagination_bar -- 
    #    calcs including list_limit and list_offset, build UI
    # ================================================
    # if $s exists, add it to to pagination urls.

    # constants
    set page_num_prefix "#acs-templating.Page# "
    set a_href_h "<a href=\""
    set amp_s_h "&amp;s="
    set amp_p_h "&amp;p="
    set amp_h "&amp;"
    set eq_h "="
    set da_h "-"
    set qm_h "?"
    set q_s_h "?s="
    set sp " "
    set class_att_h "\" class=\""
    set title_att_h "\" title=\""
    set this_start_row_h "this_start_row="
    set dquote_end_h "\">"
    set a_end_h "</a>"
    set span_end_h "</span>"
    set sortedlast "sortedlast"
    set sortedfirst "sortedfirst"
    set unsorted "unsorted"
    set span_h "<span "
    set colon ":"
    set div_end_h "</div>"
    # Add the sort links to the titles.
    # urlcode sort_order_list
    set s_urlcoded ""
    foreach sort_i $sort_order_list {
        append s_urlcoded $sort_i
        append s_urlcoded a
    }
    set s_urlcoded [string range $s_urlcoded 0 end-1]
    set s_url_add $amp_s_h
    append s_url_add ${s_urlcoded}

    # Sanity check 
    if { $this_start_row > $item_count } {
        set this_start_row $item_count
    }

    set bar_list_set [hf_pagination_by_items $item_count $items_per_page $this_start_row]
    set prev_bar_list [list]
    set next_bar_list [list]

    set prev_bar_list [lindex $bar_list_set 0]
    foreach {page_num start_row} $prev_bar_list {
        if { $page_num_p } {
            set page_ref $page_num
        } else {
            set item_index [expr { ( $start_row - 1 ) } ]
            set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
            set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val] 10]
            if { $page_ref eq "" } {
                set page_ref $page_num_prefix
                append page_ref ${page_num}
            }
        }
        set this_start_row_link ${a_href_h}
        append this_start_row_link ${base_url} $qm_h $this_start_row_h ${start_row}
        append this_start_row_link ${s_url_add} $dquote_end_h ${page_ref} $a_end_h
        lappend prev_bar_list $this_start_row_link
    } 
    set nav_prev_links_html [join $prev_bar_list $separator]

    set current_bar_list [lindex $bar_list_set 1]
    set page_num [lindex $current_bar_list 0]
    set start_row [lindex $current_bar_list 1]
    if { $s eq "" } {
        set page_ref $page_num
    } else {
        set item_index [expr { ( $start_row - 1 ) } ]
        set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
        set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val] 10]
        if { $page_ref eq "" } {
            set page_ref $page_num_prefix
            append page_ref ${page_num}
        }
    }

    set nav_current_pos_html $page_ref

    set next_bar_list [lindex $bar_list_set 2]
    foreach {page_num start_row} $next_bar_list {
        if { $s eq "" } {
            set page_ref $page_num
        } else {
            set item_index [expr { ( $page_num - 1 ) * $items_per_page  } ]
            set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
            set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val] 10]
            if { $page_ref eq "" } {
                set page_ref $page_num_prefix
                append page_ref ${page_num}
            }
        }
        set next_bar_link ${sp}
        append next_bar_link ${a_href_h}
        append next_bar_link ${base_url} ${qm_h} ${this_start_row_h} ${start_row}
        append next_bar_link ${s_url_add} ${dquote_end_h} ${page_ref} ${a_end_h} ${sp}
        lappend next_bar_list $next_bar_link
    }
    set nav_next_links_html [join $next_bar_list $separator]


    # add start_row to sort_urls.
    if { $this_start_row_exists_p } {
        set page_url_add ${amp_h}
        append page_url ${this_start_row_h}
        append page_url_add ${this_start_row}
    } else {
        set page_url_add ""
    }

    # ================================================
    # 4. Sort UI -- build
    # ================================================
    # Sort's abbreviated title should be context sensitive, 
    # changing depending on sort type.
    # sort_type_list is indexed by sort_column nbr (0...)
    # for UX, chagnged "ascending order" to "A first" or "1 First", 
    # and "Descending order" to "Z first" or "9 first".

    set text_asc "A"
    set text_desc "Z"
    set nbr_asc "1"
    set nbr_desc "9"
    # increasing
    set title_asc "#acs-templating.ascending_order#"
    set title_asc_by_nbr "'${nbr_asc}' #acs-kernel.common_first#"
    set title_asc_by_text "'${text_asc}' #acs-kernel.common_first#"
    # decreasing
    set title_desc "#acs-templating.descending_order#"
    set title_desc_by_nbr "'${nbr_desc}' #acs-kernel.common_first#"
    set title_desc_by_text "'${text_desc}' #acs-kernel.common_first#"

    set table_titles_w_links_list [list ]
    set column_count 0
    set primary_sort_col [lindex $sort_order_list $column_count]

    # column_sort_decreases_list tells which columns are
    # sorted in decreasing order.
    set column_sort_decreases_list [list ]
    set column_sorted_list [list ]
    for {set i 0} {$i < $table_cols_count} {incr i} {
        lappend column_sort_decreases_list 0
        lappend column_sorted_list 0
    }
    foreach sort_i $sort_order_list {
        if { [string range $sort_i 0 0] eq "-" } {
            set col_sort_i [string range $sort_i 1 end]
            set decreasing_p 1
        } else {
            set col_sort_i $sort_i
            set decreasing_p 0
        }
        if { $decreasing_p } {
            set column_sort_decreases_list [lreplace $column_sort_decreases_list $col_sort_i $col_sort_i $decreasing_p]
        }
        set column_sorted_list [lreplace $column_sorted_list $col_sort_i $col_sort_i 1]
    }

    foreach title $table_titles_list {
        # Figure out column data type for sort button (text or nbr).
        # The column order is not changed yet.
        set column_type [string range [lindex $sort_type_list $column_count] 1 end]
        if { $column_type eq "integer" || $column_type eq "real" } {
            set abbrev_asc $nbr_asc
            set abbrev_desc $nbr_desc
            set title_asc $title_asc_by_nbr
            set title_desc $title_desc_by_nbr
        } else {
            set abbrev_asc $text_asc
            set abbrev_desc $text_desc
            set title_asc $title_asc_by_text
            set title_desc $title_desc_by_text
        }

        # Is column sort decreasing? 
        # If so, let's reverse the order of column's sort links.
        set decreasing_p [lindex $column_sort_decreases_list $column_count]
        set column_sorted_p [lindex $column_sorted_list $column_count]
        set sort_link_delim ""
        # Sort button should be active if an available choice, 
        # and inactive if already chosen (primary sort case).
        # Sorted columns should reflect existing sort case, 
        # so if column is sorted descending integer, then '9:1' not '1:9'.
        # Sorted columnns should be aligned vertically,
        # to reflect column value orientation.

        # For now, just inactivate the left most sort link 
        # that was most recently pressed (if it has been).
        set title_new $title

        if { $primary_sort_col eq "" \
                 || ( $primary_sort_col ne "" \
                          && $column_count ne [expr { abs( $primary_sort_col ) } ] ) } {
            if { $column_sorted_p } {
                if { $decreasing_p } {
                    # reverse class styles
                    set sort_top ${a_href_h}
                    append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_top ${amp_p_h} ${column_count} ${page_url_add}
                    append sort_top ${title_att_h} ${title_asc}
                    append sort_top ${class_att_h} ${sortedlast} ${dquote_end_h}
                    append sort_top ${abbrev_asc} ${a_end_h}
                    set sort_bottom ${a_href_h}
                    append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_bottom ${amp_p_h} ${da} ${column_count} ${page_url_add}
                    append sort_bottom ${title_att_h} ${title_desc}
                    append sort_bottom ${class_att_h} ${sortedfirst} ${dquote_end_h}
                    append sort_bottom ${abbrev_desc} ${a_end_h}
                } else {
                    set sort_top ${a_href_h} ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_top ${amp_p_h} ${column_count} ${page_url_add}
                    append sort_top ${title_att_h} ${title_asc}
                    append sort_top ${class_att_h} ${sortedfirst} ${dquote_end_h}
                    append sort_top ${abbrev_asc} ${a_end_h}
                    set sort_bottom ${a_href_h} ${base_url} ${q_s_h} ${s_urlcoded}
                    append sort_bottom ${amp_p_h} ${da} ${column_count} ${page_url_add}
                    append sort_bottom ${title_att_h} ${title_desc}
                    append sort_bottom ${class_att_h} ${sortedlast} ${dquote_end_h}
                    append sort_bottom ${abbrev_desc} ${a_end_h}
                }
            } else {
                # Not sorted, so don't align sort order vertically.. 
                # Just use normal horizontal alignment.
                set sort_top ${a_href_h}
                append sort_top ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_top ${amp_p_h} ${column_count} ${page_url_add}
                append sort_top ${title_att_h} ${title_asc}
                append sort_top ${class_att_h} ${unsorted} ${dquote_end_h}
                set sort_bottom ${a_href_h} 
                append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_bottom ${amp_p_h} ${da} ${column_count} ${page_url_add}
                append sort_bottom ${title_att_h} ${title_desc}
                append sort_bottom ${class_att_h} ${unsorted} ${dquote_end_h}
                append sort_bottom ${abbrev_desc} ${a_end_h}
                set sort_link_delim ${colon}
            }
        } else {
            if { $decreasing_p } {
                # Decreasing primary sort is chosen last, 
                # no need to make the link active
                set sort_top ${a_href_h}
                append sort_top ${base_url} ${q_s_h} ${s_urlcoded} 
                append sort_top ${amp_p_h} ${column_count} ${page_url_add}
                append sort_top ${title_att_h} ${title_asc}
                append sort_top ${class_att_h} ${sortedlast} ${dquote_end_h}
                append sort_top ${abbrev_asc} ${a_end_h}
                set sort_bottom ${span_h} ${class_att_h} ${sortedfirst} ${dquote_end_h}
                append sort_bottom ${abbrev_desc} ${span_end_h}
            } else {
                # Increasing primary sort is chosen last, 
                # no need to make the link active
                set sort_top ${span_h} ${class_att_h} ${sortedfirst} ${dquote_end_h}
                append sort_top ${abbrev_asc} ${span_end_h}
                set sort_bottom ${a_href_h}
                append sort_bottom ${base_url} ${q_s_h} ${s_urlcoded}
                append sort_bottom ${amp_p_h} ${da} ${column_count} ${page_url_add}
                append sort_bottom ${title_att_h} ${title_desc}
                append sort_bottom ${class_att_h} ${sortedlast} ${dquote_end_h}
                append sort_bottom ${abbrev_desc} ${a_end_h}
            }
        }
        set end_div ""
        if { $column_sorted_p } {
            append title_new $title_sorted_div_html
            if { $title_sorted_div_html ne "" } {
                set end_div ${div_end_h}
            }
        } else {
            append title_new $title_unsorted_div_html
            if { $title_unsorted_div_html ne "" } {
                set end_div ${div_end_h}
            }
        }
        if { $decreasing_p } {
            append title_new ${sort_bottom} ${sort_link_delim} ${sort_top}
        } else {
            append title_new ${sort_top} ${sort_link_delim} ${sort_bottom}
        }
        
        append title_new $end_div
        lappend table_titles_w_links_list $title_new
        incr column_count
    }
    #set table_titles_list $table_titles_w_links_list

    # Begin building the paginated table here. Table rows have been sorted.

    set table_paged_sorted_lists [list ]
    set lindex_start [expr { $this_start_row - 1 } ]
    set lindex_last [expr { $item_count - 1 } ]
    set last_row [expr { $lindex_start + $items_per_page - 1 } ]
    if { $lindex_last < $last_row } {
        set last_row $lindex_last
    }
    for { set row_num $lindex_start } { $row_num <= $last_row } {incr row_num} {
        lappend table_paged_sorted_lists [lindex $table_sorted_lists $row_num]
    }
    set table_sorted_lists $table_paged_sorted_lists

    # Result: table_sorted_lists
    # Number of sorted columns:
    set sort_cols_count [llength $sort_order_list]

    # ================================================
    # Display customizations


    # To remove a column from display:
    # 1. Blank the column reference from sort_stack_list (and sort_rev_order_list if it were used..)
    #    where  sort_stack_list is a sequential list: 0 1 2 3..
    #    so, removal of '1' becomes 0 "" 2 3..
    #    Don't remove the reference, or later column tracking for unsorted removals will break.
    # 2. Reduce table_cols_count by number of columns removed



    # ================================================
    # Change the order of columns
    # ================================================
    # so that the primary sort col is left, secondary is 2nd from left etc.

    # parameters: table_sorted_lists
    set table_col_sorted_lists [list ]

    # Rebuild the table, one row at a time, 
    # Add the primary sorted column, then secondary sorted columns in order
    foreach table_row_list $table_sorted_lists {
        set table_row_new [list ]

        # Track the columns that aren't sorted
        set unsorted_list $sort_stack_list
        foreach ii $sort_order_list {
            set ii_pos [expr { abs( $ii ) } ]
            lappend table_row_new [lindex $table_row_list $ii_pos]
            # Blank the reference instead of removing it, 
            # or the $ii reference won't work. lsearch is slower
            set unsorted_list [lreplace $unsorted_list $ii_pos $ii_pos ""]
        }

        # Now that the sorted columns are added to the row, 
        # add the remaining columns
        foreach ui $unsorted_list {
            if { $ui ne "" } {
                # Add unsorted column to row
                lappend table_row_new [lindex $table_row_list $ui]
            }
        }

        # Confirm that all columns have been accounted for.
        set table_row_new_cols [llength $table_row_new]
        if { $table_row_new_cols != $table_cols_count } {
            ns_log Notice "qfsp_listcl(203): Warning: table_row_new has ${table_row_new_cols} instead of ${table_cols_count} columns."
        }
        # Append new row to new table
        lappend table_col_sorted_lists $table_row_new
    }

    # ================================================
    # Add UI Options column to table?
    # Not at this time. Keep here in case a variant needs the code at some point.
    ##code The above code needs a way to designate columns to not sort
    # static (vs sortable) columns should by their nature and UI,
    # be on the opposite side of the sorted cases. 
    # So, have api include a list,
    # and convert that list to a logic array, static_col_p_arr().


    # ================================================
    # 5. Format output 
    # Add attributes to the TABLE tag
    set table_tag_attributes_list 

    # Add cell formatting to TD tags
    set cell_formating_list [list ]

    # Let's try to get fancy, have the rows alternate color after the first row, 
    # and have the sorted columns slightly lighter in color to highlight them
    # base alternating row colors:
    set color_even_row "evenrow"
    set color_odd_row "oddrow"
    # sorted column colors
    set color_even_scol "evenlight"
    set color_odd_scol "oddlight"

    # Set the default title row and column TD formats before columns sorted:
    set title_td_attrs_list [list ]
    set column_nbr 0
    foreach title $table_titles_w_links_list {
        set column_type [string range [lindex $sort_type_list $column_nbr] 1 end]
        # Title row TD formats in title_td_attrs_list
        # even row TD attributes in even_row_list
        # odd row TD attributes in odd_row_list
        if { $column_type eq "integer" ||$column_type eq "real" } {
            lappend title_td_attrs_list [list class "rightj border1"]
            # Value is a number, so right justify
            lappend even_row_list [list class "rightj smallest border1"]
            lappend odd_row_list [list class "rightj smallest border1"]
        } else {
            lappend title_td_attrs_list [list class "border1"]
            lappend even_row_list [list class "smallest border1"]
            lappend odd_row_list [list class "smallest border1"]
        }
        incr column_nbr
    }
    set cell_table_lists [list $title_td_attrs_list $odd_row_list $even_row_list]

    # Rebuild the even/odd rows adding the colors
    # When column order changes, 
    # then formatting of the TD tags may change, too.
    # So, re-order the formatting columns, 
    # insert the appropriate color at each cell.
    # Use the same looping logic from when the table columns changed order
    # to avoid inconsistencies
    ##code  This looping should be integrated into the first loop.

    # Rebuild the cell format table, one row at a time, 
    # add the primary sort column, secondary sort column etc. columns in order
    set row_count 0
    set cell_table_sorted_lists [list ]
    foreach td_row_list $cell_table_lists {
        set td_row_new [list ]
        # Track the rows that aren't sorted
        set unsorted_list $sort_stack_list
        foreach ii $sort_order_list {
            set ii_pos [expr { abs( $ii ) } ]
            set cell_format_list [lindex $td_row_list $ii_pos]
            if { $row_count > 0 } {
                # add the appropriate background color
                if { [f::even_p $row_count] } {
                    set color $color_even_scol
                } else {
                    set color $color_odd_scol
                }
                set class_pos [lsearch -exact $cell_format_list "class"]
                if { $class_pos > -1 } {
                    # Combine the class values 
                    # instead of appending more attributes
                    incr class_pos
                    set attr_value [lindex $cell_format_list $class_pos]
                    set new_attr_value $attr_value
                    append new_attr_value " $color"
                    set cell_format_list [lreplace $cell_format_list $class_pos $class_pos $new_attr_value]
                } else {
                    lappend cell_format_list class $color
                }      
            }
            lappend td_row_new $cell_format_list
            # Blank the reference instead of removing it, 
            # or the $ii_pos reference won't work. lsearch is slower
            set unsorted_list [lreplace $unsorted_list $ii_pos $ii_pos ""]
        }
        # Now that the sorted columns are added to the row, 
        # add the remaining columns
        foreach ui $unsorted_list {
            if { $ui ne "" } {
                set cell_format_list [lindex $td_row_list $ui]
                if { $row_count > 0 } {
                    # add the appropriate background color
                    if { [f::even_p $row_count] } {
                        set color $color_even_row
                    } else {
                        set color $color_odd_row
                    }
                    set class_pos [lsearch -exact $cell_format_list "class"]
                    if { $class_pos > -1 } {
                        # combine the class values instead of appending more attributes
                        incr class_pos
                        set attr_value [lindex $cell_format_list $class_pos]
                        set new_attr_value $attr_value
                        append new_attr_value " $color"
                        set cell_format_list [lreplace $cell_format_list $class_pos $class_pos $new_attr_value]
                    } else {
                        lappend cell_format_list class $color
                    }
                }
                # Add unsorted column to row
                lappend td_row_new $cell_format_list
            }
        }
        # Append new row to new table
        lappend cell_table_sorted_lists $td_row_new
        incr row_count
    }

    set table_row_count [llength $table2_lists]
    set row_odd_format [lindex $cell_table_sorted_lists 1]
    set row_even_format [lindex $cell_table_sorted_lists 2]
    if { $table_row_count > 3 } { 
        # Repeat the odd/even rows for the length of the table (table2_lists)
        for {set row_i 3} {$row_i < $table_row_count} { incr row_i } {
            if { [f::even_p $row_i ] } {
                lappend cell_table_sorted_lists $row_even_format
            } else {
                lappend cell_table_sorted_lists $row_odd_format
            }
        }

    }
    # ================================================


    # this builds the html table and assigns it to table_html
    set table_html [qss_list_of_lists_to_html_table $table2_lists $table_tag_attributes_list $cell_table_sorted_lists]

    return 1
}

ad_proc -private hf_pagination_by_items {
    item_count
    items_per_page
    first_item_displayed
} {
    Returns a list of 3 pagination components.
    The first is a list of page_number and start_row pairs for pages before the current page.
    The second contains page_number and start_row for the current page.
    Third is the same value pair for pages after the current page.  
    See hosting-farm/lib/paginiation-bar for an implementation example. 
} {
    # based on ecds_pagination_by_items
    if { $items_per_page > 0 && $item_count > 0 && $first_item_displayed > 0 && $first_item_displayed <= $item_count } {
        set bar_list [list]
        set end_page [expr { ( $item_count + $items_per_page - 1 ) / $items_per_page } ]

        set current_page [expr { ( $first_item_displayed + $items_per_page - 1 ) / $items_per_page } ]

        # first row of current page is { (( $current_page - 1)  * $items_per_page ) + 1 }

        # create bar_list with no pages beyond end_page

        if { $item_count > [expr { $items_per_page * 81 } ] } {
            # use exponential page referencing
            set relative_step 0
            set next_bar_list [list]
            set prev_bar_list [list]
            # 0.69314718056 = log(2)  
            set max_search_points [expr { int( ( log( $end_page ) / 0.69314718056 ) + 1 ) } ]
            for {set exponent 0} { $exponent <= $max_search_points } { incr exponent 1 } {
                # exponent refers to a page, relative_step refers to a relative row
                set relative_step_row [expr { int( pow( 2, $exponent ) ) } ]
                set relative_step_page $relative_step_row
                lappend next_bar_list $relative_step_page
                set prev_bar_list [linsert $prev_bar_list 0 [expr { -1 * $relative_step_page } ]]
            }

            # template_bar_list and relative_bar_list contain page numbers
            set template_bar_list [concat $prev_bar_list 0 $next_bar_list]
            set relative_bar_list [lsort -unique -increasing -integer $template_bar_list]
            
            # translalte bar_list relative values to absolute rows
            foreach {relative_page} $relative_bar_list {
                set new_page [expr { int ( $relative_page + $current_page ) } ]
                if { $new_page < $end_page } {
                    lappend bar_list $new_page 
                }
            }

        } elseif {  $item_count > [expr { $items_per_page * 10 } ] } {
            # use linear, stepped page referencing

            set next_bar_list [list 1 2 3 4 5]
            set prev_bar_list [list -5 -4 -3 -2 -1]
            set template_bar_list [concat $prev_bar_list 0 $next_bar_list]
            set relative_bar_list [lsort -unique -increasing -integer $template_bar_list]
            # translalte bar_list relative values to absolute rows
            foreach {relative_page} $relative_bar_list {
                set new_page [expr { int ( $relative_page + $current_page ) } ]
                if { $new_page < $end_page } {
                    lappend bar_list $new_page 
                }
            }
            # add absolute page references
            for {set page_number 10} { $page_number <= $end_page } { incr page_number 10 } {
                lappend bar_list $page_number
                set bar_list [linsert $bar_list 0 [expr { -1 * $page_number } ] ]
            }

        } else {
            # use complete page reference list
            for {set page_number 1} { $page_number <= $end_page } { incr page_number 1 } {
                lappend bar_list $page_number
            }
        }

        # add absolute reference for first page, last page
        lappend bar_list $end_page
        set bar_list [linsert $bar_list 0 1]

        # clean up list
        # now we need to sort and remove any remaining nonpositive integers and duplicates
        set filtered_bar_list [lsort -unique -increasing -integer [lsearch -all -glob -inline $bar_list {[0-9]*} ]]
        # delete any cases of page zero
        set zero_index [lsearch $filtered_bar_list 0]
        set bar_list [lreplace $filtered_bar_list $zero_index $zero_index]

        # generate list of lists for code in ecommerce/lib
        set prev_bar_list_pair [list]
        set current_bar_list_pair [list]
        set next_bar_list_pair [list]
        foreach page $bar_list {
            set start_item [expr { ( ( $page - 1 ) * $items_per_page ) + 1 } ]
            if { $page < $current_page } {
                lappend prev_bar_list_pair $page $start_item
            } elseif { $page eq $current_page } {
                lappend current_bar_list_pair $page $start_item
            } elseif { $page > $current_page } {
                lappend next_bar_list_pair $page $start_item
            }
        }
        set bar_list_set [list $prev_bar_list_pair $current_bar_list_pair $next_bar_list_pair]
    } else {
        ns_log Warning "hf_pagination_by_items: parameter value(s) out of bounds for $item_count $items_per_page $first_item_displayed"
    }

    return $bar_list_set
}

