-- First set DB name:
USE [test_IH_]
GO


-- ***************************************************************************************
--
-- Author:		Winston Jansz
-- Create date: 03/27/2012
-- Description:	SQL Script to perform the following, for either the Staging DB and/or the
--              Registry DB (that depends on the DB name provided above):
--              (1) First, create a housekeeping USP, dropUSP(<USP-name>).--In order to
--                  drop the specified USP (before re-creating it).
--              (2) Create the USPs: 
--                  (a) setupdb_collectionsDataConstraint
--                  (b) setupdb_physicalAddCol
--                  (c) setupdb_physicalSetCol
--              (3) Perform a START TRAN
--              (4) Run (b) & (c). In order to add the new column, "physical", to the
--                  Collections table, and to populate this new column, respectively. In 
--                  the latter case: Also change values in the Aggregtion Columns where
--                  necessary.
--              (5) Run (a), to generate the constraint CK_Collections on Collections
--                  table; specifically the Aggregation Columns & new column "physical".
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


--
-- NOW, get rid of the CONSTRAINT on Collections, CK_Collections.
--
IF EXISTS (SELECT * FROM sys.check_constraints 
           WHERE    object_id = OBJECT_ID(N'[dbo].[CK_Collections]') 
           AND      parent_object_id = OBJECT_ID(N'[dbo].[Collections]')
          )
ALTER TABLE [dbo].[Collections] DROP CONSTRAINT [CK_Collections];


EXEC dropUSP 'setupdb_collectionsDataConstraint'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Winston Jansz
-- Create date: 11/17/2011
-- Description:	Validate some of the columns'
--              values in Collections table.
-- =============================================
CREATE PROCEDURE [dbo].[setupdb_collectionsDataConstraint]
AS
BEGIN
BEGIN try
    -- Prevent extra result sets from interfering with SELECT statements
    SET NOCOUNT ON;

    /*
	IF EXISTS (SELECT * FROM sys.check_constraints 
	           WHERE    object_id = OBJECT_ID(N'[dbo].[CK_Collections]') 
	           AND      parent_object_id = OBJECT_ID(N'[dbo].[Collections]')
	          )
	    ALTER TABLE [dbo].[Collections] DROP CONSTRAINT [CK_Collections];
    */
	
	ALTER TABLE [dbo].[Collections]  WITH NOCHECK ADD  CONSTRAINT [CK_Collections] 
	CHECK          ((imls is null OR imls in ('NLG', 'LSTA', 'MFA'))
	            AND (ih is null OR ih='IH')
	            AND (dlf is null OR dlf='DLF')
	            AND (hist is null OR hist='Hist')
	            AND (dpla is null OR dpla='DPLA'));
	ALTER TABLE [dbo].[Collections] CHECK CONSTRAINT [CK_Collections];

    RETURN 0 -- successful
END try
BEGIN catch
    PRINT 'ERROR ENCOUNTERED IN THE USP, setupdb_collectionsDataConstraint. RETURNING.'
    RETURN -1
END catch
END
GO


EXEC dropUSP 'setupdb_physicalAddCol'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Winston Jansz
-- Create date: 12/12/2011
-- Description:	Add a new column, 'physical', to
--              both the Registry & STAGING DBs.
--              Also set a default value of zero
--              for this column, and add an
--              index (wnj: may remove later...)
-- =============================================
CREATE PROCEDURE [dbo].[setupdb_physicalAddCol]
AS
BEGIN

DECLARE @df_constraint sysname;

BEGIN try
    -- Prevent extra result sets from interfering with SELECT statements
    SET NOCOUNT ON;
    
	-- Add column to Collections table
	IF NOT EXISTS (
	                select 1 
	                from   sys.columns 
	                where  Name = 'physical' 
	                and    Object_ID = Object_ID('Collections')
	              )
	BEGIN
	    ALTER TABLE [dbo].[Collections] ADD  physical     bit NOT NULL DEFAULT ((0));

        SELECT @df_constraint = QuoteName(name)
        FROM   dbo.sysobjects 
        WHERE  name LIKE 'DF__Collect%' 
        AND    type = 'D';
        
        EXECUTE ('ALTER TABLE [dbo].[Collections] DROP CONSTRAINT ' + @df_constraint);

	    ALTER TABLE [dbo].[Collections] ADD  CONSTRAINT [DF_Collections_physical]  DEFAULT ((0)) FOR [physical]
    END

    RETURN 0 -- successful
END try
BEGIN catch
    PRINT 'ERROR ENCOUNTERED IN THE USP, setupdb_physicalAddCol. RETURNING.'
    RETURN -1
END catch
END
GO


EXEC dropUSP 'setupdb_physicalSetCol'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Winston Jansz
-- Create date: 12/12/2011
-- Description:	
-- Description:	Set the value in new column,
--              'physical', for both Registry &
--              STAGING DBs.
-- =============================================
CREATE PROCEDURE [dbo].[setupdb_physicalSetCol]
AS
BEGIN
    BEGIN try
        -- Prevent extra result sets from interfering with SELECT statements
        SET NOCOUNT ON;
        
        -- Set value of column (physical), & modify the _other_ corresp. columns accordingly...
	    update [dbo].[Collections]
	    set    physical = 0
	          ,imls     = NULL
	    where  imls = 'non-NLG-digital';
    	
	    update [dbo].[Collections]
	    set    physical = 0
	          ,dlf      = NULL
	    where  dlf = 'non-DLF-digital';
    	
	    update [dbo].[Collections]
	    set    physical = 1
	          ,imls  = NULL
	          ,hist  = NULL
	          ,dpla  = NULL
	          ,dlf   = NULL
	          ,ih    = NULL
	    where  imls like '%-physical'
	    or     hist like '%-physical'
	    or     dlf  like '%-physical';
    	
        /*
        -- Error check
        select *
	    from   [dbo].[Collections]
	    where  physical=1 and (imls in ('NLG','LSTA','MFA') or dlf='DLF' or hist='Hist' or dpla='DPLA' or ih='IH');

        if @@rowcount > 0
        begin
            print 'ERROR: Expected zero rows from SELECT statement! RETURNING.'
            return -2
        end
        */

        RETURN 0 -- successful
    END try
    BEGIN catch
        PRINT 'ERROR ENCOUNTERED IN THE USP, setupdb_physicalSetCol. RETURNING.'
        RETURN -1
    END catch
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

-- Call USP setupdb_physicalAddCol
EXEC @returnStatus = dbo.setupdb_physicalAddCol
if @returnStatus < 0
begin
    print 'ERROR STATUS returned from setupdb_physicalAddCol.'
    GOTO ERR_HANDLER
end

-- Next, call USP setupdb_physicalSetCol
SET @returnStatus = 0 -- re-set
EXEC @returnStatus = dbo.setupdb_physicalSetCol
if @returnStatus < 0
begin
    print 'ERROR STATUS returned from setupdb_physicalSetCol.'
    GOTO ERR_HANDLER
end

-- Call this LAST: USP setupdb_collectionsDataConstraint
SET @returnStatus = 0 -- re-set
EXEC @returnStatus = dbo.setupdb_collectionsDataConstraint
if @returnStatus < 0
begin
    print 'ERROR STATUS returned from setupdb_collectionsDataConstraint.'
    GOTO ERR_HANDLER
end


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

