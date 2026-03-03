USE [SISE_NEW]
GO
/****** Object:  Table [SISE3].[CAT_OrigenPromocion]    Script Date: 12/14/2023 9:32:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SISE3].[CAT_OrigenPromocion](
	[kIdOrigenPromocion] [int] NOT NULL,
	[sNombreOrigenPromocion] [varchar](25) NULL,
 CONSTRAINT [PK_CAT_OrigenPromocion] PRIMARY KEY CLUSTERED 
(
	[kIdOrigenPromocion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (0, N'SISE')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (1, N'FESE')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (2, N'SAN LÁZARO')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (3, N'VET')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (4, N'OFICIALÍA')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (5, N'JUICIO EN LÍNEA')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (6, N'JUICIO EN LÍNEA')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (7, N'OFICIALÍA')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (14, N'INTERCONEXIÓN')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (15, N'INTERCONEXIÓN')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (22, N'INTERCONEXIÓN OJ')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (26, N'MINTERSCJN')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (29, N'OCC')
GO
INSERT [SISE3].[CAT_OrigenPromocion] ([kIdOrigenPromocion], [sNombreOrigenPromocion]) VALUES (30, N'OCC')
GO