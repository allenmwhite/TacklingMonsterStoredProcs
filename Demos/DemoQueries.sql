SET STATISTICS TIME ON
SET STATISTICS IO ON

-- CROSS APPLY vs. temp table joins
USE [GolfTrack]
GO
SELECT r.[GHINNumber]
      ,r.[GolferName]
      ,r.[EmailAddress]
      ,r.[Division]
      ,l.[LeagueDt]
  FROM [dbo].[Roster] r
  CROSS APPLY (
	SELECT TOP 1 s.[LeagueDt]
	FROM [dbo].[Scores] s
	WHERE s.[RosterID] = r.[RosterID]
	ORDER BY s.[LeagueDt] ASC
	) l
ORDER BY r.Division, r.LastName, r.FirstName


CREATE TABLE #LowLeague (
	[RosterID] int,
	[LeagueDt] date
	)
INSERT INTO #LowLeague
	([RosterID], [LeagueDt])
SELECT [RosterID]
      ,MIN([LeagueDt]) AS [LeagueDt]
FROM [dbo].[Scores]
GROUP BY [RosterID]

SELECT r.[GHINNumber]
      ,r.[GolferName]
      ,r.[EmailAddress]
      ,r.[Division]
      ,l.[LeagueDt]
  FROM [dbo].[Roster] r
  INNER JOIN #LowLeague l
	ON r.[RosterID] = l.[RosterID]
ORDER BY r.Division, r.LastName, r.FirstName


-- FOR XML vs. STRING_AGG
USE [GolfTrack]
GO
SELECT [GolferName]
      ,[EmailAddress]
      ,STUFF((SELECT DISTINCT ' // ' + CONVERT(varchar,s.Score)
			FROM dbo.Scores s
			WHERE s.RosterID = r.RosterID
			FOR XML PATH('')),1,4,'') AS Scores
      ,[Division]
  FROM [dbo].[Roster] r
ORDER BY r.Division, r.LastName, r.FirstName

SELECT [GolferName]
      ,[EmailAddress]
      ,(SELECT STRING_AGG(CONVERT(varchar, Score), ' // ')
			FROM dbo.Scores s
			WHERE s.RosterID = r.RosterID
			GROUP BY s.RosterID) AS Scores
      ,[Division]
  FROM [dbo].[Roster] r
ORDER BY r.Division, r.LastName, r.FirstName


-- IN() Lists vs. temp table joins
USE [HostWeb]
GO

SELECT [PatientID]
      ,[FirstName]
      ,[LastName]
      ,[DateOfBirth]
      ,[ConditionID]
FROM [dbo].[Patients]
WHERE [ConditionID] IN (
'10097', --Breast and Ovarian Cancer and Family Health History
'10098', --Breast Cancer
'10120', --Cancer
'10121', --Colorectal (Colon) Cancer
'10122', --Gynecologic Cancers
'10123', --Lung Cancer
'10124', --Prostate Cancer
'10125', --Skin Cancer
'10126', --Cancer and Flu
'10146', --Cervical Cancer
'10190', --Colorectal (Colon) Cancer
'10191', --Colorectal Cancer Control Program (CRCCP)
'10192', --Colorectal Cancer and Genetics
'10311', --Flu and Cancer — see Cancer and Flu
'10362', --Gynecologic Cancers
'10363', --Cervical Cancer
'10364', --Ovarian Cancer
'10365', --Uterine Cancer
'10366', --Vaginal and Vulvar Cancers
'10427', --HPV-Associated Cancers
'10513', --Lung Cancer
'10596', --Occupational Cancers
'10603', --Oral Cancer
'10610', --Ovarian Cancer
'10661', --Prostate Cancer
'10746', --Skin Cancer
'10747', --Skin Cancer and Genetics
'10749', --see also Skin Cancer
'10865', --Uterine Cancer
'10866' --Vaginal and Vulvar Cancers
)
ORDER BY [LastName], [FirstName]

CREATE TABLE #Cancers (
	[ConditionID] varchar(20)
	)
