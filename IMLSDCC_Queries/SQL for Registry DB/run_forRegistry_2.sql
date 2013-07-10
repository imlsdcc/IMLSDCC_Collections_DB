-- First set DB name:
USE [test_IH_]
GO


-- ***************************************************************************************
--
-- Author:		Winston Jansz
-- Create date: 03/27/2012
-- Description:	SQL Script to perform the following, for the Registry DB:
--              (1) First, create a housekeeping USP, dropUSP(<USP-name>).--In order to
--                  drop the specified USP (before re-creating it).
--              (2) CREATE the USPs: 
--                  (a) setupdb_portalCodeAddCol
--                  (b) z_ProduceSummary_DCC -- actually, ALTER (rather than CREATE)
--                  (c) z_ProduceSummary_Hist -- actually, ALTER (rather than CREATE)
--              (3) Perform a START TRAN
--              (4) Run (a) to add the new Computed Column, "portal", to the Collections
--                  table, and to then populate this new column. Also create index on it.
--              (5) Run (b) and (c). These USPs delete and then re-populate the 
--                  corresponding tables z_ProduceSummary_DCC and z_ProduceSummary_Hist,
--                  respectively.
--              (6) Finally perform a COMMIT, or ROLLBACK, TRAN as necessary.
--
-- ***************************************************************************************


