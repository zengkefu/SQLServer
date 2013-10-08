ALTER PROCEDURE [admin].[stp_DatabaseName_Admin]
AS
BEGIN

/* 

Rebuild indexes for each table

*/

-- This script assumes no data can be inserted between existind data; if this assumption is false, use coded out script below
EXEC sp_msforeachtable 'ALTER INDEX ALL ON ? REBUILD PARTITION = ALL WITH ( FILLFACTOR  = 100, PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = OFF )'

-- Mid data inserts - fill factor can be 70 or 80 depending on how many mid-data inserts there are
-- EXEC sp_msforeachtable 'ALTER INDEX ALL ON ? REBUILD PARTITION = ALL WITH ( FILLFACTOR  = 80, PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = OFF )'

-- Check off item
INSERT INTO admin.AdministrativeTasks
SELECT 'Indexing Complete', GETDATE()

/*

Database integrity check and verify

*/

IF OBJECT_ID('##DatabaseConsistency') IS NOT NULL
BEGIN
	DROP TABLE ##DatabaseConsistency
END

CREATE TABLE ##DatabaseConsistency(
	Error VARCHAR(10) NULL,
	Level VARCHAR(10) NULL,
	State VARCHAR(10) NULL,
	MessageText VARCHAR(2000),
	RepairLevel VARCHAR(250) NULL,
	Status VARCHAR(10) NULL,
	DbId VARCHAR(10) NULL,
	DbFragId VARCHAR(10) NULL,
	ObjectID VARCHAR(25) NULL,
	IndexID VARCHAR(10) NULL,
	PartitionID VARCHAR(10) NULL,
	AllocUnitId VARCHAR(10) NULL,
	RidDbID VARCHAR(10) NULL,
	RidPruId VARCHAR(10) NULL,
	[File] VARCHAR(10) NULL,
	Page VARCHAR(10) NULL,
	Slot VARCHAR(10) NULL,
	RefDbId VARCHAR(10) NULL,
	RefPruId VARCHAR(10) NULL,
	RefFile VARCHAR(10) NULL,
	RefPage VARCHAR(10) NULL,
	RefSlot VARCHAR(10) NULL,
	Allocation VARCHAR(10) NULL
)

INSERT INTO ##DatabaseConsistency
EXEC('DBCC CHECKDB(StockAnalysis) WITH TABLERESULTS')

INSERT INTO admin.IntegrityCheck (Error,Level,State,MessageText,RepairLevel,Status)
SELECT Error, Level ,State, MessageText, RepairLevel, Status
FROM ##DatabaseConsistency

-- Check off item
INSERT INTO admin.AdministrativeTasks
SELECT 'Database Integrity Checked', GETDATE()

/* Backup the database if integrity exists */

DECLARE @count TINYINT

SELECT @count = COUNT(*)
FROM ##DatabaseConsistency
WHERE MessageText LIKE 'CHECKDB found 0 allocation errors and 0 consistency errors%'

IF @count > 0
BEGIN
	
	-- Back up database
	DECLARE @name VARCHAR(25)  
	DECLARE @path VARCHAR(256) 
	DECLARE @fileName VARCHAR(256)  
	DECLARE @fileDate VARCHAR(20)

	SET @name = 'DatabaseName'
	SET @path = 'D:\Backup\'
	SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) 
	SET @fileName = @path + @name + '_' + @fileDate + '.BAK'
	
	BACKUP DATABASE @name 
	TO DISK = @fileName
	WITH CHECKSUM

	RESTORE VERIFYONLY
	FROM DISK = @fileName

	IF @@ERROR = 0
	BEGIN
		
		-- Database backed up twice and both backups were verified
		INSERT INTO admin.AdministrativeTasks
		SELECT 'Backup File Created and Verified', GETDATE()
	
		PRINT 'Database backed up and verified ' + CAST(@count AS VARCHAR(1))

	END
	ELSE
	BEGIN
		
		-- Either the backups failed, or the backups weren't verified
		INSERT INTO admin.AdministrativeTasks
		SELECT 'Either Database Not Backed Up Or Verified', GETDATE()

		PRINT 'Either Database Not Backed Up Or Verified'
	
	END
	
END
ELSE
BEGIN

	-- Database integrity compromised
	PRINT 'Database integrity compromised'
	INSERT INTO admin.AdministrativeTasks
	SELECT 'ERROR! Database Integrity Compromised.', GETDATE()
	
END

DROP TABLE ##DatabaseConsistency

END
