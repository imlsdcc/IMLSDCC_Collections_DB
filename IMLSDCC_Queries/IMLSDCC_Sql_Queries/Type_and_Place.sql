Declare @cid int = 2370;


--Select ctm.collectionID as cid, ctm.dcmiType as type
--From CollectionTypeMap ctm
--where ctm.collectionID = @cid;

--SELECT collectionID, text
--  FROM [IH_IMLS].[dbo].[CollectionProperties]cp
--  where property = 'type_collection'
--  and propertyType = 'ControlledVocabulary'
--  and cp.collectionID = @cid;

Select distinct ci.collectionID as cid, ip.text as place
From CollectionInstitutions ci, InstitutionProperties ip
where ci.collectionID = @cid and ip.property = 'state' and ci.institutionID = ip.institutionID;

----Select r.recordID
----From test_IMLS_Items2.dbo.Records r
----where r.cid = @cid;

--Select distinct rf.facetID, f.facetType
--From test_IMLS_Items2.dbo.Records r, test_IMLS_Items2.dbo.RecordsToFacets rf, test_IMLS_Items2.dbo.Facets f
--where rf.recordID in (Select r.recordID From test_IMLS_Items2.dbo.Records r where r.cid = @cid) 
--and f.facetID = rf.facetID;