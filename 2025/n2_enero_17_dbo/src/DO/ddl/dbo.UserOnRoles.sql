CREATE TABLE [dbo].[UserOnRoles] (
    [userId]                          INTEGER NOT NULL,
    [roleId]                          INTEGER NOT NULL,
    [assignedAt]                       DATETIME NOT NULL,
    [assignedBy]                       VARCHAR(50) NULL,
    [status]                           INTEGER NULL,
    CONSTRAINT [PK_UserRoles] PRIMARY KEY ([userId], [roleId]),
    CONSTRAINT [FK_UserRoles_Users] FOREIGN KEY ([userId]) 
        REFERENCES [dbo].[Users]([userId])
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
    CONSTRAINT [FK_UserRoles_Roles] FOREIGN KEY ([roleId]) 
        REFERENCES [dbo].[Roles]([roleId])
        ON DELETE CASCADE
        ON UPDATE NO ACTION
);
