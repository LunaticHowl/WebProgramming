/*
Get metadata from ad-hoc query

This is huge!
Only available in sql server 2012
  http://lennilobel.wordpress.com/2012/05/29/new-metadata-discovery-features-in-sql-server-2012/

Uses sp_describe_first_result_set and sys.dm_exec_describe_first_result_set to get meta data from sql server for ad-hoc queries.
** note: ** if you have a left join then each field involved in that left join will have "is_nullable" = True

The test query is:
  select
    namelastname as last,
    namefirstname as first,
    NameBirthday AS PartyTime,
    PhonAreaCode as Area,
    PhonPhoneNumber as Number,
    cast(PhonAreaCode as varchar(5)) + '-' + PhonPhoneNumber AS FullNumber
  from names as N
  join PhoneNumbers as PN on N.NameNameID = PN.PhonNameID

notice how every field and table are aliased and there is a calculated column

sp_describe_first_result_set and sys.dm_exec_describe_first_result_set both work.
The examples below use sys.dm_exec_describe_first_result_set
sys.dm_exec_describe_first_result_set allow returning just a sub-set of the meta data columns
The syntax for sp_describe_first_result_set is:
  sp_describe_first_result_set N'...', NULL, 1

  name
  is_nullable
  source_table
  source_column
  is_identity_column
  is_part_of_unique_key
  is_updateable
  is_computed_column

example:
  SELECT
    name,
    is_nullable,
    source_table,
    source_column,
    is_identity_column,
    is_part_of_unique_key,
    is_updateable,
    is_computed_column
  FROM sys.dm_exec_describe_first_result_set('select namelastname as last, namefirstname as first, NameBirthday AS PartyTime, PhonAreaCode as Area, PhonPhoneNumber as Number, cast(PhonAreaCode as varchar(5)) + ''-'' + PhonPhoneNumber AS FullNumber from names as N join PhoneNumbers as PN on N.NameNameID = PN.PhonNameID', NULL, 1)

returns:

  name         is_nullable source_table  source_column    is_identity_column is_part_of_unique_key is_updateable is_computed_column
  ------------ ----------- ------------- ---------------- ------------------ --------------------- ------------- ------------------
  last         0           Names         NameLastName     0                  0                     1             0
  first        0           Names         NameFirstName    0                  0                     1             0
  PartyTime    1           Names         NameBirthday     0                  0                     1             0
  Area         0           PhoneNumbers  PhonAreaCode     0                  0                     1             0
  Number       0           PhoneNumbers  PhonPhoneNumber  0                  0                     1             0
  FullNumber   1           NULL          NULL             0                  0                     0             1
  NameNameID   0           Names         NameNameID       1                  1                     0             0
  PhonPhoneID  0           PhoneNumbers  PhonPhoneID      1                  1                     0             0

will also return primary key data even if not specified in the query if you pass true (1) as last param ie:
  SELECT
    name,
    is_nullable,
    source_table,
    source_column,
    is_identity_column,
    is_part_of_unique_key,
    is_updateable,
    is_computed_column
  FROM sys.dm_exec_describe_first_result_set('select PMRdEndDate from PremiseMeterReadings', NULL, 1)

returns:
  name               is_nullable source_table          source_column      is_identity_column is_part_of_unique_key is_updateable is_computed_column
  ------------------ ----------- --------------------- ------------------ ------------------ --------------------- ------------- ------------------
  PMRdEndDate        1           PremiseMeterReadings  PMRdEndDate        0                  0                     1             0
  PMRdPremiseID      0           PremiseMeterReadings  PMRdPremiseID      0                  1                     1             0
  PMRdTenantCounter  0           PremiseMeterReadings  PMRdTenantCounter  0                  1                     1             0
  PMRdMeterID        0           PremiseMeterReadings  PMRdMeterID        0                  1                     1             0
  PMRdBillPeriod     0           PremiseMeterReadings  PMRdBillPeriod     0                  1                     1             0
  PMRdBillGroup      0           PremiseMeterReadings  PMRdBillGroup      0                  1                     1             0
  PMRdReadingNbr     0           PremiseMeterReadings  PMRdReadingNbr     0                  1                     1             0

Notice how all 6 fields that make up the primary key are include in the result set even though they were not in the query

Also works with views and joins to views
assume the view and query:
  create view delthis
  AS
    select
      PhonNameID as keyfld,
      PhonAreaCode as Area,
      PhonPhoneNumber as Number,
      cast(PhonAreaCode as varchar(5)) + '-' + PhonPhoneNumber AS FullNumber
    from PhoneNumbers

  select
    namelastname as last,
    namefirstname as first,
    NameBirthday AS PartyTime,
    Area,
    Number,
    FullNumber
  from names as N
  join delthis as PN on N.NameNameID = PN.keyfld

This call to sys.dm_exec_describe_first_result_set()
  SELECT
    name,
    is_nullable,
    source_table,
    source_column,
    is_identity_column,
    is_part_of_unique_key,
    is_updateable,
    is_computed_column
  FROM sys.dm_exec_describe_first_result_set('select namelastname as last, namefirstname as first, NameBirthday AS PartyTime, Area, Number, FullNumber from names as N join delthis as PN on N.NameNameID = PN.keyfld', NULL, 1)

returns:
  name         is_nullable source_table  source_column    is_identity_column is_part_of_unique_key is_updateable is_computed_column
  ------------ ----------- ------------- ---------------- ------------------ --------------------- ------------- ------------------
  last         0           Names         NameLastName     0                  0                     1             0
  first        0           Names         NameFirstName    0                  0                     1             0
  PartyTime    1           Names         NameBirthday     0                  0                     1             0
  Area         0           PhoneNumbers  PhonAreaCode     0                  0                     1             0
  Number       0           PhoneNumbers  PhonPhoneNumber  0                  0                     1             0
  FullNumber   1           NULL          NULL             0                  0                     0             1
  NameNameID   0           Names         NameNameID       1                  1                     0             0
  PhonPhoneID  0           PhoneNumbers  PhonPhoneID      1                  1                     0             0

*/
