PROMPT Loading file: "coverage.css"
set define off
declare
  c_file_name constant varchar2(250) := 'coverage.css';
  l_file_part varchar2(32757);
  l_file_clob clob;
begin
  dbms_lob.createtemporary(l_file_clob , true);
  l_file_part := q'{/* @group General */

body {
  font-family: Verdana, Helvetica, Arial, Sans-Serif;
  font-size: 12px;
  color: #4C4C4C;
  background-color: #F4F2ED;
  padding: 1em;
}

a:link {
  color: #191919;
}

a:visited {
  color: #191919;
}

pre, code {
  color: #000000;
  font-family: "Bitstream Vera Sans Mono","Monaco","Courier New",monospace;
  font-size: 95%;
  line-height: 1.3em;
  margin-top: 0;
  margin-bottom: 0;
  padding: 0;
  word-wrap: break-word;
}

h1, h2, h3, h4, h5, h6 {
  margin: 0em 0em 1em 0em;
  color: #666666;
}

h1 {
  display: block;
  font-size: 2em;
  letter-spacing: -1px;
}

h2 {
  margin-top: -1em;
}

fieldset {
  display: inline;
  border: 0px;
  padding: 0px;
  margin-right: 1em;
}

div.filters {
  margin-bottom: 1em;
}

.hidden {
  display: none;
}

/* @end */

/* @group Cross-References */

span.cross-ref-title {
  font-size: 140%;
}

span.cross-ref a {
  text-decoration: none;
}

span.cross-ref {
  background-color:#f3f7fa;
  border: 1px dashed #333;
  margin: 1em;
  padding: 0.5em;
  overflow: hidden;
}

a.crossref-toggle {
  text-decoration: none;
}

/* @end */

/* @group Report Table */

div.report_table_wrapper {
  min-width: 900px;
}

table.report {
  border-collapse: collapse;
  border: 1px solid #666666;
  width: 100%;
  margin-bottom: 1em;
}

table.report tr {
  line-height: 1.75em;
}

table.report th {
  background: #666666;
  color: #ffffff;
  text-align: right;
  text-transform: uppercase;
  font-size: .8em;
  font-weight: bold;
  padding: 0em .5em;
  border: 1px solid #666666;
}

table.report tfoot tr {
  background: #dddddd;
  font-weight: bold;
  padding: .5em;
  border: 1px solid #666666;
}

th.left_align, td.left_align {
  text-align: left !important;
}

th.right_align, td.right_align {
  text-align: right;
  padding-right: 2em !important;
}

table.report th.header:hover {
  cursor: pointer;
  text-decoration: underline;
}

table.report th.headerSortUp:after{
  content: "\25BC";
  margin-left: 1em;
}

table.report th.headerSortDown:after {
  content: "\25B2";
  margin-left: 1em;
}

table.report tr.summary_row {
  background: #cccccc;
  border: 1px solid #cccccc;
}

table.report tr.summary_row td {
  padding-left: .2em !important;
  color: #333333;
  font-weight: bold;
}

table.report td {
  padding: .2em .5em .2em .5em;
}

table.report td a {
  text-decoration: none;
}

table.report tbody tr:hover {
  background: #cccccc !important;
}

table.report tr.summary_row td {
  border-bottom: 1px solid #aaaaaa;
}

table.report tr {
  background-color: #eeeeee;
}

table.report tr.odd {
  background-color: #dddddd;
}

/* @end */

/* @group Percentage Graphs */

div.percent_graph_legend {
  width: 5.5em;
  float: left;
  margin: .5em 1em .5em 0em;
  height: 1em;
  line-height: 1em;
}

div.percent_graph {
  height: 1em;
  border: #333333 1px solid;
  empty-cells: show;
  padding: 0px;
  border-collapse: collapse;
  width: 100px !important;
  float: left;
  margin: .5em 1em .5em 0em;
}

div.percent_graph div {
  float: left;
  height: 1em;
  padding: 0px !important;
}

div.percent_graph div.covered {
  background: #649632;
}

div.percent_graph div.uncovered {
  background: #a92730;
}

div.percent_graph div.NA {
  background: #eaeaea;
}

/* @end */

/* @group Details page */

table.details {
  margin-top: 1em;
  border-collapse: collapse;
  width: 100%;
  border: 1px solid #666666;
}

table.details tr {
  line-height: 1.75em;
  }

table.details td {
  padding: .25em;
  }

table.details td a {
  display: inline-block;
  min-width: 3em;
}

span.inferred, span.inferred1, span.marked, span.marked1, span.uncovered, span.uncovered1 {
  display: block;
  padding: .25em;
}

tr.inferred td, span.inferred {
  background-color: #e0dedb;
}

tr.inferred1 td, span.inferred1 {
  background-color: #e0dedb;
}

tr.marked td, span.marked, span.marked1 {
  background-color: #bed2be;
}

tr.uncovered td, span.uncovered {
  background-color: #ce8b8c;
}

tr.uncovered1 td, span.uncovered1 {
  background-color: #ce8b8c;
}



div.key {
  border: 1px solid #666666;
  margin: 1em 0em;
}

/* @end */
}';
  dbms_lob.writeappend(l_file_clob, length(l_file_part), l_file_part);

  insert
    into ut_coverage_templates( file_name, file_content, is_static )
    values ( c_file_name, l_file_clob, 'Y' );
  commit;
end;
/
