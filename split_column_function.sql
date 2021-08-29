CREATE PROCEDURE `split_column`()
BEGIN
  DECLARE i INTEGER;
  SET i = 1;
  REPEAT
  INSERT INTO temp_table (job_id, route)
	SELECT job_id, split_string(routes, ',', i) as route
    FROM scirt_job
    WHERE split_string(routes, ',', i) IS NOT NULL;
    SET i = i + 1;
    UNTIL ROW_COUNT() = 0
  END REPEAT;
END