INSERT INTO #Cancers ([ConditionID])
VALUES
('10097'), --Breast and Ovarian Cancer and Family Health History
('10098'), --Breast Cancer
('10120'), --Cancer
('10121'), --Colorectal (Colon) Cancer
('10122'), --Gynecologic Cancers
('10123'), --Lung Cancer
('10124'), --Prostate Cancer
('10125'), --Skin Cancer
('10126'), --Cancer and Flu
('10146'), --Cervical Cancer
('10190'), --Colorectal (Colon) Cancer
('10191'), --Colorectal Cancer Control Program (CRCCP)
('10192'), --Colorectal Cancer and Genetics
('10311'), --Flu and Cancer — see Cancer and Flu
('10362'), --Gynecologic Cancers
('10363'), --Cervical Cancer
('10364'), --Ovarian Cancer
('10365'), --Uterine Cancer
('10366'), --Vaginal and Vulvar Cancers
('10427'), --HPV-Associated Cancers
('10513'), --Lung Cancer
('10596'), --Occupational Cancers
('10603'), --Oral Cancer
('10610'), --Ovarian Cancer
('10661'), --Prostate Cancer
('10746'), --Skin Cancer
('10747'), --Skin Cancer and Genetics
('10749'), --see also Skin Cancer
('10865'), --Uterine Cancer
('10866') --Vaginal and Vulvar Cancers

SELECT p.[PatientID]
      ,p.[FirstName]
      ,p.[LastName]
      ,p.[DateOfBirth]
      ,p.[ConditionID]
FROM [dbo].[Patients] p
INNER JOIN #Cancers c
ON p.[ConditionID] = c.[ConditionID]
ORDER BY [LastName], [FirstName]

--CREATE NONCLUSTERED INDEX [IX_Patients_CMSMatterID]
--ON [dbo].[Patients] ([ConditionID])
--INCLUDE ([FirstName],[LastName],[DateOfBirth])
--GO


-- Calling Function vs. Inline Calculations
USE [GolfTrack]
GO
SELECT r.GHINNumber
	,r.GolferName
	,s.LeagueDt
	,c.CourseName
	,s.Score
	,[dbo].[getCourseHandicap](s.CourseRating, s.SlopeRating, s.HI, c.Par) AS CourseHandicap
	,s.Score - [dbo].[getCourseHandicap](s.CourseRating, s.SlopeRating, s.HI, c.Par) AS Net
FROM dbo.Scores s
INNER JOIN dbo.Roster r
ON s.RosterID = r.RosterID
INNER JOIN dbo.Course c
ON s.CourseID = c.CourseID
ORDER BY r.LastName, r.FirstName, s.LeagueDt DESC

SELECT r.GHINNumber
	,r.GolferName
	,s.LeagueDt
	,c.CourseName
	,s.Score
	,CONVERT(INT, ROUND(ROUND(CONVERT(float,(s.HI * (s.SlopeRating / 113.0)) + (s.CourseRating - c.Par)),0) ,0)) AS CourseHandicap
	,s.Score - CONVERT(INT, ROUND(ROUND(CONVERT(float,(s.HI * (s.SlopeRating / 113.0)) + (s.CourseRating - c.Par)),0) ,0)) AS Net
FROM dbo.Scores s
INNER JOIN dbo.Roster r
ON s.RosterID = r.RosterID
INNER JOIN dbo.Course c
ON s.CourseID = c.CourseID
ORDER BY r.LastName, r.FirstName, s.LeagueDt DESC


-- Put it together - Single Query vs. temp tables
USE [GolfTrack]
GO
SELECT r.[GHINNumber]
      ,r.[GolferName]
      ,l.[LeagueDt] AS LastPlayed
	  ,DATEDIFF(dd, l.[LeagueDt], GETDATE()) AS DaysSinceLastPlay
	  ,lc.[CourseName] AS LastCourse
	  ,lc.[Par] AS LastCoursePar
	  ,l.[Score] AS LastCourseScore
	  ,[dbo].[getCourseHandicap](l.CourseRating, l.SlopeRating, l.HI, lc.Par) AS LastCourseHandicap
	  ,l.Score - [dbo].[getCourseHandicap](l.CourseRating, l.SlopeRating, l.HI, lc.Par) AS LastCourseNet
      ,r.[HI]
      ,r.[Division]
  FROM [dbo].[Roster] r
  CROSS APPLY (
	SELECT TOP 1 s.[LeagueDt], s.[CourseID], s.[Score],
		s.[HI], s.[CourseRating], s.[SlopeRating]
	FROM [dbo].[Scores] s
	WHERE s.[RosterID] = r.[RosterID]
	ORDER BY s.[LeagueDt] DESC
	) l
  INNER JOIN [dbo].[Course] lc
    ON l.[CourseID] = lc.[CourseID]
  WHERE lc.[Certified] = 1
  AND r.Division = 'A'
