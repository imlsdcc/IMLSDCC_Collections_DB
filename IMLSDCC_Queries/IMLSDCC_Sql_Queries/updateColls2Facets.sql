USE [test_IMLS_Items2]
GO
/****** Object:  StoredProcedure [dbo].[onetime_updateColls2Facets]    Script Date: 10/04/2012 11:58:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Tim Cole
-- Create date: 12 August 2011
-- Description:	Run this to update the CollectionsToFacets
--				Table (only after Collections 
--				and Facets tables 
--				have been populated)
-- =============================================
ALTER PROCEDURE [dbo].[onetime_updateColls2Facets] 
		@facetTypeToUpdate nvarchar(10) = "All"
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Step 1; associate facets with collections based on collection XMLBlob
	DECLARE @facetid int;
	DECLARE @facetValue nvarchar(100);
	DECLARE @facetType nvarchar(50);
	if @facetTypeToUpdate = 'All'
		Begin
		 set @facetTypeToUpdate = '%'
		End
	DECLARE myRow CURSOR LOCAL FOR
		(select facetid, facetValue, facetType from facets where facetType like @facetTypeToUpdate);
	    
	OPEN myRow;
	FETCH NEXT FROM myRow INTO @facetID, @facetValue, @facetType;

	-- CHANGED varchar(255) to nvarhar(255) in .value method of XML objects, without retesting

	WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (@facetType = 'Type' or @facetTypeToUpdate = 'All' or @facetTypeToUpdate = 'Type')
				BEGIN
					if(@facetValue = 'photograph')
					Begin
						insert into CollectionsToFacets (collID, facetID) (
						(select collid, @facetID as facetID
							from collections c, IH_IMLS.dbo.CollectionTypeMap ctm
							where c.collID = ctm.collectionID and ctm.dcmiType = 'image'
							and c.collID not in (select cf.collid From CollectionsToFacets cf where cf.collid = c.collID and cf.facetID = @facetID)
						))
					End
					if(@facetValue = 'text')
					Begin
						insert into CollectionsToFacets (collID, facetID) (
						(select collid, @facetID as facetID
							from collections c, IH_IMLS.dbo.CollectionTypeMap ctm
							where c.collID = ctm.collectionID and ctm.dcmiType = 'text'
							and c.collID not in (select cf.collid From CollectionsToFacets cf where cf.collid = c.collID and cf.facetID = @facetID)	
						))
					End
					if(@facetValue = 'artifact')
					Begin
						insert into CollectionsToFacets (collID, facetID) (
						(select collid, @facetID as facetID
							from collections c, IH_IMLS.dbo.CollectionTypeMap ctm
							where c.collID = ctm.collectionID and ctm.dcmiType = 'physical object'
							and c.collID not in (select cf.collid From CollectionsToFacets cf where cf.collid = c.collID and cf.facetID = @facetID)	
						))
					End
				END
			ELSE
				IF (@facetType = 'Date' or @facetTypeToUpdate = 'All' or @facetTypeToUpdate = 'Date')
					BEGIN
						DECLARE @xMatchOn nvarchar(100) = '';
						DECLARE @xMatchOn2 nvarchar(100) = '';
						insert into collectionsToFacets (collID, facetID) (
							
						)
						Case @facetValue
							When 'Pre-1800' Then
								insert into collectionsToFacets (collID, facetID) (
								(select collid, @facetID as facetID
								from collections))
						End
						IF (@facetValue='Pre-1800')
						  BEGIN
							set @xMatchOn = '1700-1799';
							set @xMatchOn2 = '1400s-1699';
							insert into collectionsToFacets (collID, facetID) (
							(select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn")])[1]', 'nvarchar(max)') <> '')
							union
							(select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn2")])[1]', 'nvarchar(max)') <> '')
							)
							
						  END
						ELSE IF (@facetValue='Early 19th century')
						  BEGIN
							set @xMatchOn = '1800-1849';
							insert into collectionsToFacets (collID, facetID) (
							select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn")])[1]', 'nvarchar(max)') <> '')
							
						  END
						ELSE IF (@facetValue='Late 19th century')
						  BEGIN
							set @xMatchOn = '1850-1899';
							insert into collectionsToFacets (collID, facetID) (
							select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn")])[1]', 'nvarchar(max)') <> '')
							
						  END
						ELSE IF (@facetValue='Early 20th century')
						  BEGIN
							set @xMatchOn = '1900-1929';							
							set @xMatchOn2 = '1930-1949';
							insert into collectionsToFacets (collID, facetID) (
							(select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn")])[1]', 'nvarchar(max)') <> '')
							union
							(select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn2")])[1]', 'nvarchar(max)') <> ''))
							
						  END
						ELSE IF (@facetValue='Late 20th century')
						  BEGIN
							set @xMatchOn = '1950-1969';							
							set @xMatchOn2 = '1970-1999';
							insert into collectionsToFacets (collID, facetID) (
							(select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn")])[1]', 'nvarchar(max)') <> '')
							union
							(select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn2")])[1]', 'nvarchar(max)') <> ''))
							
						  END
						ELSE IF (@facetValue='2000-Present')
						  BEGIN
							set @xMatchOn = '2000 to present';
							insert into collectionsToFacets (collID, facetID) (
							select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn")])[1]', 'nvarchar(max)') <> '')
							
						  END 
						ELSE 
						  BEGIN
							set @xMatchOn = @facetValue;
							insert into collectionsToFacets (collID, facetID) (
							select collid, @facetID as facetID
								from collections
								where XMLBlob.value('(/record/metadata[1]/dc/coverage[.=sql:variable("@xMatchOn")])[1]', 'nvarchar(max)') <> '')
						  END
							
					END
				ELSE
					IF (@facetType = 'Place' or @facetTypeToUpdate = 'All' or @facetTypeToUpdate = 'Place')
						BEGIN
							--DECLARE @xState nvarchar(127) = @facetValue + ' (state)';
							insert into collectionsToFacets (collID, facetID) (
							select c.collID, @facetid as facetID
								From IH_IMLS.dbo.CollectionInstitutions ci, IH_IMLS.dbo.InstitutionProperties ip, Collections c
								where ip.property = 'state' and ci.institutionID = ip.institutionID and ip.text = @facetValue and c.collID = ci.collectionID
								and c.collID not in (select cf.collid From CollectionsToFacets cf where c.collID = ci.collectionID and cf.facetID = @facetID))
						END
			FETCH NEXT FROM myRow INTO @facetID, @facetValue, @facetType;

		END
	CLOSE myRow;
	DEALLOCATE myRow;
	
	-- Step 2: Associate facets with Collections having items based on the facets of those items 
	--DECLARE @cid int;

	--DECLARE myRow CURSOR LOCAL FOR
	--	(select c5.collid from [dbo].[collections] c5 where c5.itemCount >0);
	    
	--OPEN myRow;
	--FETCH NEXT FROM myRow INTO @cid;

	--WHILE @@FETCH_STATUS = 0
	--	BEGIN
	--		DECLARE @fid int;
			
	--		DECLARE myInsideRow CURSOR LOCAL FOR
	--			(select rf5.facetID from [dbo].[Records] r5
	--				join [dbo].[RecordsToFacets] rf5 on rf5.recordid = r5.recordid
	--				where r5.cid = @cid
	--				group by rf5.facetID);
	--			OPEN myInsideRow;
	--			FETCH NEXT FROM myInsideRow INTO @fid;
				
	--			WHILE @@FETCH_STATUS = 0
	--			BEGIN
	--				DECLARE @myCnt int;
	--				SET @myCnt = (SELECT COUNT(*) from [dbo].[CollectionsToFacets] cf6 where cf6.collid = @cid and cf6.facetID=@fid)
	--				IF @myCnt = 0
	--					INSERT INTO [dbo].[CollectionsToFacets] (collid, facetID) VALUES (@cid, @fid)
	--				FETCH NEXT FROM myInsideRow INTO @fid;
				
	--			END
	--			CLOSE myInsideRow;
	--			DEALLOCATE myInsideRow;

	--		FETCH NEXT FROM myRow INTO @cid;

	--	END
	--CLOSE myRow;
	--DEALLOCATE myRow;

END


