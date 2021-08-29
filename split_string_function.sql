CREATE FUNCTION `split_string`(x VARCHAR(16383), delim VARCHAR(12), pos INTEGER) RETURNS varchar(16383) CHARSET utf8mb4
BEGIN
  DECLARE output VARCHAR(16383);
  SET output = REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos), LENGTH(SUBSTRING_INDEX(x, delim, pos - 1)) + 1), delim, '');
  IF output = '' THEN SET output = null; END IF;
  RETURN trim(output);
END