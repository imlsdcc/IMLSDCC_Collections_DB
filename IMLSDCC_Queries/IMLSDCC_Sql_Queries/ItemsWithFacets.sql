USE [test_IMLS_Items2]
GO
/****** Object:  StoredProcedure [dbo].[GetItemsWithFacets]    Script Date: 10/17/2012 13:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetItemsWithFacets] (
	-- Add the parameters for the function here
	@phrase nvarchar(255),
	@queryType nvarchar(255) = '*', 
	@top_n int = 10000,
	@dateIDs nvarchar(255) = '',
	@typeIDs nvarchar(255) = '',
	@placeIDs nvarchar(255) = '',
	@collectionIDs nvarchar(255) = ''
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @ctq Table(RecordID int,ctRank int);
	insert into @ctq(RecordID, ctRank)(Select * From containsTableQuery(@phrase,@queryType,@top_n));
	select * from @ctq;
	
	IF (@dateIDs = '')
		select * from @ctq ctq where ctq.RecordID in (select recordID from test_IMLS_Items2.dbo.RecordsToFacets where facetID in (select * from [dbo].[mySplit](@dateIDs)))
		
	IF (@typeIDs = '')
		select * from @ctq ctq where ctq.RecordID in (select recordID from test_IMLS_Items2.dbo.RecordsToFacets where facetID in (select * from [dbo].[mySplit](@typeIDs)))
		
	IF (@placeIDs = '')
		select * from @ctq ctq where ctq.RecordID in (select recordID from test_IMLS_Items2.dbo.RecordsToFacets where facetID in (select * from [dbo].[mySplit](@placeIDs)))
	
	select COUNT(f.facetID) as facetCount, f.facetValue, f.facetType, f.facetID
	from Facets f
	join RecordsToFacets rf on rf.facetID = f.facetID
	join @ctq ctq on ctq.RecordID = rf.recordID
	group by f.facetID, f.facetValue, f.facetType
	order by f.facetType, COUNT(f.facetID) desc
END
