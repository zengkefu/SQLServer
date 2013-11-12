/* (0) */
-- Is the query SARGable?  WHERE?  JOINS?

/* (1) */

DECLARE @inside VARCHAR(25)
SET @inside = @outside

-- USE @inside


/* (2) */

DBCC FREEPROCCACHE


/* (3) */

EXECUTE stp_OurProcedure WITH RECOMPILE


/* (4) */

CREATE NONCLUSTERED INDEX IX_MatchTheQuery ON OurTable(OurColumn)


/* (5) */
-- 2005, 2008R2

EXECUTE AS USER = 'User\User';
EXECUTE AS LOGIN = 'User';

SELECT SUSER_NAME(), USER_NAME()

EXECUTE stp_OurProcedure 'Parameter'

REVERT


/* (6) */
EXEC sp_configure 'remote login timeout'
