create or replace package body ut_coverage is

  g_skipped_objects ut_object_names;

  function get_coverage_id return integer is
  begin
    return ut_coverage_helper.get_coverage_id;
  end;

  function coverage_start return integer is
  begin
    g_skipped_objects := ut_object_names();
    return ut_coverage_helper.coverage_start('utPLSQL Code coverage run '||ut_utils.to_string(systimestamp));
  end;

  procedure coverage_start is
    l_coverage_id integer;
  begin
    l_coverage_id := coverage_start;
  end;

  procedure coverage_start_develop is
  begin
    g_skipped_objects := ut_object_names();
    ut_coverage_helper.coverage_start_develop();
  end;

  procedure coverage_flush is
  begin
    ut_coverage_helper.coverage_flush();
  end;

  procedure coverage_pause is
  begin
    ut_coverage_helper.coverage_pause();
  end;

  procedure coverage_resume is
  begin
    ut_coverage_helper.coverage_resume();
  end;

  procedure coverage_stop is
  begin
    ut_coverage_helper.coverage_stop();
  end;

  procedure skip_coverage_for(a_object ut_object_name) is
  begin
    if g_skipped_objects is null then
      g_skipped_objects := ut_object_names();
    end if;
      g_skipped_objects.extend;
      g_skipped_objects(g_skipped_objects.last) := a_object;
  end;

  function get_coverage_data(a_schema_names ut_varchar2_list) return t_coverage is

    pragma autonomous_transaction;

    type t_coverage_row is record(
      name          varchar2(500),
      line_number   integer,
      total_occur   number(38,0)
    );
    type tt_coverage_rows is table of t_coverage_row;
    l_line_calls       ut_coverage_helper.unit_line_calls;
    l_result           t_coverage;
    l_new_unit         t_unit_coverage;
    l_skipped_objects  ut_object_names := ut_object_names();

    type t_source_lines is table of binary_integer;
    l_source_lines     t_source_lines;
    line_no            binary_integer;
    l_schema_names     ut_varchar2_list;
  begin

    l_schema_names := nvl(a_schema_names,ut_varchar2_list(sys_context('userenv','current_schema')));
    if not ut_coverage_helper.is_develop_mode() then
      l_skipped_objects := ut_utils.get_utplsql_objects_list() multiset union set(g_skipped_objects);
    end if;

    --prepare global temp table with sources
    delete from ut_coverage_sources_tmp;

    insert into ut_coverage_sources_tmp(owner,name,line,text)
    select s.owner,s.name,s.line,s.text
      from all_source s
     where s.type not in ('PACKAGE', 'TYPE')
       and s.owner in (select t.column_value from table(l_schema_names) t)
       --Exclude calls to utPLSQL framework and Unit Test packages
    --   and not exists(select 1 from table(l_skipped_objects) l where s.owner = l.owner AND s.name = l.name)
    ;

    for src_object in (
      select o.owner, o.object_name, o.object_type, lower(o.owner||'.'||o.object_name) full_name, c.lines_count
      from all_objects o
      join (select max(c.line) lines_count, c.owner, c.name
        from ut_coverage_sources_tmp c
        group by c.owner, c.name) c
        on o.owner = c.owner and o.object_name = c.name
      where o.object_type not in ('PACKAGE', 'TYPE')
      and o.owner in ( select t.column_value from table (l_schema_names) t)
        --Exclude calls to utPLSQL framework and Unit Test packages
      and not exists ( select 1 from table (l_skipped_objects) l where o.owner = l.owner and o.object_name = l.name)
    ) loop

      --get coverage data
      l_line_calls := ut_coverage_helper.get_raw_coverage_data( src_object.owner, src_object.object_name );

      --if there is coverage, we need to filter out the garbage (badly indicated data from dbms_profiler)
      if l_line_calls.count > 0 then
        --get source lines to skip
        select line
          bulk collect into l_source_lines
          from ut_coverage_sources_tmp c
         where c.owner = src_object.owner
           and c.name = src_object.object_name
           and regexp_instr(
                  c.text,
                  '^\s*(((not)?\s*(overriding|final|instantiable)\s*)*(constructor|member)?\s*(procedure|function)|package(\s+body)|begin|end(\s+\S+)?\s*;)', 1, 1, 0, 'i'
                ) != 0;
        --remove lines that should not be indicted as meaningful
        for i in 1 .. l_source_lines.count loop
          l_line_calls.delete(l_source_lines(i));
        end loop;
      end if;

      if not l_result.objects.exists(src_object.full_name) then
        l_result.objects(src_object.full_name) := l_new_unit;
      end if;
      l_result.total_lines := l_result.total_lines + src_object.lines_count;
      l_result.objects(src_object.full_name).total_lines := src_object.lines_count;
      --map to results
      line_no := l_line_calls.first;
      if line_no is null then
        l_result.uncovered_lines := l_result.uncovered_lines + src_object.lines_count;
        l_result.objects(src_object.full_name).uncovered_lines := src_object.lines_count;
      else
        loop
          exit when line_no is null;

          if l_line_calls(line_no) > 0 then
            l_result.covered_lines := l_result.covered_lines + 1;
            l_result.executions := l_result.executions + l_line_calls(line_no);
            l_result.objects(src_object.full_name).covered_lines := l_result.objects(src_object.full_name).covered_lines + 1;
            l_result.objects(src_object.full_name).executions := l_result.objects(src_object.full_name).executions + l_line_calls(line_no);
          elsif l_line_calls(line_no) = 0 then
            l_result.uncovered_lines := l_result.uncovered_lines + 1;
            l_result.objects(src_object.full_name).uncovered_lines := l_result.objects(src_object.full_name).uncovered_lines + 1;
          end if;
          l_result.objects(src_object.full_name).lines(line_no) := l_line_calls(line_no);

          line_no := l_line_calls.next(line_no);
        end loop;
      end if;


    end loop;

    commit;
    return l_result;
  end get_coverage_data;

  function get_schema_names_from_run(a_run ut_run) return ut_varchar2_list is
    type t_schema_names is table of boolean index by varchar2(500);
    l_schema_names t_schema_names;
    l_result ut_varchar2_list;

    l_schema_name varchar2(500);

    procedure get_suite_item_schema_names(a_suite_item ut_logical_suite, a_schema_names in out nocopy t_schema_names) is
    begin
      if a_suite_item is of (ut_suite) then
        a_schema_names(a_suite_item.object_owner) := true;
      elsif a_suite_item.items is not null then
        for i in 1 .. a_suite_item.items.count loop
          if a_suite_item is of (ut_logical_suite) then
            get_suite_item_schema_names(treat( a_suite_item.items(i) as ut_logical_suite), a_schema_names);
          end if;
        end loop;
      end if;
    end;

  begin
    if a_run is not null and a_run.items is not null then
      for i in 1 .. a_run.items.count loop
        if a_run.items(i) is of (ut_logical_suite) then
          get_suite_item_schema_names(treat( a_run.items(i) as ut_logical_suite), l_schema_names);
        end if;
      end loop;
    end if;
    if l_schema_names.count > 0 then
      l_result := ut_varchar2_list();
      l_schema_name := l_schema_names.first;
      loop
        exit when l_schema_name is null;
        l_result.extend;
        l_result(l_result.last) := l_schema_name;
        l_schema_name := l_schema_names.next(l_schema_name);
      end loop;
    end if;
    return l_result;
  end;
end;
/
