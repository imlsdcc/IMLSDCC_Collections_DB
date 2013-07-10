-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jordan Vannoy
-- Create date: August 16, 2012
-- =============================================
CREATE PROCEDURE GetStateCount
	-- Add the parameters for the stored procedure here
	 

AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select COUNT(Distinct i.institutionID) as institCount, i.text as stateName, COUNT(ci.collectionID) as stateCount, f.facetID as stateID
	From InstitutionProperties i join CollectionInstitutions ci on i.institutionID = ci.institutionID
	join [test_IMLS_Items].dbo.Facets f on i.text = f.facetValue
	where f.facetType = 'Place' and i.property = 'state'
	group by i.text, f.facetID
	order by i.text
END
GO
