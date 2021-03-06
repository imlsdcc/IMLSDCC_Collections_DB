USE [test_IMLS_Items2]
GO
/****** Object:  UserDefinedFunction [dbo].[CleanText]    Script Date: 09/28/2012 12:06:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tim Cole
-- Create date: 18 August 2011
-- Description:	
--	This function returns the given string after
--  "cleaning" it.
--
--	I/O: @txt (REQUIRED) - nvarchar(max)
--
-- =============================================
ALTER FUNCTION [dbo].[CleanText]
(	
	-- Add the parameters for the function here
	@txt nvarchar(max)
)
RETURNS nvarchar(127) WITH SCHEMABINDING
AS

BEGIN	
			
           IF LEN(@txt) > 120
			  SET @txt = LEFT(@txt, 120) + '...'
			  
			 --update collectionproperties set textSort = rtrim(ltrim(left([text],50)));
			--while (select count(*) from collectionProperties where @txt like '"%' or @txt like '''%') > 0 
			--begin
			--update collectionproperties set @txt = rtrim(ltrim(substring(@txt,2,50))) where [@txt] like '"%' or [@txt] like '''%'; 
			--end
-- drop articles for sorting purposes
			--update collectionproperties set textSort = rtrim(ltrim(substring(textSort,5,50))) where [textSort] like 'The %'; 
			--update collectionproperties set textSort = rtrim(ltrim(substring(textSort,3,50))) where [textSort] like 'A %'; 
			--update collectionproperties set textSort = rtrim(ltrim(substring(textSort,4,50))) where [textSort] like 'An %';
		   WHILE LEFT(@txt, 4) = 'The '
		      SET @txt = SUBSTRING(@txt, 5, 127)
		   WHILE LEFT(@txt, 2) = 'A '
		      SET @txt = SUBSTRING(@txt, 3, 127)
		   WHILE LEFT(@txt, 3) = 'An '
		      SET @txt = SUBSTRING(@txt, 4, 127)
		   WHILE LEFT(@txt, 1) = '['
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '&amp;'
		      SET @txt = SUBSTRING(@txt, 6, 127)
		   WHILE LEFT(@txt, 1) = '&lt;'
		      SET @txt = SUBSTRING(@txt, 5, 127)
		   WHILE LEFT(@txt, 1) = '&gt;'
		      SET @txt = SUBSTRING(@txt, 5, 127)
		   WHILE LEFT(@txt, 1) = '&apos;'
		      SET @txt = SUBSTRING(@txt, 7, 127)
		   WHILE LEFT(@txt, 1) = '&quot;'
		      SET @txt = SUBSTRING(@txt, 7, 127)
		   WHILE LEFT(@txt, 1) = ''''
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '"'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '&nbsp;'
		      SET @txt = SUBSTRING(@txt, 7, 127)
		   WHILE LEFT(@txt, 1) = '('
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '{'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = ']'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = ')'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '}'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '.'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = ','
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = ';'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = ':'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '/'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '\'                    --'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '_'
		      SET @txt = SUBSTRING(@txt, 3, 127)
		   WHILE LEFT(@txt, 1) = '-'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '?'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   WHILE LEFT(@txt, 1) = '!'
		      SET @txt = SUBSTRING(@txt, 2, 127)
		   SET @txt = LTRIM(@txt)
		   SET @txt = RTRIM(@txt)

	RETURN (@txt)
END 