ORDER BY r.[LastName], r.[FirstName], r.[GHINNumber]

;WITH LastPlayed ([RosterID], [LeagueDt], [CourseID], [Score],
	[HI], [CourseRating], [SlopeRating], [RowNum]) AS (
		SELECT s.[RosterID], s.[LeagueDt], s.[CourseID], s.[Score],
			s.[HI], s.[CourseRating], s.[SlopeRating],
			ROW_NUMBER() OVER(PARTITION BY s.[RosterID] ORDER BY s.[LeagueDt] DESC) AS RowNum
		FROM [dbo].[Scores] s
	)
SELECT *
INTO #LastPlayed
FROM LastPlayed 
WHERE RowNum = 1

SELECT [CourseID]
	  ,[CourseName]
	  ,[Par]
INTO #CertCourse
FROM [dbo].[Course]
WHERE [Certified] = 1

SELECT r.[RosterID]
      ,r.[GHINNumber]
      ,r.[LastName]
      ,r.[FirstName]
      ,r.[GolferName]
      ,r.[HI]
      ,r.[Division]
INTO #APlayers
  FROM [dbo].[Roster] r
WHERE r.Division = 'A'

SELECT r.[GHINNumber]
      ,r.[GolferName]
      ,l.[LeagueDt] AS LastPlayed
	  ,DATEDIFF(dd, l.[LeagueDt], GETDATE()) AS DaysSinceLastPlay
	  ,lc.[CourseName] AS LastCourse
	  ,lc.[Par] AS LastCoursePar
	  ,l.[Score] AS LastCourseScore
	  ,CONVERT(INT, ROUND(ROUND(CONVERT(float,(l.HI * (l.SlopeRating / 113.0)) + (l.CourseRating - lc.Par)),0) ,0)) AS LastCourseHandicap
	  ,l.Score - CONVERT(INT, ROUND(ROUND(CONVERT(float,(l.HI * (l.SlopeRating / 113.0)) + (l.CourseRating - lc.Par)),0) ,0)) AS LastCourseNet
      ,r.[HI]
      ,r.[Division]
  FROM #APlayers r
  INNER JOIN #LastPlayed l
	ON r.[RosterID] = l.[RosterID]
  INNER JOIN #CertCourse lc
    ON l.[CourseID] = lc.[CourseID]
ORDER BY r.[LastName], r.[FirstName], r.[GHINNumber]

DROP TABLE #APlayers,
	#CertCourse,
	#LastPlayed


-- Single Big Query vs. update temp table

USE [HostWeb]
GO
SELECT p.[PatientID]
      ,p.[FirstName]
      ,p.[LastName]
      ,p.[City]
      ,ISNULL(sc.[StateName], 'UNK') AS StateName
      ,ISNULL(s.[StatusDesc], 'Unknown') AS StatusDesc
      ,p.[DateOfBirth]
      ,ISNULL(CONCAT_WS(', ', dr.[LastName], dr.[FirstName], dr.[Suffix]), 'Unknown') AS DoctorName
      ,ISNULL(c.[ConditionDesc], 'Unknown') AS ConditionDesc
      ,p.[Priority]
      ,ISNULL(ir.InitialResponseDesc, 'Unknown') AS InitialResponse
      ,ISNULL(pc.ProcedureDesc, 'Unknown') AS [Procedure]
  FROM [dbo].[Patients] p
  LEFT JOIN [dbo].[MedStatus] s
	ON p.StatusID = s.StatusID
  LEFT JOIN [dbo].[Physician] dr
    ON p.PhysicianID = dr.PhysicianID
  LEFT JOIN [dbo].[Conditions] c
    ON p.ConditionID = c.ConditionID
  LEFT JOIN [dbo].[InitialResponseCodes] ir
    ON p.InitialResponseCode = ir.InitialResponseCode
  LEFT JOIN [dbo].[ProcedureCodes] pc
    ON p.ProcedureID = pc.ProcedureID
  LEFT JOIN [dbo].[StateCodes] sc
    ON p.State = sc.State
  WHERE p.Tolling = 1