IF EXISTS (SELECT 1 FROM sys.procedures
           WHERE  schema_id = schema_id('dbo')
           AND    name = 'dropUSP'
          )
    DROP PROCEDURE [dbo].[dropUSP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Winston Jansz
-- Create date: 03/27/2012
-- Description:	Drop the given USP (passed in as
--              a parameter) if it already exists.
-- =============================================
CREATE PROCEDURE [dbo].[dropUSP]
    @name varchar(60)
AS
BEGIN
    DECLARE @sql varchar(250) = ''
    IF EXISTS (SELECT 1 FROM sys.procedures
               WHERE  schema_id = schema_id('dbo')
               AND    name = @name
              )
    BEGIN
        SELECT @sql += 'DROP PROCEDURE [dbo].[' + @name + ']'
        EXEC(@sql)
    END
END
GO


EXEC dropUSP 'setupdb_portalCodeAddCol'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Winston Jansz
-- Create date: 11/17/2011
-- Description:	Add Computed Column 'portalCode'
--              to Collections table in Registry
--              and create index on it.
-- =============================================
CREATE PROCEDURE [dbo].[setupdb_portalCodeAddCol]
AS
BEGIN
BEGIN try
    -- Prevent extra result sets from interfering with SELECT statements
    SET NOCOUNT ON;

	IF  EXISTS (SELECT 1 FROM sys.indexes 
	            WHERE  object_id = OBJECT_ID('[dbo].[Collections]') 
	            AND    name = 'portalCode')
	DROP INDEX [portalCode] ON [dbo].[Collections] WITH ( ONLINE = OFF );
	
	IF COLUMNPROPERTY(OBJECT_ID('[dbo].[Collections]'),'portalCode','IsComputed') = 1
	    ALTER TABLE [dbo].[Collections] DROP COLUMN portalCode;
	
	SET ANSI_NULLS ON
	ALTER TABLE [dbo].[Collections]
	ADD   portalCode AS (
	            CONVERT(tinyint,
	                CASE WHEN hist='Hist'
	                    THEN 2
	                    ELSE 1 
	                END--hist
	              | CASE WHEN imls in ('NLG', 'LSTA', 'MFA')
	                    THEN 4
	                    ELSE 1 
	                END--imls
	              | CASE WHEN dlf='DLF'
	                    THEN 8
	                    ELSE 1 
	                END--dlf
	              | CASE WHEN dpla='DPLA'
	                    THEN 16
	                    ELSE 1 
	                END)--dpla
	) PERSISTED
	
	--Create Index on Computed Column
	SET ARITHABORT ON
	SET CONCAT_NULL_YIELDS_NULL ON
	SET QUOTED_IDENTIFIER ON
	SET ANSI_NULLS ON
	SET ANSI_PADDING ON
	SET ANSI_WARNINGS ON
	SET NUMERIC_ROUNDABORT OFF
	CREATE NONCLUSTERED INDEX [portalCode] ON [dbo].[Collections] 
	(
		[portalCode] ASC
	)
	INCLUDE ([collectionID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
END try
BEGIN catch
    PRINT 'ERROR ENCOUNTERED IN THE USP, setupdb_portalCodeAddCol. RETURNING.'
    RETURN -1
END catch
END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Hong Zhang
-- Create date: Feb. 18, 2009
-- Description: Fill the table z_collSummaryDCC with collection ID, title,
--               description, available_url, and number of items for displaying
--               collection information in collection browsing.      
-- =============================================
ALTER PROCEDURE [dbo].[z_ProduceSummary_DCC] 
AS
BEGIN
	DECLARE @collID INT;
	DECLARE @title VARCHAR(3000);
	DECLARE @desc VARCHAR(3000);
	DECLARE @url VARCHAR(3000);
	DECLARE @num INT;

	DELETE FROM [dbo].[z_collSummaryDCC]

	DECLARE i_Cursor CURSOR FORWARD_ONLY FOR
	select table1.cid, table1.value as coll_title, table2.value as coll_desc, table3.value as coll_url, table1.num as numRecords
    from
    (select cp.collectionID as cid, property, text as value, COUNT(rc.collID) as num
    from collectionProperties as cp
    INNER JOIN Collections as c 
    ON cp.collectionID = c.collectionID
    left outer join [IMLSHarvest_DCC].[dbo].[recordsToCollections] as rc
    on rc.collID = cp.collectionID
    where (c.imls='NLG' or c.imls='LSTA' or c.imls='MFA') and cp.property = 'title_collection'  
    group by rc.collID, text, property, cp.collectionID) as table1
    left outer join
   (select cp.collectionID as cid, property, text as value
   from collectionProperties as cp
   INNER JOIN Collections as c 
   ON cp.collectionID = c.collectionID
   where (c.imls='NLG' or c.imls='LSTA' or c.imls='MFA') and cp.property = 'description'  
   ) as table2
   on table1.cid = table2.cid
   left outer join
   (select cp.collectionID as cid, property, text as value
   from collectionProperties as cp
   INNER JOIN Collections as c 
   ON cp.collectionID = c.collectionID
   where (c.imls='NLG' or c.imls='LSTA' or c.imls='MFA') and cp.property = 'isAvailableAt_URL'  
   ) as table3
   on table3.cid = table1.cid
   order by table1.property, table1.value
	
	OPEN i_Cursor 
	FETCH NEXT FROM i_Cursor INTO @collID, @title, @desc, @url, @num
	WHILE @@FETCH_STATUS = 0
	BEGIN

		INSERT INTO dbo.z_collSummaryDCC (cid, coll_title, coll_desc, coll_url, numRecords)
			VALUES (@collID, @title, @desc, @url, @num);

		FETCH NEXT FROM i_Cursor INTO @collID, @title, @desc, @url, @num
	END
	CLOSE i_Cursor;
	DEALLOCATE i_Cursor;
END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Hong Zhang
-- Create date: Feb. 18, 2009
-- Description: Fill the table z_collSummaryHist with collection ID, title,
--               description, available_url, and number of items for displaying
--               collection information in collection browsing.      
-- =============================================
ALTER PROCEDURE [dbo].[z_ProduceSummary_Hist] 
AS
BEGIN
	DECLARE @collID INT;
	DECLARE @title VARCHAR(3000);
	DECLARE @desc VARCHAR(3000);
	DECLARE @url VARCHAR(3000);
	DECLARE @num INT;

	DELETE FROM [dbo].[z_collSummaryHist]

	DECLARE i_Cursor CURSOR FORWARD_ONLY FOR
	select table1.cid, table1.value as coll_title, table2.value as coll_desc, table3.value as coll_url, table1.num as numRecords
    from
    (select cp.collectionID as cid, property, text as value, COUNT(rc.collID) as num
    from collectionProperties as cp
    INNER JOIN Collections as c 
    ON cp.collectionID = c.collectionID
    left outer join [IMLSHarvest_History].[dbo].[recordsToCollections] as rc
    on rc.collID = cp.collectionID
    where c.hist='Hist' and cp.property = 'title_collection'  
    group by rc.collID, text, property, cp.collectionID) as table1
    left outer join
   (select cp.collectionID as cid, property, text as value
   from collectionProperties as cp
   INNER JOIN Collections as c 
   ON cp.collectionID = c.collectionID
   where c.hist='Hist' and cp.property = 'description'  
   ) as table2
   on table1.cid = table2.cid
   left outer join
   (select cp.collectionID as cid, property, text as value
   from collectionProperties as cp
   INNER JOIN Collections as c 
   ON cp.collectionID = c.collectionID
   where c.hist='Hist' and cp.property = 'isAvailableAt_URL'  
   ) as table3
   on table3.cid = table1.cid
   order by table1.property, table1.value
	
	OPEN i_Cursor 
	FETCH NEXT FROM i_Cursor INTO @collID, @title, @desc, @url, @num
	WHILE @@FETCH_STATUS = 0
	BEGIN

		INSERT INTO dbo.z_collSummaryHist (cid, coll_title, coll_desc, coll_url, numRecords)
			VALUES (@collID, @title, @desc, @url, @num);

		FETCH NEXT FROM i_Cursor INTO @collID, @title, @desc, @url, @num
	END
	CLOSE i_Cursor;
	DEALLOCATE i_Cursor;
END
GO


-- =============================================
-- Author:		Winston Jansz
-- Create date: 03/27/2012
-- Description:	Finally, run the required USPs.
-- =============================================

-- Start tx
BEGIN TRANSACTION
print '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN TRANSACTION ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'


DECLARE @returnStatus int = 0

-- Call USP setupdb_portalCodeAddCol
EXEC @returnStatus = dbo.setupdb_portalCodeAddCol
if @returnStatus < 0
begin
    print 'ERROR STATUS returned from setupdb_portalCodeAddCol.'
    GOTO ERR_HANDLER
end


-- Then call the other two USPs
EXEC dbo.z_ProduceSummary_DCC
EXEC dbo.z_ProduceSummary_Hist


-- If no errors, commit tx
print '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ NO ERRORS; COMMIT TRANSACTION ~~~~~~~~~~~~~~~~~~~'
COMMIT TRANSACTION
GOTO EGRESS


ERR_HANDLER:
BEGIN
    print '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ERROR; ROLLBACK TRANSACTION ~~~~~~~~~~~~~~~~~~~~~'
    ROLLBACK TRANSACTION
END


EGRESS:
GO

