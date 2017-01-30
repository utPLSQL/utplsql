create or replace package ut_coverage_helper authid definer is

  function  get_coverage_id return integer;
  function  is_develop_mode return boolean;

  function  coverage_start(a_run_comment varchar2 := ut_utils.to_string(systimestamp) ) return binary_integer;
  procedure coverage_start(a_run_comment varchar2 := ut_utils.to_string(systimestamp) );

  /*
  * Start coverage in develop mode, where all internal calls to utPLSQL itself are also included
  */
  procedure coverage_start_develop(a_run_comment varchar2 := ut_utils.to_string(systimestamp) );

  procedure coverage_stop;

  procedure coverage_pause;

  procedure coverage_resume;

  procedure coverage_flush;

  function get_raw_coverage_data return ut_coverage_rows pipelined;

end;
/