USE [HostWeb]
GO
CREATE TABLE #Patients(
	[PatientID] [int] NOT NULL,
	[FirstName] [varchar](30) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[City] [varchar](50) NULL,
	[State] [int] NULL,
	[StateName] [varchar](50) NOT NULL,
	[StatusID] [int] NULL,
	[StatusDesc] [varchar](100) NOT NULL,
	[DateOfBirth] [datetime] NULL,
	[PhysicianID] [int] NULL,
	[DoctorName] [varchar](104) NOT NULL,
	[ConditionID] [varchar](20) NULL,
	[ConditionDesc] [varchar](500) NOT NULL,
	[Priority] [int] NULL,
	[InitialResponseCode] [int] NULL,
	[InitialResponse] [varchar](100) NOT NULL,
	[ProcedureID] [varchar](50) NULL,
	[Procedure] [varchar](200) NOT NULL
	)

INSERT INTO #Patients (
	[PatientID],
	[FirstName],
	[LastName],
	[City],
	[State],
	[StateName],
	[StatusID],
	[StatusDesc],
	[DateOfBirth],
	[PhysicianID],
	[DoctorName],
	[ConditionID],
	[ConditionDesc],
	[Priority],
	[InitialResponseCode],
	[InitialResponse],
	[ProcedureID],
	[Procedure]
	)
SELECT p.[PatientID]
      ,p.[FirstName]
      ,p.[LastName]
      ,p.[City]
	  ,p.[State]
      ,'UNK' AS StateName
	  ,p.[StatusID]
      ,'Unknown' AS StatusDesc
      ,p.[DateOfBirth]
	  ,p.[PhysicianID]
      ,'Unknown' AS DoctorName
	  ,p.[ConditionID]
      ,'Unknown' AS ConditionDesc
      ,p.[Priority]
	  ,p.[InitialResponseCode]
      ,'Unknown' AS InitialResponse
	  ,p.[ProcedureID]
      ,'Unknown' AS [Procedure]
  FROM [dbo].[Patients] p
  WHERE p.Tolling = 1

UPDATE t
	SET t.[StatusDesc] = s.[StatusDesc]
FROM #Patients t
INNER JOIN [dbo].[MedStatus] s
	ON t.StatusID = s.StatusID

UPDATE t
	SET t.[DoctorName] = CONCAT_WS(', ', dr.[LastName], dr.[FirstName], dr.[Suffix])
FROM #Patients t
INNER JOIN [dbo].[Physician] dr
    ON t.PhysicianID = dr.PhysicianID

UPDATE t
	SET t.[ConditionDesc] = c.[ConditionDesc]
FROM #Patients t
INNER JOIN [dbo].[Conditions] c
    ON t.ConditionID = c.ConditionID

UPDATE t
	SET t.[InitialResponse] = ir.[InitialResponseDesc]
FROM #Patients t
INNER JOIN [dbo].[InitialResponseCodes] ir
    ON t.InitialResponseCode = ir.InitialResponseCode

UPDATE t
	SET t.[Procedure] = pc.[ProcedureDesc]
FROM #Patients t
INNER JOIN [dbo].[ProcedureCodes] pc
    ON t.ProcedureID = pc.ProcedureID

UPDATE t
	SET t.[StateName] = sc.[StateName]
FROM #Patients t
INNER JOIN [dbo].[StateCodes] sc
    ON t.State = sc.State

SELECT [PatientID]
      ,[FirstName]
      ,[LastName]
      ,[City]
      ,[StateName]
      ,[StatusDesc]
      ,[DateOfBirth]
      ,[DoctorName]
      ,[ConditionDesc]
      ,[Priority]
      ,[InitialResponse]
      ,[Procedure]
  FROM #Patients

DROP TABLE #Patients


