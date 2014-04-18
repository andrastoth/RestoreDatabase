USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author		Tóth András
-- Create date 2014-03-31
-- Description	Restore Database
-- USAGE Restore or Create exec dbo.RestoreDatabase 'E:\AdventureWorks2012.bak' ,'AdventureWorks2012'
-- USAGE Copy exec dbo.RestoreDatabase 'E:\AdventureWorks2012.bak', 'AdventureWorks2012','AdventureWorks2012Copy'
-- =============================================
CREATE PROCEDURE [dbo].[RestoreDatabase]
	-- Add the parameters for the stored procedure here
	@path NVARCHAR(500)
	,@db NVARCHAR(100)
	,@cdb NVARCHAR(100) = @db
AS
BEGIN
	DECLARE @SQLCommand NVARCHAR(max);
	SET @SQLCommand = 
'USE [master];
IF EXISTS (
		SELECT *
		FROM sys.databases
		WHERE NAME = ''@cdb''
		)
BEGIN
	ALTER DATABASE [@cdb]
	SET SINGLE_USER
	WITH
	ROLLBACK IMMEDIATE
END;
DECLARE @backup_filelist TABLE (
	LogicalName NVARCHAR(128) NOT NULL PRIMARY KEY
	,PhysicalName NVARCHAR(260)
	,Type CHAR(1)
	,FileGroupName NVARCHAR(128)
	,Size NUMERIC(20, 0)
	,MaxSize NUMERIC(20, 0)
	,FileID BIGINT
	,CreateLSN NUMERIC(22, 0)
	,DropLSN NUMERIC(25, 0)
	,UniqueID UNIQUEIDENTIFIER
	,ReadOnlyLSN NUMERIC(25, 0)
	,ReadWriteLSN NUMERIC(25, 0)
	,BackupSizeInBytes BIGINT
	,SourceBlockSize INT
	,FileGroupID INT
	,LogGroupGUID UNIQUEIDENTIFIER
	,DifferentialBaseLSN NUMERIC(25, 0)
	,DifferentialBaseGUID UNIQUEIDENTIFIER
	,IsReadOnly BIT
	,IsPresent BIT
	,TDEThumbprint VARBINARY(32)
	)
DECLARE @cmdstr NVARCHAR(255)
SELECT @cmdstr = ''RESTORE filelistonly FROM DISK = ''''@path''''''
INSERT INTO @backup_filelist
EXEC (@cmdstr)
DECLARE @md_path NVARCHAR(200);
DECLARE @ldf NVARCHAR(200);
DECLARE @mdf NVARCHAR(200);
DECLARE @mdf_file NVARCHAR(200);
DECLARE @ldf_file NVARCHAR(200);
SET @ldf_file = (SELECT LogicalName FROM @backup_filelist WHERE Type = ''L'');
SET @mdf_file = (SELECT LogicalName FROM @backup_filelist WHERE Type = ''D'');
SET @md_path = (
		SELECT SUBSTRING(physical_name, 1, CHARINDEX(N''master.mdf'', LOWER(physical_name)) - 1)
		FROM master.sys.master_files
		WHERE database_id = 1
			AND file_id = 1
		);
IF ''@db'' = ''@cdb''
BEGIN
	SET @ldf = @md_path + @ldf_file + ''.ldf'';
	SET @mdf = @md_path + @mdf_file + ''.mdf'';
END
ELSE
BEGIN
	SET @ldf = @md_path + ''@cdb_log.ldf'';
	SET @mdf = @md_path + ''@cdb.mdf'';
END;

RESTORE DATABASE [@cdb]
FROM DISK = ''@path''
WITH MOVE @mdf_file TO @mdf
	,MOVE @ldf_file TO @ldf;
ALTER DATABASE [@cdb]
SET MULTI_USER;
';

	SET @SQLCommand = REPLACE(@SQLCommand, '@db', @db);
	SET @SQLCommand = REPLACE(@SQLCommand, '@cdb', @cdb);
	SET @SQLCommand = REPLACE(@SQLCommand, '@path', @path);

	EXEC(@SQLCommand);
END


GO
