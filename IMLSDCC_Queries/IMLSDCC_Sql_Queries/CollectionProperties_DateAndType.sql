/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT COUNT(collectionID), text
--  FROM [IH_IMLS].[dbo].[CollectionProperties]
--  where property = 'type_collection'
--  and propertyType = 'ControlledVocabulary'
--  group by text;
  
  SELECT COUNT(collectionid),property, text
  FROM [IH_IMLS].[dbo].[CollectionProperties]
  where property = 'coverage_temporal' and propertyType = 'ControlledVocabulary'
  group by property, text
  