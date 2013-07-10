UPDATE [test_IMLS_Items2].[dbo].[Records]
   SET 
      [parent_description]='' where recordID<2793;
      

declare @txt nvarchar(max);
declare @cid int;

DECLARE myRow CURSOR LOCAL FOR
(select collectionid, [text] FROM [IH_IMLS].[dbo].[CollectionProperties] 
    where property in ('alternative_title','associatedCollection','audience','collectionpolicy',
						'contributor','coverage_spatial','coverage_temporal','creator','creatorOfCollection',
						'description','format','language','notes','parentCollection','provenance',
						'publisher','relation_supplement','rights','size','source','subcollection',
						'subject','title_collection','type','type_collection') 
					and collectionid In 
					(select collId from test_IMLS_Items2.dbo.Collections where itemCount > 0));

	OPEN myRow;
	FETCH NEXT FROM myRow INTO @cid,@txt;
	WHILE @@FETCH_STATUS = 0
	  BEGIN

		UPDATE [test_IMLS_Items2].[dbo].[Records]
		SET [parent_description] = [parent_description] + ' ' + @txt WHERE cid=@cid AND recordID<2793;

		FETCH NEXT FROM myRow INTO @cid,@txt;
		
	  END
GO


